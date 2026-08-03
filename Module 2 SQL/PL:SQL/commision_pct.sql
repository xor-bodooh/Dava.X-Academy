CREATE OR REPLACE PROCEDURE adjust_salaries_by_commission IS
   
    v_module VARCHAR2(100) := 'adjust_salaries_by_commission';
    v_update_count NUMBER := 0;
    v_new_salary NUMBER;
BEGIN
    
    debug_utils.log_msg(v_module, 'Starting salary adjustment process', 'INFO');

   
FOR emp IN (SELECT employee_id, salary, commission_pct FROM employees) LOOP
BEGIN
            
            IF emp.commission_pct IS NOT NULL THEN
                
                v_new_salary := emp.salary + (emp.salary * emp.commission_pct);
                debug_utils.log_variable(v_module, 'emp_' || emp.employee_id || '_calc', 'Commission logic applied');
ELSE
              
                v_new_salary := emp.salary + (emp.salary * 0.02);
                debug_utils.log_variable(v_module, 'emp_' || emp.employee_id || '_calc', 'Flat 2% logic applied');
END IF;

    
            debug_utils.log_variable(v_module, 'emp_id_' || emp.employee_id || '_new_salary', TO_CHAR(v_new_salary));

            
UPDATE employees
SET salary = v_new_salary
WHERE employee_id = emp.employee_id;

v_update_count := v_update_count + 1;

EXCEPTION
            WHEN OTHERS THEN
              
                debug_utils.log_error(v_module, 'Failed to update employee ' || emp.employee_id || '. Error: ' || SQLERRM);
END;
END LOOP;

    
    debug_utils.log_msg(v_module, 'Process finished successfully. Total rows updated: ' || v_update_count, 'INFO');

COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      
        debug_utils.log_error(v_module, 'FATAL ERROR in procedure: ' || SQLERRM);
ROLLBACK;
END adjust_salaries_by_commission;
/