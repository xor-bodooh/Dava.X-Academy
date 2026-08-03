-- Run the procedure with debugging enabled
BEGIN
    debug_utils.enable_debug;
    adjust_salaries_by_commission;
    debug_utils.disable_debug;
END;
/
-- RESULTS
SELECT * FROM debug_log;
SELECT * FROM employees;