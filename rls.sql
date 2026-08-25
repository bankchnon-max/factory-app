-- =====================================================================
-- ล็อกตาราง kv_store ให้เฉพาะคนที่ล็อกอินแล้วเท่านั้นที่อ่าน/เขียนได้
-- วางทั้งไฟล์นี้ใน Supabase → SQL Editor → New query → Run
--
-- ⚠ ทำ "ขั้นที่ 4" เท่านั้น หลังจากล็อกอินครบทุกเครื่องแล้ว (ดู SECURITY-SETUP.md)
--
-- สถานะจริงที่ตรวจเจอเมื่อ 24 ส.ค. 2569:
--   RLS เปิดอยู่แล้ว แต่มี policy 3 อันที่เปิดให้ role "public" (= ใครก็ได้
--   ที่มี key ในหน้าเว็บ) อ่าน/เพิ่ม/แก้ได้ทั้งหมด → ช่องโหว่อยู่ตรงนี้
--   สคริปต์นี้จะ "ลบ 3 อันนั้นทิ้ง" แล้วสร้างใหม่ให้เฉพาะคนที่ล็อกอิน
-- =====================================================================

alter table public.kv_store enable row level security;

-- ---------------------------------------------------------------------
-- 1) ลบ policy เดิมที่เปิดให้ใครก็ได้ ← ขั้นที่ปิดช่องโหว่จริง
-- ---------------------------------------------------------------------
drop policy if exists "allow anon read"   on public.kv_store;
drop policy if exists "allow anon insert" on public.kv_store;
drop policy if exists "allow anon update" on public.kv_store;

-- ---------------------------------------------------------------------
-- 2) สร้าง policy ใหม่ ให้เฉพาะคนที่ล็อกอินแล้ว (authenticated)
-- ---------------------------------------------------------------------

-- อ่านข้อมูล
drop policy if exists "wpd_select_authenticated" on public.kv_store;
create policy "wpd_select_authenticated"
  on public.kv_store for select
  to authenticated
  using (true);

-- เพิ่มข้อมูลใหม่
drop policy if exists "wpd_insert_authenticated" on public.kv_store;
create policy "wpd_insert_authenticated"
  on public.kv_store for insert
  to authenticated
  with check (true);

-- แก้ข้อมูลเดิม (จำเป็น เพราะแอพบันทึกแบบ upsert)
drop policy if exists "wpd_update_authenticated" on public.kv_store;
create policy "wpd_update_authenticated"
  on public.kv_store for update
  to authenticated
  using (true)
  with check (true);

-- ไม่เปิดสิทธิ์ลบแถวให้ใคร แอพไม่ได้ใช้อยู่แล้ว
drop policy if exists "wpd_delete_authenticated" on public.kv_store;

-- ---------------------------------------------------------------------
-- ตรวจผล: ต้องเห็น rowsecurity = true
-- และเหลือ policy แค่ 3 อันที่ขึ้นต้นด้วย wpd_ และ roles = {authenticated}
-- ถ้ายังเห็น "allow anon ..." อยู่ แปลว่ายังไม่ปิดช่องโหว่
-- ---------------------------------------------------------------------
select relname, relrowsecurity as rowsecurity
from pg_class where relname = 'kv_store';

select policyname, cmd, roles
from pg_policies where tablename = 'kv_store'
order by policyname;

-- =====================================================================
-- ย้อนกลับ ถ้ามีปัญหา (แอพกลับมาใช้ได้ทันที ข้อมูลไม่หาย)
-- วางเฉพาะ 3 บรรทัดนี้แล้ว Run
-- =====================================================================
-- create policy "allow anon read"   on public.kv_store for select to public using (true);
-- create policy "allow anon insert" on public.kv_store for insert to public with check (true);
-- create policy "allow anon update" on public.kv_store for update to public using (true) with check (true);
