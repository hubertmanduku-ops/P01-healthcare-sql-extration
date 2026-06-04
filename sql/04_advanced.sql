-- ================================================================
-- 04_advanced.sql — Window Functions, CTEs, and Subqueries
-- ================================================================
-- These are the SQL features that separate junior from senior
-- data professionals. They are used in every production data pipeline.
--
-- WINDOW FUNCTIONS: compute a value for each row using a "window"
--   of related rows (without collapsing to one row like GROUP BY).
--   "What is each employee's salary RANK within their department?"
--
-- CTEs (Common Table Expressions): named temporary result sets.
--   Break a complex query into readable, named steps.
--   Defined with the WITH keyword.
--
-- SUBQUERIES: a query nested inside another query.
--   The inner query runs first; the outer query uses its result.
-- ================================================================


-- ================================================================
-- SECTION 1: Window Functions
-- ================================================================
-- SYNTAX:
--   function() OVER (
--       PARTITION BY column   ← define groups (like GROUP BY but keeps all rows)
--       ORDER BY column       ← order within each group
--   )
--
-- KEY DIFFERENCE FROM GROUP BY:
--   GROUP BY: 1 department → 1 row (collapses to summary)
--   PARTITION BY: 1 department → all original rows kept, but each gets the group stat
-- ================================================================

-- 1.1 — ROW_NUMBER: assign unique sequential numbers within each partition
-- Use case: "Give each employee a rank within their department by salary"
SELECT
    first_name,
    last_name,
    department,
    salary,
    ROW_NUMBER() OVER (
        PARTITION BY department   -- reset counter for each department
        ORDER BY salary DESC      -- highest salary gets number 1
    ) AS dept_salary_rank
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
ORDER BY department, dept_salary_rank;


-- 1.2 — RANK vs DENSE_RANK
-- RANK:       tied values get the same rank, then SKIP the next rank (1,2,2,4)
-- DENSE_RANK: tied values get the same rank, NO skip (1,2,2,3)
SELECT
    first_name,
    salary,
    RANK()       OVER (ORDER BY salary DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS rank_no_gaps
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
LIMIT 20;


-- 1.3 — Salary percentile using PERCENT_RANK
-- PERCENT_RANK returns a value between 0 and 1 showing relative position.
-- 0 = lowest, 1 = highest. A value of 0.9 means top 10% earner.
SELECT
    first_name,
    department,
    salary,
    ROUND((PERCENT_RANK() OVER (ORDER BY salary))::NUMERIC * 100, 1) AS percentile
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
ORDER BY percentile DESC
LIMIT 20;


-- 1.4 — Running total using SUM() OVER (ORDER BY)
-- SUM() as a window function computes a CUMULATIVE sum.
-- Each row's value is the total of all rows up to and including that row.
SELECT
    sale_date,
    total_amount,
    ROUND(SUM(total_amount) OVER (
        ORDER BY sale_date   -- running total ordered by date
    )::NUMERIC, 2) AS running_total
FROM bootcamp_data.sales
WHERE status = 'Completed'
ORDER BY sale_date
LIMIT 20;


-- 1.5 — LAG and LEAD: compare to previous or next row
-- LAG(column, n):  value from n rows BEFORE the current row
-- LEAD(column, n): value from n rows AFTER the current row
-- Use case: "How much did this employee's salary change from the previous hire?"
SELECT
    first_name,
    hire_date,
    salary,
    LAG(salary, 1) OVER (ORDER BY hire_date) AS prev_hire_salary,
    salary - LAG(salary, 1) OVER (ORDER BY hire_date) AS salary_diff_vs_prev_hire
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
ORDER BY hire_date
LIMIT 15;


-- 1.6 — Salary vs department average using window function
-- This is the most common window function use case in business analytics.
-- Each row keeps its individual values BUT also gets the group-level stat.
SELECT
    first_name,
    last_name,
    department,
    salary,
    ROUND(AVG(salary) OVER (PARTITION BY department)::NUMERIC, 0) AS dept_avg_salary,
    ROUND((salary - AVG(salary) OVER (PARTITION BY department))::NUMERIC, 0) AS vs_dept_avg
FROM bootcamp_data.employees
WHERE salary IS NOT NULL
ORDER BY department, vs_dept_avg DESC;


-- ================================================================
-- SECTION 2: CTEs (Common Table Expressions)
-- ================================================================
-- Syntax:
--   WITH cte_name AS (
--       SELECT ...
--   )
--   SELECT ... FROM cte_name ...
--
-- WHY USE CTEs?
--   Without CTEs, complex queries become deeply nested and unreadable.
--   CTEs give each step a name, making the logic clear and debuggable.
--   You can even define multiple CTEs in one query (separated by commas).
-- ================================================================

-- 2.1 — Basic CTE: find the top earner per department
WITH dept_top_earners AS (
    -- Step 1: rank employees within each department
    SELECT
        first_name,
        last_name,
        department,
        salary,
        ROW_NUMBER() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS rank_in_dept
    FROM bootcamp_data.employees
    WHERE salary IS NOT NULL
)
-- Step 2: filter to only the #1 ranked employee per department
SELECT
    first_name,
    last_name,
    department,
    salary
FROM dept_top_earners
WHERE rank_in_dept = 1
ORDER BY salary DESC;


-- 2.2 — Multiple CTEs: build a complete sales report step by step
WITH
-- Step 1: compute total revenue per employee
employee_revenue AS (
    SELECT
        employee_id,
        COUNT(*)                        AS num_sales,
        SUM(total_amount)               AS total_revenue
    FROM bootcamp_data.sales
    WHERE status = 'Completed'
    GROUP BY employee_id
),
-- Step 2: join with employee details
employee_details AS (
    SELECT
        e.first_name,
        e.last_name,
        e.department,
        e.salary,
        COALESCE(r.num_sales, 0)         AS num_sales,
        COALESCE(r.total_revenue, 0)     AS total_revenue
    FROM bootcamp_data.employees AS e
    LEFT JOIN employee_revenue AS r
        ON e.employee_id = r.employee_id
    WHERE e.is_active = TRUE
),
-- Step 3: rank employees by revenue within each department
ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY department
            ORDER BY total_revenue DESC
        ) AS dept_rank
    FROM employee_details
)
-- Step 4: show final results
SELECT
    first_name,
    last_name,
    department,
    salary,
    num_sales,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    dept_rank
FROM ranked
WHERE dept_rank <= 3    -- top 3 per department
ORDER BY department, dept_rank;


-- ================================================================
-- SECTION 3: Subqueries
-- ================================================================
-- A subquery is a SELECT inside another SELECT.
-- The inner query runs first. Its result is used by the outer query.
-- CTEs are generally preferred for readability, but subqueries
-- are common in production code and important to recognise.
-- ================================================================

-- 3.1 — Scalar subquery: single value used in WHERE
-- Find employees earning above the company average salary.
SELECT first_name, last_name, department, salary
FROM bootcamp_data.employees
WHERE salary > (
    SELECT AVG(salary)          -- this subquery returns ONE number
    FROM bootcamp_data.employees
    WHERE salary IS NOT NULL
)
ORDER BY salary DESC
LIMIT 10;


-- 3.2 — Subquery in FROM: treat a query result as a table
SELECT
    dept_stats.department,
    dept_stats.avg_salary,
    dept_stats.headcount
FROM (
    SELECT
        department,
        ROUND(AVG(salary)::NUMERIC, 0)  AS avg_salary,
        COUNT(*)                         AS headcount
    FROM bootcamp_data.employees
    WHERE salary IS NOT NULL
    GROUP BY department
) AS dept_stats              -- alias the subquery as a table
WHERE dept_stats.headcount > 30
ORDER BY dept_stats.avg_salary DESC;


-- 3.3 — EXISTS subquery: check if matching rows exist
-- Find departments that have at least one employee with salary > £150k
SELECT DISTINCT department
FROM bootcamp_data.employees AS e1
WHERE EXISTS (
    SELECT 1                    -- EXISTS just checks if any rows are returned
    FROM bootcamp_data.employees AS e2
    WHERE e2.department = e1.department
      AND e2.salary > 150000
)
ORDER BY department;
