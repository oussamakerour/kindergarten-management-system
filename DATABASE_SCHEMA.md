# قاعدة البيانات - Database Schema
## نظام إدارة روضة الأطفال

---

## 1. جدول المستخدمين (Users)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(120) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  role ENUM('admin', 'teacher', 'staff', 'parent') NOT NULL,
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES users(id),
  
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
```

---

## 2. جدول الأقسام/الفصول (Classes)
```sql
CREATE TABLE classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  capacity INT NOT NULL CHECK (capacity > 0),
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  assistant_teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  academic_year VARCHAR(10) NOT NULL,
  age_group ENUM('1-2_years', '2-3_years', '3-4_years', '4-5_years') NOT NULL,
  status ENUM('active', 'inactive', 'archived') DEFAULT 'active',
  room_number VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_class_per_year UNIQUE (kindergarten_id, code, academic_year)
);

CREATE INDEX idx_classes_teacher ON classes(teacher_id);
CREATE INDEX idx_classes_kindergarten ON classes(kindergarten_id);
CREATE INDEX idx_classes_status ON classes(status);
```

---

## 3. جدول الأطفال (Children)
```sql
CREATE TABLE children (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name VARCHAR(150) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender ENUM('male', 'female') NOT NULL,
  national_id VARCHAR(50),
  blood_type VARCHAR(5),
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
  enrollment_date DATE NOT NULL,
  enrollment_status ENUM('active', 'graduated', 'withdrawn', 'on_leave') DEFAULT 'active',
  emergency_contact_name VARCHAR(150),
  emergency_contact_phone VARCHAR(20),
  medical_notes TEXT,
  dietary_restrictions TEXT,
  allergies TEXT,
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT child_age CHECK (EXTRACT(YEAR FROM age(date_of_birth)) BETWEEN 1 AND 6)
);

CREATE INDEX idx_children_kindergarten ON children(kindergarten_id);
CREATE INDEX idx_children_class ON children(class_id);
CREATE INDEX idx_children_enrollment_status ON children(enrollment_status);
```

---

## 4. جدول أولياء الأمور (Parents)
```sql
CREATE TABLE parents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  relationship ENUM('father', 'mother', 'guardian', 'other') NOT NULL,
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
```

---

## 5. جدول الحضور والغياب (Attendance)
```sql
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attendee_id UUID NOT NULL,
  attendee_type ENUM('child', 'teacher', 'staff') NOT NULL,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status ENUM('present', 'absent', 'late', 'excused', 'leave') DEFAULT 'absent',
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
```

---

## 6. جدول الاشتراكات والدفعات (Subscriptions & Payments)
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  subscription_type ENUM('monthly', 'quarterly', 'annual', 'daily') NOT NULL,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) DEFAULT 'USD',
  start_date DATE NOT NULL,
  end_date DATE,
  status ENUM('active', 'paused', 'cancelled') DEFAULT 'active',
  discount_percentage DECIMAL(5, 2) DEFAULT 0,
  discount_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscriptions_child ON subscriptions(child_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
```

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  payment_method ENUM('cash', 'bank_transfer', 'check', 'credit_card', 'mobile_wallet') NOT NULL,
  payment_status ENUM('paid', 'pending', 'overdue', 'partial') DEFAULT 'pending',
  due_date DATE NOT NULL,
  paid_date DATE,
  receipt_number VARCHAR(100) UNIQUE,
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES users(id),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT check_payment_amount CHECK (paid_date IS NULL OR paid_date >= payment_date)
);

CREATE INDEX idx_payments_child ON payments(child_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_due_date ON payments(due_date);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
```

---

## 7. جدول رواتب المربيات والموظفين (Salaries & Payroll)
```sql
CREATE TABLE salary_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  basic_salary DECIMAL(10, 2) NOT NULL CHECK (basic_salary > 0),
  position VARCHAR(100) NOT NULL,
  employment_type ENUM('full_time', 'part_time', 'contract') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  currency VARCHAR(3) DEFAULT 'USD',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_salary_config_user ON salary_configurations(user_id);
```

```sql
CREATE TABLE salary_payments (
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
  payment_status ENUM('pending', 'paid', 'delayed') DEFAULT 'pending',
  payment_date DATE,
  payment_method ENUM('bank_transfer', 'cash', 'check') NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_salary_payments_user ON salary_payments(user_id);
CREATE INDEX idx_salary_payments_month ON salary_payments(payment_month);
CREATE INDEX idx_salary_payments_status ON salary_payments(payment_status);
```

---

## 8. جدول الأنشطة (Activities)
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(150) NOT NULL,
  description TEXT,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  activity_type ENUM('educational', 'sports', 'arts', 'cultural', 'trip', 'workshop', 'other') NOT NULL,
  is_paid BOOLEAN DEFAULT FALSE,
  fee DECIMAL(10, 2) CHECK (fee IS NULL OR fee >= 0),
  currency VARCHAR(3) DEFAULT 'USD',
  age_groups TEXT[], -- Array of age groups
  max_participants INT,
  status ENUM('draft', 'pending_approval', 'approved', 'rejected', 'completed', 'cancelled') DEFAULT 'draft',
  approval_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
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
```

---

## 9. جدول المشاركين في الأنشطة (Activity Subscriptions)
```sql
CREATE TABLE activity_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  enrollment_status ENUM('registered', 'confirmed', 'participated', 'cancelled') DEFAULT 'registered',
  fee_paid BOOLEAN DEFAULT FALSE,
  payment_id UUID REFERENCES payments(id),
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,
  
  CONSTRAINT unique_activity_child UNIQUE (activity_id, child_id)
);

CREATE INDEX idx_activity_subscriptions_activity ON activity_subscriptions(activity_id);
CREATE INDEX idx_activity_subscriptions_child ON activity_subscriptions(child_id);
CREATE INDEX idx_activity_subscriptions_status ON activity_subscriptions(enrollment_status);
```

---

## 10. جدول المصروفات (Expenses)
```sql
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kindergarten_id UUID NOT NULL REFERENCES kindergartens(id) ON DELETE CASCADE,
  category ENUM('salaries', 'utilities', 'maintenance', 'supplies', 'equipment', 'other') NOT NULL,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) DEFAULT 'USD',
  expense_date DATE NOT NULL,
  payment_method ENUM('bank_transfer', 'cash', 'check', 'credit_card') NOT NULL,
  approved_by UUID REFERENCES users(id),
  approval_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  status ENUM('recorded', 'paid', 'pending') DEFAULT 'recorded',
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
```

---

## 11. جدول الروضات (Kindergartens)
```sql
CREATE TABLE kindergartens (
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
  director_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  logo_url TEXT,
  currency_code VARCHAR(3) DEFAULT 'USD',
  established_date DATE,
  status ENUM('active', 'inactive', 'archived') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kindergartens_status ON kindergartens(status);
```

---

## 12. جدول صلاحيات الأدوار (Role Permissions)
```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  permission_code VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  category VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_role_permission UNIQUE (role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
```

---

## 13. جدول النشاطات والتغييرات (Audit Logs)
```sql
CREATE TABLE audit_logs (
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
```

---

## العلاقات الرئيسية (Key Relationships)

```
Users (1) ──→ (Many) Classes (as teachers)
Classes (1) ──→ (Many) Children
Children (1) ──→ (Many) Subscriptions
Children (1) ──→ (Many) Payments
Children (1) ──→ (Many) Attendance
Children (1) ──→ (Many) ActivitySubscriptions
Parents (Many) ──→ (1) Children
Users (1) ──→ (Many) SalaryConfigurations
SalaryConfigurations (1) ──→ (Many) SalaryPayments
Activities (1) ──→ (Many) ActivitySubscriptions
ActivitySubscriptions (1) ──→ (1) Payments
Kindergartens (1) ──→ (Many) Classes
Kindergartens (1) ──→ (Many) Children
Kindergartens (1) ──→ (Many) Activities
Kindergartens (1) ──→ (Many) Expenses
```

---

## ملاحظات مهمة

- استخدام **UUID** لجميع المفاتيح الأساسية (Primary Keys) لأسباب الأمان والتوسع
- جميع الجداول تحتوي على `created_at` و `updated_at` لتتبع التغييرات
- استخدام **ENUM** للحالات المحددة مسبقاً
- إضافة **Indexes** على الحقول المستخدمة في الاستعلامات المتكررة
- استخدام **JSONB** للبيانات المرنة في جدول التدقيق
- جميع المبالغ المالية بصيغة **DECIMAL** لتجنب مشاكل الدقة
- استخدام **Constraints** للتحقق من صحة البيانات
