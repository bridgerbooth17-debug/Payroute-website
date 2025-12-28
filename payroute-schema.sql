-- PayRoute Database Schema for Supabase
-- FedEx Contractor Payroll & Back-Office Automation Platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USERS & AUTHENTICATION
-- =============================================

-- Contractors (Companies that use PayRoute)
CREATE TABLE contractors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    fedex_contract_number VARCHAR(100),
    subscription_plan VARCHAR(50) DEFAULT 'starter', -- starter, professional, enterprise
    subscription_status VARCHAR(50) DEFAULT 'active', -- active, cancelled, suspended
    monthly_base_fee DECIMAL(10, 2) DEFAULT 299.00,
    per_employee_fee DECIMAL(10, 2) DEFAULT 4.50,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Admins/Managers for each contractor
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Supabase auth user
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    role VARCHAR(50) DEFAULT 'admin', -- admin, manager, owner
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Drivers (Employees of contractors)
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Supabase auth user
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    route_number VARCHAR(50),
    employee_id VARCHAR(50),
    hire_date DATE,
    termination_date DATE,
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, terminated
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- PAYROLL & PAYMENTS
-- =============================================

-- Payroll Periods
CREATE TABLE payroll_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    pay_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, approved, paid, cancelled
    total_gross DECIMAL(12, 2) DEFAULT 0.00,
    total_deductions DECIMAL(12, 2) DEFAULT 0.00,
    total_net DECIMAL(12, 2) DEFAULT 0.00,
    processed_by UUID REFERENCES admins(id),
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Individual Driver Payments
CREATE TABLE driver_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_period_id UUID REFERENCES payroll_periods(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    
    -- Pay Components
    base_pay DECIMAL(10, 2) DEFAULT 0.00,
    overtime_pay DECIMAL(10, 2) DEFAULT 0.00,
    bonus_pay DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Hours
    regular_hours DECIMAL(6, 2) DEFAULT 0.00,
    overtime_hours DECIMAL(6, 2) DEFAULT 0.00,
    
    -- Deductions
    federal_tax DECIMAL(10, 2) DEFAULT 0.00,
    state_tax DECIMAL(10, 2) DEFAULT 0.00,
    social_security DECIMAL(10, 2) DEFAULT 0.00,
    medicare DECIMAL(10, 2) DEFAULT 0.00,
    other_deductions DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Totals
    gross_pay DECIMAL(10, 2) DEFAULT 0.00,
    total_deductions DECIMAL(10, 2) DEFAULT 0.00,
    net_pay DECIMAL(10, 2) DEFAULT 0.00,
    
    payment_method VARCHAR(50) DEFAULT 'direct_deposit', -- direct_deposit, check, cash
    payment_status VARCHAR(50) DEFAULT 'pending', -- pending, processed, paid, failed
    payment_date DATE,
    
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- BONUSES
-- =============================================

-- Bonus Types
CREATE TABLE bonus_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Bonus Requests
CREATE TABLE bonus_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    bonus_type_id UUID REFERENCES bonus_types(id) ON DELETE SET NULL,
    
    bonus_name VARCHAR(100) NOT NULL,
    bonus_amount DECIMAL(10, 2) NOT NULL,
    request_date DATE NOT NULL,
    stops_count INTEGER,
    reason TEXT NOT NULL,
    
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, paid
    reviewed_by UUID REFERENCES admins(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    
    paid_in_payroll_period_id UUID REFERENCES payroll_periods(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- SCHEDULES & ROUTES
-- =============================================

-- Driver Schedules
CREATE TABLE driver_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    
    schedule_date DATE NOT NULL,
    route_number VARCHAR(50),
    start_time TIME,
    end_time TIME,
    
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
    
    stops_planned INTEGER,
    stops_completed INTEGER,
    packages_delivered INTEGER,
    
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- NOTIFICATIONS
-- =============================================

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info', -- info, success, warning, error
    
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    
    related_entity_type VARCHAR(50), -- bonus_request, payment, schedule, etc.
    related_entity_id UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- CONTACT FORM SUBMISSIONS (from website)
-- =============================================

-- Contact Form Leads
CREATE TABLE contact_leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    
    status VARCHAR(50) DEFAULT 'new', -- new, contacted, qualified, converted, rejected
    source VARCHAR(50) DEFAULT 'website', -- website, referral, other
    
    notes TEXT,
    contacted_by UUID REFERENCES admins(id),
    contacted_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- SETTINGS & CONFIGURATION
-- =============================================

-- Contractor Settings
CREATE TABLE contractor_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE UNIQUE,
    
    -- Payroll Settings
    default_pay_frequency VARCHAR(50) DEFAULT 'weekly', -- weekly, biweekly, monthly
    overtime_threshold DECIMAL(5, 2) DEFAULT 40.00,
    overtime_multiplier DECIMAL(3, 2) DEFAULT 1.50,
    
    -- Tax Settings
    federal_tax_rate DECIMAL(5, 4) DEFAULT 0.1200,
    state_tax_rate DECIMAL(5, 4) DEFAULT 0.0500,
    
    -- Bonus Settings
    enable_bonus_requests BOOLEAN DEFAULT true,
    require_bonus_approval BOOLEAN DEFAULT true,
    
    -- Notification Settings
    notify_on_bonus_request BOOLEAN DEFAULT true,
    notify_on_payment_processed BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- AUDIT LOGS
-- =============================================

-- Activity Logs
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    contractor_id UUID REFERENCES contractors(id) ON DELETE CASCADE,
    
    action VARCHAR(100) NOT NULL, -- login, create_payment, approve_bonus, etc.
    entity_type VARCHAR(50), -- payment, bonus, driver, etc.
    entity_id UUID,
    
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Contractors
CREATE INDEX idx_contractors_email ON contractors(email);
CREATE INDEX idx_contractors_subscription_status ON contractors(subscription_status);

-- Admins
CREATE INDEX idx_admins_contractor_id ON admins(contractor_id);
CREATE INDEX idx_admins_email ON admins(email);
CREATE INDEX idx_admins_user_id ON admins(user_id);

-- Drivers
CREATE INDEX idx_drivers_contractor_id ON drivers(contractor_id);
CREATE INDEX idx_drivers_email ON drivers(email);
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_status ON drivers(status);
CREATE INDEX idx_drivers_route_number ON drivers(route_number);

-- Payroll Periods
CREATE INDEX idx_payroll_periods_contractor_id ON payroll_periods(contractor_id);
CREATE INDEX idx_payroll_periods_status ON payroll_periods(status);
CREATE INDEX idx_payroll_periods_dates ON payroll_periods(period_start, period_end);

-- Driver Payments
CREATE INDEX idx_driver_payments_payroll_period_id ON driver_payments(payroll_period_id);
CREATE INDEX idx_driver_payments_driver_id ON driver_payments(driver_id);
CREATE INDEX idx_driver_payments_contractor_id ON driver_payments(contractor_id);
CREATE INDEX idx_driver_payments_status ON driver_payments(payment_status);

-- Bonus Requests
CREATE INDEX idx_bonus_requests_driver_id ON bonus_requests(driver_id);
CREATE INDEX idx_bonus_requests_contractor_id ON bonus_requests(contractor_id);
CREATE INDEX idx_bonus_requests_status ON bonus_requests(status);
CREATE INDEX idx_bonus_requests_date ON bonus_requests(request_date);

-- Driver Schedules
CREATE INDEX idx_driver_schedules_driver_id ON driver_schedules(driver_id);
CREATE INDEX idx_driver_schedules_contractor_id ON driver_schedules(contractor_id);
CREATE INDEX idx_driver_schedules_date ON driver_schedules(schedule_date);

-- Notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_contractor_id ON notifications(contractor_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Contact Leads
CREATE INDEX idx_contact_leads_status ON contact_leads(status);
CREATE INDEX idx_contact_leads_email ON contact_leads(email);

-- Activity Logs
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_contractor_id ON activity_logs(contractor_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE contractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bonus_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE bonus_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE contractor_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Contractors: Users can only see their own contractor data
CREATE POLICY "Users can view own contractor" ON contractors
    FOR SELECT USING (
        id IN (
            SELECT contractor_id FROM admins WHERE user_id = auth.uid()
            UNION
            SELECT contractor_id FROM drivers WHERE user_id = auth.uid()
        )
    );

-- Admins: Admins can see admins in their contractor
CREATE POLICY "Admins can view admins in their contractor" ON admins
    FOR SELECT USING (
        contractor_id IN (SELECT contractor_id FROM admins WHERE user_id = auth.uid())
    );

-- Drivers: Drivers can see themselves, Admins can see all drivers in their contractor
CREATE POLICY "Drivers can view own profile" ON drivers
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all drivers in contractor" ON drivers
    FOR SELECT USING (
        contractor_id IN (SELECT contractor_id FROM admins WHERE user_id = auth.uid())
    );

-- Driver Payments: Drivers see their own, Admins see all in their contractor
CREATE POLICY "Drivers can view own payments" ON driver_payments
    FOR SELECT USING (
        driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid())
    );

CREATE POLICY "Admins can view all payments in contractor" ON driver_payments
    FOR SELECT USING (
        contractor_id IN (SELECT contractor_id FROM admins WHERE user_id = auth.uid())
    );

-- Bonus Requests: Drivers see their own, Admins see all in their contractor
CREATE POLICY "Drivers can view own bonus requests" ON bonus_requests
    FOR SELECT USING (
        driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid())
    );

CREATE POLICY "Drivers can create bonus requests" ON bonus_requests
    FOR INSERT WITH CHECK (
        driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid())
    );

CREATE POLICY "Admins can view all bonus requests in contractor" ON bonus_requests
    FOR ALL USING (
        contractor_id IN (SELECT contractor_id FROM admins WHERE user_id = auth.uid())
    );

-- Notifications: Users see their own notifications
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

-- Contact Leads: Only admins can see
CREATE POLICY "Admins can view contact leads" ON contact_leads
    FOR ALL USING (
        auth.uid() IN (SELECT user_id FROM admins)
    );

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_contractors_updated_at BEFORE UPDATE ON contractors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payroll_periods_updated_at BEFORE UPDATE ON payroll_periods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_payments_updated_at BEFORE UPDATE ON driver_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bonus_types_updated_at BEFORE UPDATE ON bonus_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bonus_requests_updated_at BEFORE UPDATE ON bonus_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_schedules_updated_at BEFORE UPDATE ON driver_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contact_leads_updated_at BEFORE UPDATE ON contact_leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contractor_settings_updated_at BEFORE UPDATE ON contractor_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SEED DATA (Default Bonus Types)
-- =============================================

-- Insert default bonus types (will need contractor_id when contractor is created)
-- This is a template - you'll insert these for each new contractor during onboarding
/*
INSERT INTO bonus_types (contractor_id, name, amount, description) VALUES
    ('contractor_uuid_here', 'High Volume', 150.00, 'For exceeding 180 stops in a day'),
    ('contractor_uuid_here', 'Chains', 75.00, 'Required chains for mountain/snow routes'),
    ('contractor_uuid_here', 'Perfect Week', 200.00, '100% success rate for entire week'),
    ('contractor_uuid_here', 'Early Start', 50.00, 'Starting route before 6:00 AM');
*/
