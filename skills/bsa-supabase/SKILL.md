---
name: bsa-supabase
description: Supabase/PostgreSQL işlerinde (migration, RLS, SECURITY DEFINER RPC, trigger, pg_cron, enum, backfill, canlı şema, Storage/Realtime) BigBrain derslerini ve v2.23 BLOK 13 kurallarını uygular. supabase/**, *.sql, lib/*supabase*, supabase.rpc/.from içeren kod dokunulurken çağır.
---
# bsa-supabase — Supabase / PostgreSQL kuralları

## Ne zaman
- `supabase/migrations/**`, `supabase/backfills/**`, `*.sql` dosyası oluşturuluyor veya değişiyor
- RLS policy, SECURITY DEFINER RPC, trigger, view, enum, pg_cron job yazılıyor
- `lib/*supabase*`, `supabase.rpc(...)`, `.from(...)` içeren istemci/sunucu/API route kodu değişiyor
- Realtime, Storage/dosya yükleme, harici API cache, zamanlanmış iş tasarlanıyor
- Canlı DB'ye tek seferlik veri düzeltmesi (backfill) planlanıyor

## Görev başı kontrol listesi
1. Canlı şemayı oku (L-0007): `select column_name, data_type from information_schema.columns where table_name='X';` — repo migration'ına körü körüne güvenme.
2. `gh pr list`, `git branch -a`, `grep -rn '<tablo|rpc>'` — aynı tablo/RPC'ye dokunan açık iş var mı (L-0092).
3. `grep -i '<konu>' BigBrain/lessons/INDEX.md` — eşleşen dersleri rapora "Uygulanan dersler" olarak yaz.
4. Migration numarası = bir sonraki boş numara; aynı NNNN ön ekiyle ikinci dosya engellenir (hook da yakalar: pre-write-guard).
5. DB şeması/migration KRİTİK DOSYA: canlı `db push` ve merge yalnızca açık kullanıcı onayıyla; production DB elle değiştirilmez.

## Hızlı şablonlar (derslerin somut hali)
```sql
-- RLS (L-0074): (select ...) sarımı + index
alter table public.x enable row level security;
create policy x_staff_all on public.x for all
  using ((select public.is_staff())) with check ((select public.is_staff()));
create index if not exists x_user_id_idx on public.x(user_id);

-- Atomik RPC (L-0055 / L-0002)
create or replace function public.record_payment(p_plan_id uuid, p_amount numeric)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not (select public.is_staff()) then raise exception 'forbidden'; end if;
  -- 2+ tabloya yazma: tek gövde = tek transaction
end $$;

-- pg_cron (L-0052): UTC, unique ad, re-deploy'da önce sil
delete from cron.job where jobname = 'mark-overdue';
select cron.schedule('mark-overdue', '0 0 * * *', $$select public.mark_overdue()$$);
```
Canlı uygulama: `npx supabase db push --linked --dry-run` → çıktıyı raporla → onaydan sonra `npx supabase db push --linked` (sıra dışı ise `--include-all`).

## Kurallar (BigBrain dersleri)

### RLS ve anahtar güvenliği
- **L-0002** — İstemciden doğrudan PostgREST upsert (`on_conflict` + `resolution=merge-duplicates`) RLS WITH CHECK'e takılır → 401. İstemci yazmalarını SECURITY DEFINER RPC ile yap (örn. `save_push_subscription`, `save_backup`/`get_backup`); istemci anon key kullanır.
- **L-0003** — `SUPABASE_SERVICE_ROLE_KEY` yalnızca server-side; ASLA `NEXT_PUBLIC_*` altında, client bundle'da veya commit'te değil — aksi halde RLS tümüyle bypass (hook da yakalar). Service role ile yazan API route'larda input validation kritik.
- **L-0074** — RLS politikasında `is_staff()`/`auth.uid()` çağrısını `(select ...)` ile sar: `USING ((select public.is_staff()))` → InitPlan, tek hesaplama (Supabase: 5-10x). SECURITY DEFINER helper gövdesinde gerekmez. RLS'de kullanılan kolonlara index ekle.
- **L-0017** — Sıfır temas: `profiles.phone`/email yalnız self/admin RLS; public tarafta phone/email hariç `public_profiles` view. Public model'ler phone içermez; iletişim in-app kanaldan.
- **L-0016** — PII ve sağlık verisi (semptom, ilaç) `console.log`/exception mesajına yazılmaz; `sanitize()`/`sanitize_pii()` kullan. UID/IP/status kalabilir, ham `response.text` asla.

### RPC ve atomik yazma
- **L-0055** — 2+ tabloya yazan iş operasyonu (dönem kapatma, toplu atama) → `SECURITY DEFINER LANGUAGE plpgsql` fonksiyon; tüm adımlar tek gövdede (implicit transaction). Başta `auth.uid()` ile rol doğrula, `SET search_path = public` zorunlu. Ad: `public.<fiil>_<nesne>()` (örn. `close_term_and_create_next`, `record_payment`). Client anon key ile `supabase.rpc('fn', params)`; service role client'a verilmez.
- **L-0082** — Geçmişi koruyan finansal değişim (cancelled-void): tek atomik SECURITY DEFINER motorda eski atama `ended`, yalnız geçiş-ayı-sonrası `pending` planlar `status='cancelled'` (paid/partial/overdue'a dokunma; status-only UPDATE, satır silme yok). Borç/dashboard sorgularına `status <> 'cancelled'`. BEFORE trigger amount/due_date UPDATE + DELETE'i kilitler, status'a izin verir.
- **L-0056** — Sözleşme/fatura/makbuz: tabloya `content_snapshot TEXT NOT NULL`; `draft`'ta preview canlı veriden olabilir, `signed`/`sent`'e geçişte snapshot al ve `signed_at IS NOT NULL` ise güncellemeyi yasakla. Görüntüleme daima snapshot'tan (Markdown/HTML); canlı JOIN'den re-generate YOK.

### Trigger, hesaplama, zamanlama
- **L-0053** — Hesaplamalı denormalize kolon (`payment_plans.status` gibi) API katmanından değil `AFTER INSERT OR UPDATE OR DELETE` trigger ile; `COALESCE(NEW.fk_col, OLD.fk_col)` INSERT+DELETE'i yakalar. Trigger'ın UPDATE'i başka trigger'ı tetiklememeli; ağır aggregate'e index (`CREATE INDEX ON payments(plan_id)`).
- **L-0089** — AFTER-row trigger kendi tablosunu UPDATE'lerse sonsuz döngü. BEFORE-row (satır alanı hesabı) + AFTER-STATEMENT (toplam/sync) ayrımı; per-event ayrı trigger + `TG_OP` dallanması; gerekirse `pg_trigger_depth()` guard. Tek trigger'da OLD+NEW TABLE geçersiz (OLD yalnız UPDATE/DELETE, NEW yalnız INSERT/UPDATE).
- **L-0052** — DB içinde biten zamanlanmış iş için Vercel Cron değil `pg_cron`: migration'da `SELECT cron.schedule('job-name', '0 0 * * *', $$SELECT public.fn()$$)`. Cron UTC çalışır (TR +3); job adı unique; re-deploy'da önce `DELETE FROM cron.job WHERE jobname='...'`. Harici cron yalnız DB dışı kaynağı (HTTP endpoint) tetikliyorsa.
- **L-0076** — Periyodik satır üreticisi başlangıcını kaydın `created_at`'ine kırp: `iter := greatest(date_trunc('month', current_date), date_trunc('month', rec.created_at))` + `IF due_date >= rec.created_at::date`. İdempotentlik `ON CONFLICT DO NOTHING`. Eski hatalı satırlar için ayrı, otomatik çalışmayan cancel betiği (`status='cancelled'`, DRY→commit).
- **L-0058** — Rate-limited harici API'yi her istekte çağırma; cevabı Supabase tablosuna `fetched_at` TTL kolonu ile cache'le; TTL dolunca tazele; toplu çekim `pg_cron` ile. Her harici API özelliğinde "cache katmanı var mı?" sor.

### Migration sırası ve canlı şema
- **L-0007** — Canlı şema repo migration'larından drift eder; feature/fix öncesi `information_schema.columns` ile bak. Production'ı elle değiştirme, yalnız migration dosyası.
- **L-0081** — Canlıda henüz olmayan enum değeriyle DB filtresi (`.neq('status','cancelled')`) "invalid input value for enum" ile 500 verir; elemeyi JS'te `rows.filter(...)` ile yap. DB-enum filtresi yalnız değer canlıda kesin varken. enum add ≠ enum use (ayrı migration).
- **L-0072** — Ertelenen migration'a bağımlı sayfa: her sorgu `(data ?? [])` / `?.` ile boş veriyle render (olmayan tablo `{data:null,error}` döner). Test katmanla: saf birim + boş-durum render e2e DB'siz geçer; kayıt→liste/RPC testi migration sonrasına, rapora "canlı doğrulama sonra". View'lar `security_invoker=true`.
- **L-0095** — `db push` küçük numaralı bekleyen migration'ı atlar ("Found local migration files to be inserted before the last migration on remote... Rerun with --include-all"). Dry-run ile kapsamı doğrula, sonra `npx supabase db push --linked --include-all`. Numara boşluğu (0029) sorun değil.

### Canlı backfill
- **L-0093** — Migration olmayan tek seferlik düzeltme `supabase/backfills/<tarih>.sql` (`begin; … commit;`), migrations/'a konmaz. `supabase db query --linked` postgres rolüyle bağlanır (RLS bypass, `auth.uid()` boş); `is_staff()` gerekiyorsa aynı tx'te `select set_config('request.jwt.claims','{"sub":"<staff-uuid>","role":"authenticated"}', true)`. DRY (rollback) → doğrula → commit iki-pass. Çok-statement yalnız son sonucu döner; ara sonuçları AYRI sorgularla al. Dönüşümü (E.164 vb.) yalnız geçerli desende uygula; PII'yi ham loglama.

### Vercel sınırları
- **L-0034** — Vercel serverless kalıcı WebSocket/Socket.IO tutamaz (ayrı 3001 portu prod'da kapalı kalır); realtime için Supabase Realtime Channels (alternatif Ably/Pusher veya Railway/Fly.io ayrı sunucu).
- **L-0035** — Vercel function body limiti ~4.5MB (base64 +%33); dosyayı istemciden doğrudan Supabase Storage bucket'a yükle, API route yalnız URL'yi kaydetsin (alternatif Vercel Blob).

## v2.23'ten taşınan bloklar
**ZORUNLU STACK:** Supabase org: <supabase-org-id> (gerçek değer: arşiv BÖLÜM B) | Region: eu-west-2. Her proje ayrı Supabase projesi; duplicate deploy kontrolü yap.

**BLOK 13 — SUPABASE**
- Her tabloda RLS aktif. Yeni tablo = RLS zorunlu. İstemci yazmaları SECURITY DEFINER RPC üzerinden; tabloya doğrudan write yok.
- RLS + UPSERT (v2.14): PostgREST doğrudan upsert (on_conflict + resolution=merge-duplicates) RLS WITH CHECK'e takılıp 401 verir → SECURITY DEFINER RPC; istemci anon anahtarını kullanır.
- SERVICE ROLE KEY (v2.14): SUPABASE_SERVICE_ROLE_KEY yalnızca server-side; ASLA NEXT_PUBLIC_* altında veya client bundle'da, ASLA commit — aksi halde RLS tümüyle bypass (hook da yakalar).
- CANLI ŞEMA (v2.14): Feature/fix öncesi `select column_name from information_schema.columns where table_name='X'`; production DB'yi elle değiştirme — sadece migration dosyaları üzerinden.

**BLOK 12 — KVKK (veri kısmı):** Aydınlatma metni; sağlık verisi koruma (RLS + log'a yazmama, L-0016); hesap silme hakkı — kullanıcı verisini silen/anonimleştiren RPC ve cascade planı tasarımda hazır olmalı.

**DESTRUCTİVE:** DB drop ve üretim verisi değişikliği açık onay ister (`drop database/table` hook da yakalar).

## Rapora yazılacak
- `Uygulanan dersler: L-...` satırı — yalnız gerçekten uygulananlar, numaralarıyla.
- Kanıt: canlı şema sorgusu çıktısı (tablo + kolonlar), migration dosya adı/numarası, `db push` dry-run çıktısı, backfill DRY (rollback) sonucu; RLS için policy adı + `(select ...)` sarımı; RPC için `SET search_path = public` + auth guard satırı.
- Ertelenen migration varsa "Varsayım: canlı doğrulama sonra" notu; canlı push/merge için bekleyen onay maddesi.

Kaynak dersler: L-0002, L-0003, L-0007, L-0016, L-0017, L-0034, L-0035, L-0052, L-0053, L-0055, L-0056, L-0058, L-0072, L-0074, L-0076, L-0081, L-0082, L-0089, L-0092, L-0093, L-0095
