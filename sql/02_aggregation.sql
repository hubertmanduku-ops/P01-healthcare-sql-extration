-- ================================================================
-- 02_aggregation.sql — GROUP BY and Aggregate Functions
-- ================================================================
-- Aggregation answers questions like:
--   "What is the average salary per department?"
--   "How many employees are in each city?"
--   "What is the total revenue by product category?"
--
-- AGGREGATE FUNCTIONS reduce many rows to one summary value:
--   COUNT(*)       → how many rows
--   COUNT(column)  → how many non-null values
--   SUM(column)    → total of all values
--   AVG(column)    → arithmetic average
--   MIN(column)    → smallest value
--   MAX(column)    → largest value
--   ROUND(n, d)    → round n to d decimal places
--
-- GROUP BY splits the table into groups before aggregating.
-- Without GROUP BY: one number for the entire table.
-- With GROUP BY: one number per group.
-- ================================================================


-- ================================================================
-- SECTION 1: Basic aggregation (no GROUP BY)
-- ================================================================

-- 1.1 — Count total employees
SELECT COUNT(*) AS total_employees
FROM bootcamp_data.employees;

-- 1.2 — Count only active employees
-- COUNT(*) counts all rows. COUNT(column) counts non-null values in that column.
SELECT
    COUNT(*)             AS total_rows,
    COUNT(salary)        AS employees_with_salary,    -- excludes NULLs
    COUNT(*) - COUNT(salary) AS employees_missing_salary
FROM bootcamp_data.employees;

-- 1.3 — Company-wide salary statistics
SELECT
    COUNT(*)                    AS headcount,
    ROUND(AVG(salary)::NUMERIC, 2) AS avg_salary,
    ROUND(MIN(salary)::NUMERIC, 2) AS min_salary,
    ROUND(MAX(salary)::NUMERIC, 2) AS max_salary,
    ROUND(MAX(salary) - MIN(salary), 2) AS salary_range
FROM bootcamp_data.employees
WHERE salary IS NOT NULL;


-- ================================================================
-- SECTION 2: GROUP BY — aggregation per group
-- ================================================================

-- 2.1 — Headcount per department
-- GROUP BY splits employees into department groups.
-- COUNT(*) then counts rows within each group.
SELECT
    department,
    COUNT(*) AS headcount
FROM bootcamp_data.employees
GROUP BY department       -- one row per unique department value
ORDER BY headcount DESC;  -- most employees first


-- 2.2 — Salary statistics per department
SELECT
    department,
    COUNT(*)                          AS headcount,
    ROUND(AVG(salary)::NUMERIC, 0)    AS avg_salary,
    ROUND(MIN(salary)::NUMERIC, 0)    AS min_salary,
    ROUND(MAX(salary)::NUMERIC, 0)    AS max_salary,
    ROUND(MAX(salary) - MIN(salary), 0) AS salary_range
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
GROUP BY department
ORDER BY avg_salary DESC;


-- 2.3 — Multiple GROUP BY columns
-- Group by BOTH department AND performance_rating.
-- Result: one row per (department, performance_rating) combination.
-- This answers: "For each department, how many employees in each rating?"
SELECT
    department,
    performance_rating,
    COUNT(*) AS count
FROM bootcamp_data.employees
WHERE is_active = TRUE
GROUP BY department, performance_rating
ORDER BY department, count DESC;


-- 2.4 — GROUP BY with WHERE
-- WHERE filters BEFORE grouping.
-- Only active employees are included before the group calculation.
-- RULE: WHERE cannot reference aggregate functions — use HAVING for that.
SELECT
    department,
    COUNT(*) AS active_headcount,
    ROUND(AVG(salary)::NUMERIC, 0) AS avg_salary
FROM bootcamp_data.employees
WHERE is_active = TRUE       -- filter rows BEFORE grouping
  AND salary IS NOT NULL
GROUP BY department
ORDER BY avg_salary DESC;


-- ================================================================
-- SECTION 3: HAVING — filtering after aggregation
-- ================================================================
-- WHERE filters individual rows BEFORE grouping.
-- HAVING filters GROUPS AFTER grouping.
-- Rule: if your filter uses an aggregate function (COUNT, AVG, etc.)
--       you MUST use HAVING, not WHERE.
-- ================================================================

-- 3.1 — Departments with more than 50 employees
-- This cannot use WHERE because headcount is computed after grouping.
SELECT
    department,
    COUNT(*) AS headcount
FROM bootcamp_data.employees
GROUP BY department
HAVING COUNT(*) > 50       -- filter groups AFTER counting
ORDER BY headcount DESC;


-- 3.2 — Departments with average salary above £90,000
SELECT
    department,
    ROUND(AVG(salary)::NUMERIC, 0) AS avg_salary,
    COUNT(*) AS headcount
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
GROUP BY department
HAVING AVG(salary) > 90000   -- filter groups where the average is above £90k
ORDER BY avg_salary DESC;


-- 3.3 — Combining WHERE and HAVING
-- WHERE: only active employees with salaries
-- HAVING: only departments where the average salary > £80k
SELECT
    department,
    COUNT(*) AS active_headcount,
    ROUND(AVG(salary)::NUMERIC, 0) AS avg_salary
FROM bootcamp_data.employees
WHERE is_active = TRUE           -- applied BEFORE grouping
  AND salary IS NOT NULL
GROUP BY department
HAVING AVG(salary) > 80000       -- applied AFTER grouping
   AND COUNT(*) >= 10             -- AND at least 10 employees
ORDER BY avg_salary DESC;


-- ================================================================
-- SECTION 4: The SQL Execution Order
-- ================================================================
-- SQL does NOT execute in the order you write it.
-- The actual execution order is:
--   1. FROM        → identify the table(s)
--   2. WHERE       → filter rows
--   3. GROUP BY    → split into groups
--   4. HAVING      → filter groups
--   5. SELECT      → compute output columns
--   6. ORDER BY    → sort results
--   7. LIMIT       → restrict row count
--
-- This is why you cannot use an alias from SELECT in a WHERE clause —
-- WHERE runs BEFORE SELECT so the alias does not exist yet.
-- ================================================================

-- 4.1 — Sales aggregation (using the sales table)
SELECT
    status,
    COUNT(*)                          AS num_sales,
    ROUND(SUM(total_amount)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(total_amount)::NUMERIC, 2) AS avg_sale_value,
    ROUND(MAX(total_amount)::NUMERIC, 2) AS max_single_sale
FROM bootcamp_data.sales
GROUP BY status
ORDER BY total_revenue DESC;
