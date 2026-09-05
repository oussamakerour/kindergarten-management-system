-- Kindergarten Management System Database Schema
-- This SQL file should be executed in Supabase SQL Editor
-- Database: PostgreSQL with UUID Extension

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- 1. جدول الروضات (Kindergartens)
-- ============================================================================
CREATE TABLE IF NOT EXISTS kindergartens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(150) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(120) UNIQUE NOT NULL,
  phone VARCHAR(20) NOT NULL,
  address TEXT NOT NULL,
  city VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20),
  country VARCHAR(100),
  website VARCHAR(255),
  license_number VARCHAR(100),
  license_expiry_date DATE,
  director_id UUID,
  logo_url TEXT,
  currency_code VARCHAR(3) DEFAULT 'USD',
  established_date DATE,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kindergartens_status ON kindergartens(status);
CREATE INDEX idx_kindergartens_code ON kindergartens(code);

-- ============================================================================
-- 2. جدول المستخدمين (Users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(120) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(50) NOT NULL DEFAULT 'teacher' CHECK (role IN ('admin', 'teacher', 'staff', 'parent')),
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  profile_picture_url TEXT,
  kindergarten_id UUID REFERENCES kindergartens(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_kindergarten ON users(kindergarten_id);

-- ============================================================================
-- 3. جدول الأقسام/الفصول (Classes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) NOT NULL,
  description TEXT,
  capacity INT NOT NULL CHECK (capacity > 0),
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  assistant_teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  academic_year VARCHAR(10) NOT NULL,
  age_group VARCHAR(50) NOT NULL CHECK (age_group IN ('1-2_years', '2-3_years', '3-4_years', '4-5_years')),
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  room_number VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_class_per_year UNIQUE (kindergarten_id, code, academic_year)
);

CREATE INDEX idx_classes_teacher ON classes(teacher_id);
CREATE INDEX idx_classes_kindergarten ON classes(kindergarten_id);
CREATE INDEX idx_classes_status ON classes(status);

-- ============================================================================
-- 4. جدول الأطفال (Children)
-- ============================================================================
CREATE TABLE IF NOT EXISTS children (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name VARCHAR(150) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender VARCHAR(20) NOT NULL CHECK (gender IN ('male', 'female')),
  national_id VARCHAR(50),
  blood_type VARCHAR(5),
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
  enrollment_date DATE NOT NULL,
  enrollment_status VARCHAR(50) DEFAULT 'active' CHECK (enrollment_status IN ('active', 'graduated', 'withdrawn', 'on_leave')),
  emergency_contact_name VARCHAR(150),
  emergency_contact_phone VARCHAR(20),
  medical_notes TEXT,
  dietary_restrictions TEXT,
  allergies TEXT,
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_children_kindergarten ON children(kindergarten_id);
CREATE INDEX idx_children_class ON children(class_id);
CREATE INDEX idx_children_enrollment_status ON children(enrollment_status);

-- ============================================================================
-- 5. جدول أولياء الأمور (Parents)
-- ============================================================================
CREATE TABLE IF NOT EXISTS parents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  relationship VARCHAR(50) NOT NULL CHECK (relationship IN ('father', 'mother', 'guardian', 'other')),
  occupation VARCHAR(100),
  company VARCHAR(100),
  work_phone VARCHAR(20),
  address TEXT,
  city VARCHAR(100),
  postal_code VARCHAR(20),
  is_primary_contact BOOLEAN DEFAULT FALSE,
  custody_documents_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parents_user ON parents(user_id);
CREATE INDEX idx_parents_child ON parents(child_id);

-- ============================================================================
-- 6. جدول الحضور والغياب (Attendance)
-- ============================================================================
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attendee_id UUID NOT NULL,
  attendee_type VARCHAR(50) NOT NULL CHECK (attendee_type IN ('child', 'teacher', 'staff')),
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status VARCHAR(50) DEFAULT 'absent' CHECK (status IN ('present', 'absent', 'late', 'excused', 'leave')),
  check_in_time TIME,
  check_out_time TIME,
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES users(id),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_attendance UNIQUE (attendee_id, date, attendee_type)
);

CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_attendance_attendee ON attendance(attendee_id);
CREATE INDEX idx_attendance_class ON attendance(class_id);
CREATE INDEX idx_attendance_status ON attendance(status);

-- ============================================================================
-- 7. جدول الاشتراكات (Subscriptions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  subscription_type VARCHAR(50) NOT NULL CHECK (subscription_type IN ('monthly', 'quarterly', 'annual', 'daily')),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) DEFAULT 'USD',
  start_date DATE NOT NULL,
  end_date DATE,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
  discount_percentage DECIMAL(5, 2) DEFAULT 0,
  discount_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscriptions_child ON subscriptions(child_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- ============================================================================
-- 8. جدول الدفعات (Payments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'credit_card', 'mobile_wallet')),
  payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN ('paid', 'pending', 'overdue', 'partial')),
  due_date DATE NOT NULL,
  paid_date DATE,
  receipt_number VARCHAR(100) UNIQUE,
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES users(id),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_child ON payments(child_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_due_date ON payments(due_date);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);

-- ============================================================================
-- 9. جدول تكوينات الرواتب (Salary Configurations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS salary_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  basic_salary DECIMAL(10, 2) NOT NULL CHECK (basic_salary > 0),
  position VARCHAR(100) NOT NULL,
  employment_type VARCHAR(50) NOT NULL CHECK (employment_type IN ('full_time', 'part_time', 'contract')),
  start_date DATE NOT NULL,
  end_date DATE,
  currency VARCHAR(3) DEFAULT 'USD',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_salary_config_user ON salary_configurations(user_id);
CREATE INDEX idx_salary_config_kindergarten ON salary_configurations(kindergarten_id);

-- ============================================================================
-- 10. جدول دفعات الرواتب (Salary Payments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS salary_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  salary_config_id UUID NOT NULL REFERENCES salary_configurations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payment_month DATE NOT NULL,
  basic_salary DECIMAL(10, 2) NOT NULL,
  attendance_days INT NOT NULL CHECK (attendance_days >= 0),
  total_working_days INT NOT NULL CHECK (total_working_days > 0),
  attendance_percentage DECIMAL(5, 2) NOT NULL,
  bonuses DECIMAL(10, 2) DEFAULT 0,
  deductions DECIMAL(10, 2) DEFAULT 0,
  deduction_notes TEXT,
  net_salary DECIMAL(10, 2) NOT NULL,
  payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'delayed')),
  payment_date DATE,
  payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('bank_transfer', 'cash', 'check')),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_salary_payments_user ON salary_payments(user_id);
CREATE INDEX idx_salary_payments_month ON salary_payments(payment_month);
CREATE INDEX idx_salary_payments_status ON salary_payments(payment_status);

-- ============================================================================
-- 11. جدول الأنشطة (Activities)
-- ============================================================================
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(150) NOT NULL,
  description TEXT,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN ('educational', 'sports', 'arts', 'cultural', 'trip', 'workshop', 'other')),
  is_paid BOOLEAN DEFAULT FALSE,
  fee DECIMAL(10, 2),
  currency VARCHAR(3) DEFAULT 'USD',
  age_groups TEXT[],
  max_participants INT,
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'completed', 'cancelled')),
  approval_status VARCHAR(50) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES users(id),
  approval_date TIMESTAMP,
  rejection_reason TEXT,
  scheduled_date DATE,
  scheduled_time TIME,
  duration_hours INT,
  location VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activities_kindergarten ON activities(kindergarten_id);
CREATE INDEX idx_activities_status ON activities(status);
CREATE INDEX idx_activities_approval_status ON activities(approval_status);
CREATE INDEX idx_activities_scheduled_date ON activities(scheduled_date);

-- ============================================================================
-- 12. جدول اشتراكات الأنشطة (Activity Subscriptions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS activity_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  enrollment_status VARCHAR(50) DEFAULT 'registered' CHECK (enrollment_status IN ('registered', 'confirmed', 'participated', 'cancelled')),
  fee_paid BOOLEAN DEFAULT FALSE,
  payment_id UUID REFERENCES payments(id),
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,
  
  CONSTRAINT unique_activity_child UNIQUE (activity_id, child_id)
);

CREATE INDEX idx_activity_subscriptions_activity ON activity_subscriptions(activity_id);
CREATE INDEX idx_activity_subscriptions_child ON activity_subscriptions(child_id);
CREATE INDEX idx_activity_subscriptions_status ON activity_subscriptions(enrollment_status);

-- ============================================================================
-- 13. جدول المصروفات (Expenses)
-- ============================================================================
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL CHECK (category IN ('salaries', 'utilities', 'maintenance', 'supplies', 'equipment', 'other')),
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) DEFAULT 'USD',
  expense_date DATE NOT NULL,
  payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('bank_transfer', 'cash', 'check', 'credit_card')),
  approved_by UUID REFERENCES users(id),
  approval_status VARCHAR(50) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  status VARCHAR(50) DEFAULT 'recorded' CHECK (status IN ('recorded', 'paid', 'pending')),
  notes TEXT,
  receipt_url TEXT,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_expenses_kindergarten ON expenses(kindergarten_id);
CREATE INDEX idx_expenses_category ON expenses(category);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_expenses_approval_status ON expenses(approval_status);

-- ============================================================================
-- 14. جدول الأدوار (Roles)
-- ============================================================================
CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 15. جدول الصلاحيات (Permissions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  permission_code VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  category VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 16. جدول صلاحيات الأدوار (Role Permissions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);

-- ============================================================================
-- 17. جدول سجلات التدقيق (Audit Logs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  table_name VARCHAR(100) NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- ============================================================================
-- البيانات الافتراضية (Sample Data)
-- ============================================================================

-- إدراج روضة افتراضية
INSERT INTO kindergartens (name, code, email, phone, address, city, postal_code, country, license_number, status)
VALUES (
  'روضة الأحلام',
  'KG-001',
  'kindergarten@example.com',
  '+966501234567',
  'شارع التربية، حي النور',
  'الرياض',
  '12345',
  'السعودية',
  'LIC-2024-001',
  'active'
) ON CONFLICT DO NOTHING;

-- إدراج مستخدم مسير عام
INSERT INTO users (username, email, password_hash, full_name, phone, role, status)
VALUES (
  'admin',
  'admin@kindergarten.com',
  crypt('admin123', gen_salt('bf')),
  'المسير العام',
  '+966501111111',
  'admin',
  'active'
) ON CONFLICT DO NOTHING;

-- إدراج مستخدم معلمة
INSERT INTO users (username, email, password_hash, full_name, phone, role, status)
VALUES (
  'teacher1',
  'teacher1@kindergarten.com',
  crypt('teacher123', gen_salt('bf')),
  'فاطمة أحمد',
  '+966502222222',
  'teacher',
  'active'
) ON CONFLICT DO NOTHING;

-- إدراج الأدوار الأساسية
INSERT INTO roles (role_name, description) VALUES
('admin', 'المسير العام - صلاحيات كاملة'),
('teacher', 'معلمة - إدارة فصل وتحصيل'),
('staff', 'موظف - دعم إداري'),
('parent', 'ولي أمر - عرض المعلومات فقط')
ON CONFLICT DO NOTHING;

-- إدراج الصلاحيات الأساسية
INSERT INTO permissions (permission_code, description, category) VALUES
('view_dashboard', 'عرض لوحة التحكم', 'dashboard'),
('manage_users', 'إدارة المستخدمين', 'users'),
('manage_classes', 'إدارة الأقسام', 'classes'),
('manage_children', 'إدارة الأطفال', 'children'),
('record_attendance', 'تسجيل الحضور', 'attendance'),
('manage_payments', 'إدارة الدفعات', 'payments'),
('manage_salaries', 'إدارة الرواتب', 'payroll'),
('create_activity', 'إنشاء نشاط', 'activities'),
('approve_activity', 'الموافقة على الأنشطة', 'activities'),
('view_reports', 'عرض التقارير', 'reports'),
('manage_expenses', 'إدارة المصروفات', 'expenses'),
('manage_permissions', 'إدارة الصلاحيات', 'system')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- تحديثات تلقائية (Automatic Updates)
-- ============================================================================

-- دالة تحديث updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تطبيق الدالة على جميع الجداول
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at
  BEFORE UPDATE ON classes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_children_updated_at
  BEFORE UPDATE ON children
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at
  BEFORE UPDATE ON activities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- الآراء المساعدة (Helper Views)
-- ============================================================================

-- عرض ملخص الإيرادات الشهرية
CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT
  DATE_TRUNC('month', p.payment_date)::DATE AS month,
  c.kindergarten_id,
  COUNT(DISTINCT c.id) AS total_children,
  COUNT(DISTINCT CASE WHEN p.payment_status = 'paid' THEN p.id END) AS paid_count,
  COALESCE(SUM(CASE WHEN p.payment_status = 'paid' THEN p.amount END), 0) AS total_revenue,
  COALESCE(SUM(CASE WHEN p.payment_status != 'paid' THEN p.amount END), 0) AS pending_amount
FROM children c
LEFT JOIN subscriptions s ON c.id = s.child_id
LEFT JOIN payments p ON s.id = p.subscription_id
WHERE c.enrollment_status = 'active'
GROUP BY DATE_TRUNC('month', p.payment_date), c.kindergarten_id;

-- عرض ملخص حضور الأطفال
CREATE OR REPLACE VIEW v_children_attendance_summary AS
SELECT
  c.id,
  c.full_name,
  c.class_id,
  DATE_TRUNC('month', a.date)::DATE AS month,
  COUNT(CASE WHEN a.status = 'present' THEN 1 END) AS present_days,
  COUNT(CASE WHEN a.status = 'absent' THEN 1 END) AS absent_days,
  COUNT(CASE WHEN a.status = 'late' THEN 1 END) AS late_days,
  ROUND(100.0 * COUNT(CASE WHEN a.status = 'present' THEN 1 END) / COUNT(*), 2) AS attendance_percentage
FROM children c
LEFT JOIN attendance a ON c.id = a.attendee_id AND a.attendee_type = 'child'
GROUP BY c.id, c.full_name, c.class_id, DATE_TRUNC('month', a.date);

-- عرض ملخص رواتب المعلمات
CREATE OR REPLACE VIEW v_salary_summary AS
SELECT
  u.id,
  u.full_name,
  sc.basic_salary,
  DATE_TRUNC('month', sp.payment_month)::DATE AS month,
  sp.attendance_percentage,
  sp.bonuses,
  sp.deductions,
  sp.net_salary,
  sp.payment_status
FROM users u
JOIN salary_configurations sc ON u.id = sc.user_id
LEFT JOIN salary_payments sp ON sc.id = sp.salary_config_id
WHERE u.role = 'teacher';

-- ============================================================================
-- ملاحظات مهمة
-- ============================================================================
/*
التعليمات:
1. انسخ كل هذا الملف
2. اذهب إلى Supabase SQL Editor
3. الصق الكود
4. اضغط "Run"
5. سيتم إنشاء كل الجداول والعلاقات تلقائياً

المستخدمون الافتراضيون:
- اسم المستخدم: admin
  كلمة المرور: admin123
  الدور: مسير عام

- اسم المستخدم: teacher1
  كلمة المرور: teacher123
  الدور: معلمة

ملاحظات أمان:
- غير كلمات المرور الافتراضية فوراً بعد التثبيت
- استخدم Row Level Security (RLS) لحماية البيانات
- قم بتفعيل المصادقة والتوثيق
*/
