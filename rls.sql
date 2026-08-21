-- =====================================================================
-- ล็อกตาราง kv_store ให้เฉพาะคนที่ล็อกอินแล้วเท่านั้นที่อ่าน/เขียนได้
-- วางทั้งไฟล์นี้ใน Supabase → SQL Editor → New query → Run
--
-- ⚠ ทำ "ขั้นที่ 4" เท่านั้น หลังจากล็อกอินครบทุกเครื่องแล้ว (ดู SECURITY-SETUP.md)
-- =====================================================================

alter table public.kv_store enable row level security;

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
-- ตรวจผล: ต้องเห็น rowsecurity = true และ policy 3 อัน
-- ---------------------------------------------------------------------
select relname, relrowsecurity as rowsecurity
from pg_class where relname = 'kv_store';

select policyname, cmd, roles
from pg_policies where tablename = 'kv_store'
order by policyname;

-- =====================================================================
-- ย้อนกลับ ถ้ามีปัญหา (แอพกลับมาใช้ได้ทันที ข้อมูลไม่หาย)
-- =====================================================================
-- alter table public.kv_store disable row level security;
