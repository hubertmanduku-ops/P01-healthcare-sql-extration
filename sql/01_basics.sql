-- ================================================================
-- 01_basics.sql — SQL Fundamentals
-- ================================================================
-- HOW TO USE THIS FILE:
--   Open in DBeaver. Read each section. Highlight a query.
--   Press Ctrl+Enter to run just that highlighted query.
--   Look at the results. Modify the query. Run again.
--   Learning SQL is about EXPERIMENTING — not memorising.
--
-- DATABASE: Supabase PostgreSQL
-- SCHEMA:   Healthcare
-- TABLE:    patients  --- change this as per the patient data (1,000 rows of GlobalTech workforce data)
-- ================================================================


-- ================================================================
-- SECTION 1: SELECT — The most important SQL keyword
-- ================================================================
-- SELECT tells PostgreSQL which COLUMNS you want.
-- FROM tells PostgreSQL which TABLE to read from.
-- Every SQL query starts with SELECT ... FROM ...
-- ================================================================

-- 1.1 — Select ALL columns (the asterisk * means "all columns")
-- Use this to see the full structure of a table for the first time.
-- CAUTION: Never use SELECT * in production — always name specific columns.
SELECT *
FROM healthcare.patients
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)


-- 1.2 — Select SPECIFIC columns (best practice)
-- Only request the columns you actually need.
-- This is faster (less data transferred) and easier to read.
SELECT
    patient_id,
    first_name,
    last_name,
    phone,
    insurance_type
FROM healthcare.patients
LIMIT 10;


-- 1.3 — Column aliases with AS
-- AS renames a column in the output — does NOT change the original table.
-- Useful for making column names cleaner or more descriptive.
SELECT
    patient_id,
    first_name  AS "First Name",      -- rename with spaces requires double quotes
    last_name   AS "Last Name",
    phone      AS "phone Number",        -- rename without spaces uses no quotes
    insurance_type AS "Insurance type"     -- you can do arithmetic directly in SELECT
FROM healthcare.patients
LIMIT 10;


-- 1.4 — DISTINCT — remove duplicate values
-- Returns only unique values in the specified column(s).
-- Like Python's list(set(values)) but much faster at scale.
SELECT DISTINCT insurance_type
FROM healthcare.patients
ORDER BY insurance_type;    -- ORDER BY sorts alphabetically (ASC by default)


-- ================================================================
-- SECTION 2: WHERE — Filtering rows
-- ================================================================
-- WHERE filters which ROWS appear in the result.
-- Only rows where the condition is TRUE are returned.
-- WHERE is always placed AFTER FROM and BEFORE ORDER BY.
-- ================================================================

-- 2.1 — Simple equality filter
-- Find all patients with private insurance type.
SELECT first_name, last_name, phone, city
FROM healthcare.patients
WHERE insurance_type = 'Private';   -- text values use SINGLE quotes in SQL


-- 2.2 — Numeric comparison operators
-- >  (greater than)
-- >= (greater than or equal to)
-- <  (less than)
-- <= (less than or equal to)
-- =  (equal to)
-- <> or != (not equal to)
SELECT first_name, last_name, phone, city
FROM healthcare.patients
WHERE blood_type = 'O-'
ORDER BY city DESC;   -- DESC = descending (highest first), ASC = ascending (default)


-- 2.3 — AND: both conditions must be true
-- using doctors table Find those earning above £300k
SELECT first_name, last_name, dept_id, salary, years_exp
FROM healthcare.doctors
WHERE specialization = 'Cardiology'
  AND salary > 300000
  AND is_active = TRUE;


-- 2.4 — OR: at least one condition must be true
-- Find employees in either Engineering or Data Science
SELECT first_name, last_name, specialization, salary
FROM healthcare.doctors
WHERE specialization = 'Cardiology'
   OR specialization = 'Pediatrics'
ORDER BY specialization, salary DESC;


-- 2.5 — IN: cleaner alternative to multiple OR conditions
-- Equivalent to WHERE department = 'A' OR department = 'B' OR department = 'C'
SELECT first_name, last_name, specialization, salary
FROM healthcare.doctors
WHERE specialization IN ('Pediatrics', 'Radiology', 'Surgery')
ORDER BY specialization, salary DESC;


-- 2.6 — BETWEEN: range filter (inclusive on both ends)
-- BETWEEN low AND high → equivalent to col >= low AND col <= high
SELECT first_name, last_name, salary, years_exp
FROM healthcare.doctors
WHERE salary BETWEEN 70000 AND 120000
  AND years_exp > 7
ORDER BY salary;


-- 2.7 — LIKE: pattern matching for text
-- %  matches any sequence of characters (like * in file search)
-- _  matches exactly one character
-- ILIKE is the case-insensitive version (PostgreSQL-specific)
SELECT first_name, last_name, email
FROM healthcare.doctors
WHERE email ILIKE '%hospital.org%'   -- email contains "hospital.org" (case-insensitive)
LIMIT 10;


-- 2.8 — IS NULL and IS NOT NULL
-- NULL means "no value present" — NOT the same as 0 or empty string
-- You CANNOT use = NULL (this always returns nothing in SQL)
-- You MUST use IS NULL or IS NOT NULL
SELECT first_name, last_name, specialization, salary
FROM healthcare.doctors
WHERE salary IS NULL;     -- find doctors with no salary recorded

-- Doctors who DO have a salary:
SELECT COUNT(*) AS doctors_with_salary
FROM healthcare.doctors
WHERE salary IS NOT NULL;


-- ================================================================
-- SECTION 3: ORDER BY and LIMIT
-- ================================================================

-- 3.1 — ORDER BY: sort results
-- ASC  = ascending  (A→Z, 0→9) — this is the DEFAULT if you don't specify
-- DESC = descending (Z→A, 9→0)
SELECT first_name, last_name, salary
FROM healthcare.doctors
WHERE is_active = TRUE
ORDER BY salary DESC;   -- highest salary first


-- 3.2 — Multiple sort columns
-- Sort by department A→Z, then within each department by salary highest first
SELECT first_name, last_name, specialization, salary
FROM healthcare.doctors
ORDER BY specialization ASC, salary DESC;


-- 3.3 — LIMIT and OFFSET — pagination
-- LIMIT restricts how many rows to return
-- OFFSET skips the first N rows (used for pagination in web apps)
-- "Give me rows 11-20" → LIMIT 10 OFFSET 10
SELECT first_name, last_name, salary
FROM healthcare.doctors
ORDER BY salary DESC
LIMIT 10        -- top 10 earners
OFFSET 0;       -- start from the beginning (page 1)

-- Page 2 (rows 11-20):
SELECT first_name, last_name, salary
FROM healthcare.doctors
ORDER BY salary DESC
LIMIT 10
OFFSET 10;      -- skip the first 10 rows (page 2)
