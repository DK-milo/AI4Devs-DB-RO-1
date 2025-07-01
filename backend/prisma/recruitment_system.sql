-- Sistema de Reclutamiento - Script SQL con Buenas Prácticas
-- Incluye normalización, índices optimizados, y estructuras mejoradas

-- =====================================================
-- TABLAS DE CATÁLOGO Y CONFIGURACIÓN
-- =====================================================

-- Tabla: Tipos de Empleo (normalizada)
CREATE TABLE employment_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: Estados de Posición (normalizada)
CREATE TABLE position_statuses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabla: Estados de Aplicación (normalizada)
CREATE TABLE application_statuses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    sort_order INT DEFAULT 0,
    is_final_status BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabla: Resultados de Entrevista (normalizada)
CREATE TABLE interview_results (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    is_positive BOOLEAN DEFAULT NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabla: Países (para normalizar ubicaciones)
CREATE TABLE countries (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(3) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabla: Departamentos/Estados
CREATE TABLE states (
    id INT PRIMARY KEY AUTO_INCREMENT,
    country_id INT NOT NULL,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (country_id) REFERENCES countries(id),
    UNIQUE KEY unique_country_code (country_id, code)
);

-- Tabla: Ciudades
CREATE TABLE cities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    state_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (state_id) REFERENCES states(id),
    INDEX idx_state (state_id)
);

-- =====================================================
-- TABLAS PRINCIPALES
-- =====================================================

-- Tabla: COMPANY (mejorada)
CREATE TABLE companies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255),
    tax_id VARCHAR(50),
    website VARCHAR(255),
    description TEXT,
    logo_url VARCHAR(500),
    headquarters_city_id INT,
    phone VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (headquarters_city_id) REFERENCES cities(id),
    INDEX idx_name (name),
    INDEX idx_active (is_active),
    INDEX idx_city (headquarters_city_id)
);

-- Tabla: INTERVIEW_TYPE (mejorada)
CREATE TABLE interview_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    estimated_duration_minutes INT DEFAULT 60,
    requires_preparation BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_active (is_active)
);

-- Tabla: INTERVIEW_FLOW (mejorada)
CREATE TABLE interview_flows (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    company_id INT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_company (company_id),
    INDEX idx_active (is_active),
    INDEX idx_default (is_default)
);

-- Tabla: EMPLOYEE (mejorada con departamentos)
CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    manager_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_company (company_id),
    INDEX idx_manager (manager_id)
);

CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    department_id INT,
    employee_code VARCHAR(50),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    job_title VARCHAR(100),
    hire_date DATE,
    city_id INT,
    can_interview BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    FOREIGN KEY (city_id) REFERENCES cities(id),
    UNIQUE KEY unique_company_email (company_id, email),
    UNIQUE KEY unique_company_code (company_id, employee_code),
    INDEX idx_company (company_id),
    INDEX idx_department (department_id),
    INDEX idx_email (email),
    INDEX idx_active (is_active),
    INDEX idx_can_interview (can_interview),
    INDEX idx_name (last_name, first_name)
);

-- Agregar FK para manager en departments después de crear employees
ALTER TABLE departments ADD FOREIGN KEY (manager_id) REFERENCES employees(id) ON DELETE SET NULL;

-- Tabla: POSITION (completamente normalizada)
CREATE TABLE positions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    interview_flow_id INT NOT NULL,
    department_id INT,
    position_status_id INT NOT NULL,
    employment_type_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    job_code VARCHAR(50),
    short_description TEXT,
    job_description TEXT,
    requirements TEXT,
    responsibilities TEXT,
    qualifications TEXT,
    salary_min DECIMAL(12,2),
    salary_max DECIMAL(12,2),
    salary_currency VARCHAR(3) DEFAULT 'COP',
    benefits TEXT,
    city_id INT,
    remote_work_allowed BOOLEAN DEFAULT FALSE,
    experience_years_min INT DEFAULT 0,
    experience_years_max INT,
    education_level_required VARCHAR(50),
    application_deadline DATE,
    max_applications INT,
    contact_email VARCHAR(255),
    hiring_manager_id INT,
    is_visible BOOLEAN DEFAULT TRUE,
    is_urgent BOOLEAN DEFAULT FALSE,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL,
    closed_at TIMESTAMP NULL,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (interview_flow_id) REFERENCES interview_flows(id) ON DELETE RESTRICT,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    FOREIGN KEY (position_status_id) REFERENCES position_statuses(id),
    FOREIGN KEY (employment_type_id) REFERENCES employment_types(id),
    FOREIGN KEY (city_id) REFERENCES cities(id),
    FOREIGN KEY (hiring_manager_id) REFERENCES employees(id) ON DELETE SET NULL,
    INDEX idx_company (company_id),
    INDEX idx_status (position_status_id),
    INDEX idx_visible (is_visible),
    INDEX idx_deadline (application_deadline),
    INDEX idx_created (created_at),
    INDEX idx_title (title),
    INDEX idx_city (city_id),
    INDEX idx_salary_range (salary_min, salary_max),
    INDEX idx_employment_type (employment_type_id),
    INDEX idx_department (department_id),
    FULLTEXT idx_search (title, short_description, job_description)
);

-- Tabla: INTERVIEW_STEP (mejorada)
CREATE TABLE interview_steps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    interview_flow_id INT NOT NULL,
    interview_type_id INT NOT NULL,
    step_name VARCHAR(255) NOT NULL,
    step_description TEXT,
    step_order INT NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE,
    estimated_duration_minutes INT,
    instructions TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (interview_flow_id) REFERENCES interview_flows(id) ON DELETE CASCADE,
    FOREIGN KEY (interview_type_id) REFERENCES interview_types(id) ON DELETE RESTRICT,
    UNIQUE KEY unique_flow_order (interview_flow_id, step_order),
    INDEX idx_flow (interview_flow_id),
    INDEX idx_type (interview_type_id),
    INDEX idx_order (step_order)
);

-- Tabla: CANDIDATE (mejorada con normalización)
CREATE TABLE candidates (
    id INT PRIMARY KEY AUTO_INCREMENT,
    candidate_code VARCHAR(50) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    alternative_phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20),
    city_id INT,
    address TEXT,
    linkedin_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    current_salary DECIMAL(12,2),
    expected_salary DECIMAL(12,2),
    salary_currency VARCHAR(3) DEFAULT 'COP',
    current_job_title VARCHAR(100),
    current_company VARCHAR(100),
    years_of_experience INT DEFAULT 0,
    education_level VARCHAR(50),
    english_level VARCHAR(20),
    availability_date DATE,
    notes TEXT,
    gdpr_consent BOOLEAN DEFAULT FALSE,
    gdpr_consent_date TIMESTAMP NULL,
    marketing_consent BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (city_id) REFERENCES cities(id),
    INDEX idx_email (email),
    INDEX idx_phone (phone),
    INDEX idx_city (city_id),
    INDEX idx_name (last_name, first_name),
    INDEX idx_experience (years_of_experience),
    INDEX idx_created (created_at),
    INDEX idx_last_activity (last_activity_at),
    FULLTEXT idx_search (first_name, last_name, current_job_title, current_company)
);

-- Tabla: APPLICATION (mejorada)
CREATE TABLE applications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    application_code VARCHAR(50) UNIQUE,
    position_id INT NOT NULL,
    candidate_id INT NOT NULL,
    application_status_id INT NOT NULL,
    application_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    cover_letter TEXT,
    resume_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    source VARCHAR(50), -- web, referral, linkedin, etc.
    referrer_employee_id INT,
    expected_salary DECIMAL(12,2),
    salary_currency VARCHAR(3) DEFAULT 'COP',
    availability_date DATE,
    notes TEXT,
    recruiter_notes TEXT,
    overall_score DECIMAL(3,2), -- 0.00 to 5.00
    screening_passed BOOLEAN,
    screening_date DATE,
    screened_by_employee_id INT,
    is_favorite BOOLEAN DEFAULT FALSE,
    assigned_recruiter_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_status_change_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (position_id) REFERENCES positions(id) ON DELETE CASCADE,
    FOREIGN KEY (candidate_id) REFERENCES candidates(id) ON DELETE CASCADE,
    FOREIGN KEY (application_status_id) REFERENCES application_statuses(id),
    FOREIGN KEY (referrer_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (screened_by_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_recruiter_id) REFERENCES employees(id) ON DELETE SET NULL,
    UNIQUE KEY unique_candidate_position (candidate_id, position_id),
    INDEX idx_position (position_id),
    INDEX idx_candidate (candidate_id),
    INDEX idx_status (application_status_id),
    INDEX idx_date (application_date),
    INDEX idx_recruiter (assigned_recruiter_id),
    INDEX idx_score (overall_score),
    INDEX idx_screening (screening_passed),
    INDEX idx_favorite (is_favorite),
    INDEX idx_last_status_change (last_status_change_at)
);

-- Tabla: INTERVIEW (completamente mejorada)
CREATE TABLE interviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    interview_code VARCHAR(50) UNIQUE,
    application_id INT NOT NULL,
    interview_step_id INT NOT NULL,
    interview_result_id INT,
    primary_interviewer_id INT NOT NULL,
    interview_date DATE NOT NULL,
    interview_time TIME,
    estimated_duration_minutes INT DEFAULT 60,
    actual_duration_minutes INT,
    location VARCHAR(255),
    meeting_url VARCHAR(500),
    meeting_room VARCHAR(100),
    technical_score INT CHECK (technical_score >= 0 AND technical_score <= 100),
    behavioral_score INT CHECK (behavioral_score >= 0 AND behavioral_score <= 100),
    overall_score INT CHECK (overall_score >= 0 AND overall_score <= 100),
    strengths TEXT,
    weaknesses TEXT,
    interviewer_notes TEXT,
    candidate_feedback TEXT,
    next_steps TEXT,
    recommendation VARCHAR(50), -- HIRE, REJECT, NEXT_ROUND, etc.
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    no_show BOOLEAN DEFAULT FALSE,
    rescheduled_from_interview_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (interview_step_id) REFERENCES interview_steps(id) ON DELETE RESTRICT,
    FOREIGN KEY (interview_result_id) REFERENCES interview_results(id),
    FOREIGN KEY (primary_interviewer_id) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (rescheduled_from_interview_id) REFERENCES interviews(id) ON DELETE SET NULL,
    INDEX idx_application (application_id),
    INDEX idx_step (interview_step_id),
    INDEX idx_interviewer (primary_interviewer_id),
    INDEX idx_date (interview_date),
    INDEX idx_completed (is_completed),
    INDEX idx_result (interview_result_id),
    INDEX idx_scores (overall_score, technical_score, behavioral_score)
);

-- Tabla: Entrevistadores adicionales (relación muchos a muchos)
CREATE TABLE interview_participants (
    id INT PRIMARY KEY AUTO_INCREMENT,
    interview_id INT NOT NULL,
    employee_id INT NOT NULL,
    role VARCHAR(50) DEFAULT 'INTERVIEWER', -- INTERVIEWER, OBSERVER, NOTE_TAKER
    notes TEXT,
    individual_score INT CHECK (individual_score >= 0 AND individual_score <= 100),
    recommendation VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (interview_id) REFERENCES interviews(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    UNIQUE KEY unique_interview_employee (interview_id, employee_id),
    INDEX idx_interview (interview_id),
    INDEX idx_employee (employee_id)
);

-- =====================================================
-- TABLAS DE AUDITORÍA Y LOGS
-- =====================================================

-- Tabla: Historial de cambios de estado de aplicaciones
CREATE TABLE application_status_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    application_id INT NOT NULL,
    from_status_id INT,
    to_status_id INT NOT NULL,
    changed_by_employee_id INT,
    change_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (from_status_id) REFERENCES application_statuses(id),
    FOREIGN KEY (to_status_id) REFERENCES application_statuses(id),
    FOREIGN KEY (changed_by_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
    INDEX idx_application (application_id),
    INDEX idx_date (created_at)
);

-- =====================================================
-- ÍNDICES COMPUESTOS PARA CONSULTAS COMPLEJAS
-- =====================================================

-- Índices para reportes y analytics
CREATE INDEX idx_positions_active_visible ON positions(company_id, is_visible, position_status_id);
CREATE INDEX idx_applications_by_position_status ON applications(position_id, application_status_id, application_date);
CREATE INDEX idx_interviews_by_date_result ON interviews(interview_date, interview_result_id, is_completed);
CREATE INDEX idx_candidates_by_experience_city ON candidates(years_of_experience, city_id, is_active);

-- Índices para búsquedas frecuentes
CREATE INDEX idx_positions_search ON positions(company_id, is_visible, city_id, employment_type_id);
CREATE INDEX idx_applications_recruiter_status ON applications(assigned_recruiter_id, application_status_id, last_status_change_at);

-- =====================================================
-- DATOS MAESTROS INICIALES
-- =====================================================

-- Estados de posición
INSERT INTO position_statuses (code, name, description, sort_order) VALUES 
('DRAFT', 'Borrador', 'Posición en proceso de creación', 1),
('PUBLISHED', 'Publicada', 'Posición activa y visible', 2),
('PAUSED', 'Pausada', 'Posición temporalmente inactiva', 3),
('FILLED', 'Ocupada', 'Posición ya cubierta', 4),
('CANCELLED', 'Cancelada', 'Posición cancelada', 5);

-- Estados de aplicación
INSERT INTO application_statuses (code, name, description, sort_order, is_final_status) VALUES 
('NEW', 'Nueva', 'Aplicación recién recibida', 1, FALSE),
('SCREENING', 'Screening', 'En proceso de screening inicial', 2, FALSE),
('INTERVIEW', 'Entrevista', 'En proceso de entrevistas', 3, FALSE),
('REFERENCE', 'Referencias', 'Verificación de referencias', 4, FALSE),
('OFFER', 'Oferta', 'Oferta extendida', 5, FALSE),
('HIRED', 'Contratado', 'Candidato contratado', 6, TRUE),
('REJECTED', 'Rechazado', 'Aplicación rechazada', 7, TRUE),
('WITHDRAWN', 'Retirada', 'Candidato se retiró del proceso', 8, TRUE);

-- Resultados de entrevista
INSERT INTO interview_results (code, name, description, is_positive, sort_order) VALUES 
('EXCELLENT', 'Excelente', 'Candidato excepcional', TRUE, 1),
('GOOD', 'Bueno', 'Candidato cumple expectativas', TRUE, 2),
('AVERAGE', 'Promedio', 'Candidato promedio', NULL, 3),
('POOR', 'Deficiente', 'Candidato no cumple expectativas', FALSE, 4),
('NO_SHOW', 'No asistió', 'Candidato no se presentó', FALSE, 5);

-- Tipos de empleo
INSERT INTO employment_types (code, name, description) VALUES 
('FULL_TIME', 'Tiempo Completo', 'Posición de tiempo completo'),
('PART_TIME', 'Medio Tiempo', 'Posición de medio tiempo'),
('CONTRACT', 'Contrato', 'Posición por contrato temporal'),
('FREELANCE', 'Freelance', 'Trabajo independiente'),
('INTERNSHIP', 'Práctica', 'Posición de práctica/pasantía');

-- Tipos de entrevista
INSERT INTO interview_types (code, name, description, estimated_duration_minutes) VALUES 
('PHONE', 'Telefónica', 'Entrevista telefónica inicial', 30),
('VIDEO', 'Video', 'Entrevista por video llamada', 45),
('TECHNICAL', 'Técnica', 'Evaluación técnica especializada', 90),
('BEHAVIORAL', 'Comportamental', 'Entrevista de competencias y cultura', 60),
('PANEL', 'Panel', 'Entrevista con múltiples entrevistadores', 75),
('FINAL', 'Final', 'Entrevista final con directivos', 60),
('CASE_STUDY', 'Caso de Estudio', 'Presentación y análisis de caso', 120);

-- Datos geográficos básicos para Colombia
INSERT INTO countries (code, name) VALUES ('COL', 'Colombia');

INSERT INTO states (country_id, code, name) VALUES 
(1, 'BOG', 'Bogotá D.C.'),
(1, 'ANT', 'Antioquia'),
(1, 'VAC', 'Valle del Cauca'),
(1, 'ATL', 'Atlántico'),
(1, 'SAN', 'Santander');

INSERT INTO cities (state_id, name) VALUES 
(1, 'Bogotá'),
(2, 'Medellín'),
(3, 'Cali'),
(4, 'Barranquilla'),
(5, 'Bucaramanga');

-- =====================================================
-- TRIGGERS PARA AUDITORÍA
-- =====================================================

-- Trigger para actualizar last_activity_at en candidates
DELIMITER //
CREATE TRIGGER update_candidate_activity 
    AFTER INSERT ON applications 
    FOR EACH ROW 
BEGIN
    UPDATE candidates 
    SET last_activity_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.candidate_id;
END //

-- Trigger para crear historial de cambios de estado
CREATE TRIGGER application_status_change_log
    AFTER UPDATE ON applications
    FOR EACH ROW
BEGIN
    IF OLD.application_status_id != NEW.application_status_id THEN
        INSERT INTO application_status_history (
            application_id, 
            from_status_id, 
            to_status_id, 
            created_at
        ) VALUES (
            NEW.id, 
            OLD.application_status_id, 
            NEW.application_status_id, 
            CURRENT_TIMESTAMP
        );
        
        UPDATE applications 
        SET last_status_change_at = CURRENT_TIMESTAMP 
        WHERE id = NEW.id;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- VISTAS ÚTILES PARA REPORTES
-- =====================================================

-- Vista: Posiciones activas con información completa
CREATE VIEW v_active_positions AS
SELECT 
    p.id,
    p.title,
    c.name as company_name,
    ct.name as city_name,
    st.name as state_name,
    ps.name as status_name,
    et.name as employment_type,
    p.salary_min,
    p.salary_max,
    p.created_at,
    p.application_deadline,
    COUNT(a.id) as application_count
FROM positions p
JOIN companies c ON p.company_id = c.id
JOIN position_statuses ps ON p.position_status_id = ps.id
JOIN employment_types et ON p.employment_type_id = et.id
LEFT JOIN cities ct ON p.city_id = ct.id
LEFT JOIN states st ON ct.state_id = st.id
LEFT JOIN applications a ON p.id = a.position_id
WHERE p.is_visible = TRUE AND ps.code IN ('PUBLISHED')
GROUP BY p.id;

-- Vista: Pipeline de candidatos por posición
CREATE VIEW v_candidate_pipeline AS
SELECT 
    p.id as position_id,
    p.title as position_title,
    a.id as application_id,
    CONCAT(ca.first_name, ' ', ca.last_name) as candidate_name,
    ca.email as candidate_email,
    ast.name as application_status,
    a.application_date,
    a.overall_score,
    COUNT(i.id) as interview_count,
    MAX(i.interview_date) as last_interview_date
FROM positions p
JOIN applications a ON p.id = a.position_id
JOIN candidates ca ON a.candidate_id = ca.id
JOIN application_statuses ast ON a.application_status_id = ast.id
LEFT JOIN interviews i ON a.id = i.application_id
GROUP BY a.id;

-- Vista: Métricas de reclutamiento por mes
CREATE VIEW v_recruitment_metrics AS
SELECT 
    DATE_FORMAT(a.application_date, '%Y-%m') as month_year,
    COUNT(a.id) as total_applications,
    COUNT(DISTINCT a.position_id) as active_positions,
    COUNT(DISTINCT a.candidate_id) as unique_candidates,
    AVG(a.overall_score) as avg_score,
    COUNT(CASE WHEN ast.code = 'HIRED' THEN 1 END) as hires,
    COUNT(CASE WHEN ast.code = 'REJECTED' THEN 1 END) as rejections
FROM applications a
JOIN application_statuses ast ON a.application_status_id = ast.id
WHERE a.application_date >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(a.application_date, '%Y-%m')
ORDER BY month_year DESC;