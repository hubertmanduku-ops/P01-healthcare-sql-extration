-- ================================================================
-- 03_joins.sql — Joining Tables
-- ================================================================
-- A database stores data in MULTIPLE TABLES to avoid repetition.
--   employees table: employee_id, name, department, salary
--   sales table:     sale_id, employee_id, total_amount, sale_date
--   customers table: customer_id, company, city, segment
--
-- To answer "Which employee made the most sales this year?" you need
-- BOTH tables. A JOIN combines them by matching a shared key column.
--
-- JOIN TYPES:
--   INNER JOIN  → only rows that match in BOTH tables
--   LEFT JOIN   → ALL rows from left + matching rows from right (NULLs where no match)
--   RIGHT JOIN  → ALL rows from right + matching rows from left (NULLs where no match)
--   FULL JOIN   → ALL rows from BOTH tables (NULLs where no match on either side)
--
-- THE KEY PRINCIPLE:
--   You join ON the column that connects the two tables.
--   employees.employee_id = sales.employee_id
--   This says: "match an employee row with a sale row when the employee_id is the same"
-- ================================================================


-- ================================================================
-- SECTION 1: INNER JOIN
-- ================================================================
-- Returns only rows that have a matching value in BOTH tables.
-- Employees who have no sales → NOT in the result.
-- Sales with no matching employee_id → NOT in the result.
-- ================================================================

-- 1.1 — Basic INNER JOIN: employees with their sales
-- We use table aliases (e for employees, s for sales) to keep queries readable.
-- e.employee_id references the employee_id column in the employees table.
SELECT
    e.first_name,
    e.last_name,
    e.department,
    s.sale_id,
    s.total_amount,
    s.sale_date
FROM bootcamp_data.employees AS e
INNER JOIN bootcamp_data.sales AS s
    ON e.employee_id = s.employee_id    -- the matching condition
LIMIT 20;


-- 1.2 — INNER JOIN with aggregation: top salespeople
-- Join + GROUP BY + ORDER BY → ranked leaderboard
SELECT
    e.first_name,
    e.last_name,
    e.department,
    COUNT(s.sale_id)                        AS num_sales,
    ROUND(SUM(s.total_amount)::NUMERIC, 2)  AS total_revenue,
    ROUND(AVG(s.total_amount)::NUMERIC, 2)  AS avg_sale_value
FROM bootcamp_data.employees AS e
INNER JOIN bootcamp_data.sales AS s
    ON e.employee_id = s.employee_id
WHERE s.status = 'Completed'    -- only count completed sales
GROUP BY e.employee_id, e.first_name, e.last_name, e.department
ORDER BY total_revenue DESC
LIMIT 10;


-- 1.3 — Three-table JOIN: employees + sales + customers
-- Each JOIN adds another table. ON connects the new table to an existing one.
SELECT
    e.first_name        AS employee_first,
    e.department,
    c.company           AS customer_company,
    c.segment           AS customer_segment,
    s.total_amount,
    s.sale_date
FROM bootcamp_data.employees AS e
INNER JOIN bootcamp_data.sales AS s
    ON e.employee_id = s.employee_id
INNER JOIN bootcamp_data.customers AS c
    ON s.customer_id = c.customer_id
WHERE s.status = 'Completed'
  AND c.segment = 'Enterprise'    -- only enterprise customers
ORDER BY s.total_amount DESC
LIMIT 15;


-- ================================================================
-- SECTION 2: LEFT JOIN
-- ================================================================
-- Returns ALL rows from the LEFT table.
-- If there is no matching row in the RIGHT table, the right columns get NULL.
-- Use when: "Show me all employees, and their sales if they have any."
-- ================================================================

-- 2.1 — Basic LEFT JOIN: all employees, with sales if available
-- Employees with no sales will appear with NULL in sale_id and total_amount.
SELECT
    e.first_name,
    e.last_name,
    e.department,
    s.sale_id,
    s.total_amount
FROM bootcamp_data.employees AS e
LEFT JOIN bootcamp_data.sales AS s
    ON e.employee_id = s.employee_id
LIMIT 20;


-- 2.2 — LEFT JOIN to find employees with NO sales
-- After a LEFT JOIN, rows with no match in the right table have NULL right columns.
-- Filter WHERE right_column IS NULL → find unmatched rows.
-- This is the most common use of LEFT JOIN in analytics.
SELECT
    e.first_name,
    e.last_name,
    e.department
FROM bootcamp_data.employees AS e
LEFT JOIN bootcamp_data.sales AS s
    ON e.employee_id = s.employee_id
WHERE s.sale_id IS NULL    -- NULL here means: this employee has no sales at all
ORDER BY e.department;


-- 2.3 — LEFT JOIN with aggregation: all employees + their sales totals
-- COALESCE(value, fallback) returns the fallback if value is NULL.
-- Employees with no sales get 0 revenue and 0 sales count instead of NULL.
SELECT
    e.first_name,
    e.last_name,
    e.department,
    COALESCE(COUNT(s.sale_id), 0)                AS num_sales,
    COALESCE(ROUND(SUM(s.total_amount)::NUMERIC, 2), 0) AS total_revenue
FROM bootcamp_data.employees AS e
LEFT JOIN bootcamp_data.sales AS s
    ON e.employee_id = s.employee_id
WHERE e.is_active = TRUE
GROUP BY e.employee_id, e.first_name, e.last_name, e.department
ORDER BY total_revenue DESC;


-- ================================================================
-- SECTION 3: Self-join — joining a table to itself
-- ================================================================
-- Used when a table has a reference to another row in the SAME table.
-- employees.manager_id references another employee's employee_id.
-- ================================================================

-- 3.1 — Employee + their manager name
-- We alias the same table twice: e = employee, m = manager
SELECT
    e.first_name  AS employee_first,
    e.last_name   AS employee_last,
    e.department,
    e.salary,
    m.first_name  AS manager_first,
    m.last_name   AS manager_last
FROM bootcamp_data.employees AS e
LEFT JOIN bootcamp_data.employees AS m    -- same table, different alias
    ON e.manager_id = m.employee_id       -- employee's manager_id matches manager's employee_id
WHERE e.is_active = TRUE
ORDER BY e.department, e.salary DESC
LIMIT 15;
