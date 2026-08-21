-- ==============================================================================
-- ระบบบริหารจัดการมูลฝอยอัจฉริยะ (SPA) - โรงพยาบาล ๕๐ พรรษา มหาวชิราลงกรณ
-- โค้ดส่วนฐานข้อมูล Supabase (รันเพื่อสร้างฐานข้อมูล)
-- ==============================================================================

-- ล้างตารางเดิมเพื่อทำการอัปเกรดแบบไม่มีปัญหาการสับเปลี่ยนโครงสร้าง
DROP TABLE IF EXISTS infectious_disposal CASCADE;
DROP TABLE IF EXISTS infectious_disposal_history CASCADE;
DROP TABLE IF EXISTS infectious_subdistricts CASCADE;
DROP TABLE IF EXISTS general_waste CASCADE;
DROP TABLE IF EXISTS infectious_hazardous_waste CASCADE;
DROP TABLE IF EXISTS users_custom CASCADE;
DROP TABLE IF EXISTS ref_companies CASCADE;
DROP TABLE IF EXISTS ref_departments CASCADE;
DROP TABLE IF EXISTS ref_bins CASCADE;

-- 1. ตารางอ้างอิงถังขยะ
CREATE TABLE ref_bins (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    bin_number VARCHAR(150) UNIQUE NOT NULL,
    bin_weight NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- 2. ตารางอ้างอิงหน่วยงาน/แผนก
CREATE TABLE ref_departments (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    department_name VARCHAR(150) UNIQUE NOT NULL
);

-- 3. ตารางอ้างอิงบริษัทกำจัดขยะ
CREATE TABLE ref_companies (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    company_name VARCHAR(150) UNIQUE NOT NULL
);

-- 4. ตารางข้อมูลผู้ใช้งานระบบ
CREATE TABLE users_custom (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'User',
    created_at VARCHAR(150) DEFAULT CURRENT_TIMESTAMP::text
);

-- 5. ตารางบันทึกข้อมูลขยะติดเชื้อบริษัทรับไปกำจัด (รายถัง)
-- คอลัมน์: รหัส, วันที่, เลขที่การมารับขยะติดเชื้อ, ข้อมูลถัง, น้ำหนักที่ชั่งได้, หักน้ำหนักถัง, น้ำหนักมูลฝอยติดเชื้อรวม, คิดเป็นมูลค่าการกำจัด, บริษัทที่มารับไปกำจัด, ลงชื่อผู้ส่ง, ลงชื่อผู้บันทึก
CREATE TABLE infectious_disposal (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    created_date VARCHAR(150),
    disposal_no VARCHAR(150),
    bin_name VARCHAR(150),
    scale_weight NUMERIC(10, 2) DEFAULT 0.00,
    bin_weight NUMERIC(10, 2) DEFAULT 0.00,
    net_weight NUMERIC(10, 2) DEFAULT 0.00,
    disposal_cost NUMERIC(10, 2) DEFAULT 0.00,
    company_name VARCHAR(150),
    sender_name VARCHAR(150),
    recorded_by VARCHAR(150),
    created_at VARCHAR(150) DEFAULT CURRENT_TIMESTAMP::text
);

-- 6. ตารางบันทึกมูลฝอยติดเชื้อ รพ.สต.
CREATE TABLE infectious_subdistricts (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    year INT DEFAULT 2569,
    month VARCHAR(50),
    received_date VARCHAR(150),
    krasob NUMERIC(10, 2) DEFAULT 0.00,
    paknam NUMERIC(10, 2) DEFAULT 0.00,
    phakaew NUMERIC(10, 2) DEFAULT 0.00,
    dongsaensuk NUMERIC(10, 2) DEFAULT 0.00,
    donghonghae NUMERIC(10, 2) DEFAULT 0.00,
    pathum NUMERIC(10, 2) DEFAULT 0.00,
    tamyae NUMERIC(10, 2) DEFAULT 0.00,
    thapthai NUMERIC(10, 2) DEFAULT 0.00,
    nonggae NUMERIC(10, 2) DEFAULT 0.00,
    nongbo NUMERIC(10, 2) DEFAULT 0.00,
    dongbang NUMERIC(10, 2) DEFAULT 0.00,
    paao NUMERIC(10, 2) DEFAULT 0.00,
    nongkhon NUMERIC(10, 2) DEFAULT 0.00,
    nonglai NUMERIC(10, 2) DEFAULT 0.00,
    nongtae NUMERIC(10, 2) DEFAULT 0.00,
    huarua NUMERIC(10, 2) DEFAULT 0.00,
    huadun NUMERIC(10, 2) DEFAULT 0.00,
    damphra NUMERIC(10, 2) DEFAULT 0.00,
    khamyai NUMERIC(10, 2) DEFAULT 0.00,
    yanglum NUMERIC(10, 2) DEFAULT 0.00,
    pcu50 NUMERIC(10, 2) DEFAULT 0.00,
    recorded_by VARCHAR(150),
    created_at VARCHAR(150) DEFAULT CURRENT_TIMESTAMP::text
);

-- 7. ตารางประวัติบันทึกข้อมูลขยะติดเชื้อบริษัทรับไปกำจัด (สรุปรวมรายบิล)
-- คอลัมน์: รหัส, วันที่, เลขที่การมารับขยะติดเชื้อ, รวมน้ำหนักที่ชั่งได้, รวมหักน้ำหนักถัง, น้ำหนักมูลฝอยติดเชื้อรวม, คิดเป็นมูลค่าการกำจัด, บริษัทที่มารับไปกำจัด, ลงชื่อผู้ส่ง, ลงชื่อผู้บันทึก, รูปภาพประกอบ1, รูปภาพประกอบ2, ลิงค์ข้อมูลการชั่งน้ำหนัก (ตช.สำหรับ รพ.), เวลาบันทึก
CREATE TABLE infectious_disposal_history (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    created_date VARCHAR(150),
    disposal_no VARCHAR(150) UNIQUE,
    total_scale_weight NUMERIC(10, 2) DEFAULT 0.00,
    total_bin_weight NUMERIC(10, 2) DEFAULT 0.00,
    total_net_weight NUMERIC(10, 2) DEFAULT 0.00,
    total_cost NUMERIC(10, 2) DEFAULT 0.00,
    company_name VARCHAR(150),
    sender_name VARCHAR(150),
    recorded_by VARCHAR(150),
    photo_url_1 TEXT,
    photo_url_2 TEXT,
    weighing_link TEXT,
    created_at VARCHAR(150) DEFAULT CURRENT_TIMESTAMP::text
);

-- ดัชนีเชื่อมโยงความสัมพันธ์ของทั้ง 2 ตารางด้วย 'เลขที่การมารับขยะติดเชื้อ' (disposal_no)
CREATE INDEX IF NOT EXISTS idx_infectious_disposal_no ON infectious_disposal(disposal_no);
CREATE INDEX IF NOT EXISTS idx_infectious_disposal_hist_no ON infectious_disposal_history(disposal_no);

-- 8. ตารางบันทึกข้อมูลขยะทั่วไป
CREATE TABLE general_waste (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    year INT DEFAULT 2569,
    month VARCHAR(50),
    waste_date VARCHAR(150),
    department_id VARCHAR(150),
    general_kg NUMERIC(10, 2) DEFAULT 0.00,
    organic_kg NUMERIC(10, 2) DEFAULT 0.00,
    recorded_by VARCHAR(150),
    created_at VARCHAR(150) DEFAULT CURRENT_TIMESTAMP::text
);

-- 9. ตารางบันทึกข้อมูลขยะติดเชื้อและขยะอันตราย รพ.หลัก
CREATE TABLE infectious_hazardous_waste (
    id VARCHAR(150) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    year INT DEFAULT 2569,
    month VARCHAR(50),
    waste_date VARCHAR(150),
    sharp_infectious NUMERIC(10, 2) DEFAULT 0.00,
    non_sharp_infectious NUMERIC(10, 2) DEFAULT 0.00,
    chemical_hazard NUMERIC(10, 2) DEFAULT 0.00,
    medical_hazard NUMERIC(10, 2) DEFAULT 0.00,
    household_obg_hazard NUMERIC(10, 2) DEFAULT 0.00,
    radioactive_hazard NUMERIC(10, 2) DEFAULT 0.00,
    total_infectious NUMERIC(10, 2) DEFAULT 0.00,
    total_hazardous NUMERIC(10, 2) DEFAULT 0.00,
    recorded_by VARCHAR(150),
    created_at VARCHAR(150) DEFAULT CURRENT_TIMESTAMP::text
);

-- เปิดสิทธิ์ Row Level Security (RLS)
ALTER TABLE ref_bins ENABLE ROW LEVEL SECURITY;
ALTER TABLE ref_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ref_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_custom ENABLE ROW LEVEL SECURITY;
ALTER TABLE infectious_subdistricts ENABLE ROW LEVEL SECURITY;
ALTER TABLE infectious_disposal ENABLE ROW LEVEL SECURITY;
ALTER TABLE infectious_disposal_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE general_waste ENABLE ROW LEVEL SECURITY;
ALTER TABLE infectious_hazardous_waste ENABLE ROW LEVEL SECURITY;

-- กำหนดนโยบาย RLS ให้สามารถเข้าถึงตารางทั้งหมดได้ (Allow All Access)
CREATE POLICY select_bins ON ref_bins FOR SELECT USING (true);
CREATE POLICY insert_bins ON ref_bins FOR INSERT WITH CHECK (true);
CREATE POLICY update_bins ON ref_bins FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_bins ON ref_bins FOR DELETE USING (true);

CREATE POLICY select_depts ON ref_departments FOR SELECT USING (true);
CREATE POLICY insert_depts ON ref_departments FOR INSERT WITH CHECK (true);
CREATE POLICY update_depts ON ref_departments FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_depts ON ref_departments FOR DELETE USING (true);

CREATE POLICY select_companies ON ref_companies FOR SELECT USING (true);
CREATE POLICY insert_companies ON ref_companies FOR INSERT WITH CHECK (true);
CREATE POLICY update_companies ON ref_companies FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_companies ON ref_companies FOR DELETE USING (true);

CREATE POLICY select_users ON users_custom FOR SELECT USING (true);
CREATE POLICY insert_users ON users_custom FOR INSERT WITH CHECK (true);
CREATE POLICY update_users ON users_custom FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_users ON users_custom FOR DELETE USING (true);

CREATE POLICY select_subdist ON infectious_subdistricts FOR SELECT USING (true);
CREATE POLICY insert_subdist ON infectious_subdistricts FOR INSERT WITH CHECK (true);
CREATE POLICY update_subdist ON infectious_subdistricts FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_subdist ON infectious_subdistricts FOR DELETE USING (true);

CREATE POLICY select_disposal ON infectious_disposal FOR SELECT USING (true);
CREATE POLICY insert_disposal ON infectious_disposal FOR INSERT WITH CHECK (true);
CREATE POLICY update_disposal ON infectious_disposal FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_disposal ON infectious_disposal FOR DELETE USING (true);

CREATE POLICY select_disposal_hist ON infectious_disposal_history FOR SELECT USING (true);
CREATE POLICY insert_disposal_hist ON infectious_disposal_history FOR INSERT WITH CHECK (true);
CREATE POLICY update_disposal_hist ON infectious_disposal_history FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_disposal_hist ON infectious_disposal_history FOR DELETE USING (true);

CREATE POLICY select_general ON general_waste FOR SELECT USING (true);
CREATE POLICY insert_general ON general_waste FOR INSERT WITH CHECK (true);
CREATE POLICY update_general ON general_waste FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_general ON general_waste FOR DELETE USING (true);

CREATE POLICY select_inf_haz ON infectious_hazardous_waste FOR SELECT USING (true);
CREATE POLICY insert_inf_haz ON infectious_hazardous_waste FOR INSERT WITH CHECK (true);
CREATE POLICY update_inf_haz ON infectious_hazardous_waste FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY delete_inf_haz ON infectious_hazardous_waste FOR DELETE USING (true);

-- สถาปนารหัสผ่านแอดมินสำหรับความปลอดภัยเบื้องต้น
INSERT INTO users_custom (username, password, role) VALUES
('Sangtawan', 'Sangtawan123456789', 'Admin'),
('UserDemo', 'user1234', 'User')
ON CONFLICT (username) DO NOTHING;
