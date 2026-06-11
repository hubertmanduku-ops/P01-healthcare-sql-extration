-- ================================================================
-- 05_extract_raw_data.sql — Healthcare Data Extraction Query
-- ================================================================
-- PURPOSE:
--   This is the query that DataExtractor.run() executes via Python.
--   It joins patients + appointments + doctors +
--   departments + billing to produce raw-data.csv.
--
--   raw-data.csv is the input to Module 05 ETL.
--
-- WHY THIS QUERY EXISTS:
--   The database is normalized for OLTP performance.
--   Analytics, BI dashboards, and ML models need a single flat table.
--   This is the "denormalisation layer" of the pipeline.
--
-- THE DATA IS INTENTIONALLY MESSY:
--   After seeding, the database may contain:
--     - Missing patient contact information
--     - Appointments without billing records
--     - Cancelled appointments mixed with completed visits
--     - Missing insurance information
--     - Unpaid or partially paid bills
--     - Doctors with incomplete profiles
--
--   Module 05 ETL will clean and transform these issues.
--   We intentionally do NOT fix them here.
--
-- CHANGE SCHEMA BEFORE RUNNING:
--   The {industry} placeholder is replaced by Python config.
-- ================================================================

SELECT

    -- ── Patient Master Data ──────────────────────────────────────
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.blood_type,
    p.email,
    p.phone,
    p.city,
    p.insurance_type,
    p.registered_at,

    -- ── Doctor Master Data ───────────────────────────────────────
    d.doctor_id,
    d.first_name AS doctor_first_name,
    d.last_name AS doctor_last_name,
    d.specialization,
    d.years_exp,
    d.salary,
    d.email AS doctor_email,
    d.phone AS doctor_phone,
    d.hire_date,
    d.is_active AS doctor_active,

    -- ── Department Master Data ───────────────────────────────────
    dept.dept_id,
    dept.dept_name,
    dept.floor_number,
    dept.head_doctor,
    dept.bed_count,

    -- ── Appointment Facts (base transaction data) ────────────────
    a.appointment_id,
    a.appointment_date,
    a.appointment_time,
    a.status,
    a.visit_type,
    a.duration_mins,
    a.fee,
    a.notes,

    -- ── Billing Data (may be NULL if billing not yet generated) ──
    b.bill_id,
    b.amount_charged,
    b.insurance_paid,
    b.patient_paid,
    b.payment_status,
    b.bill_date,
    b.payment_method,

    -- ── Derived Features (light enrichment, NOT ETL cleaning) ────

    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth))
        AS patient_age,

    (b.amount_charged - COALESCE(b.insurance_paid, 0))
        AS outstanding_amount,

    CASE
        WHEN a.status = 'Completed' THEN 1
        ELSE 0
    END AS completed_visit_flag,

    CASE
        WHEN b.payment_status = 'Paid' THEN 1
        ELSE 0
    END AS payment_completed_flag,

    CASE
        WHEN p.insurance_type IS NULL THEN 1
        ELSE 0
    END AS missing_insurance_flag,

    -- ── Metadata ────────────────────────────────────────────────
    '{industry}'::VARCHAR AS source_schema,
    NOW()::DATE AS extracted_date

FROM {industry}.appointments a

-- Patient join (who received care)
LEFT JOIN {industry}.patients p
    ON a.patient_id = p.patient_id

-- Doctor join (who provided care)
LEFT JOIN {industry}.doctors d
    ON a.doctor_id = d.doctor_id

-- Department join (where doctor belongs)
LEFT JOIN {industry}.departments dept
    ON d.dept_id = dept.dept_id

-- Billing join (optional, some appointments may not yet be billed)
LEFT JOIN {industry}.billing b
    ON a.appointment_id = b.appointment_id
    AND a.patient_id = b.patient_id

-- Easier CSV reading
ORDER BY
    a.appointment_date DESC,
    a.appointment_id;