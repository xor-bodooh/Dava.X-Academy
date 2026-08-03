CREATE OR REPLACE PACKAGE BODY debug_utils AS

    --ERROR HANDLING SEPARATE SESSION
    PROCEDURE insert_log(p_module VARCHAR2, p_line NUMBER, p_level VARCHAR2, p_message VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION; 
    BEGIN
        IF g_debug_mode OR p_level = 'ERROR' THEN
            INSERT INTO debug_log (module_name, line_no, log_level, log_message)
            VALUES (p_module, p_line, p_level, p_message);
            COMMIT; 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Logging Framework Error: ' || SQLERRM); -- IF ANYTHING FAILS , PRINT TO DEV CONSOLE
    END insert_log;
    -- ENABLE/ DISABLE DEBUGGING
    PROCEDURE enable_debug IS BEGIN g_debug_mode := TRUE; END;
    PROCEDURE disable_debug IS BEGIN g_debug_mode := FALSE; END;
    -- LOG MESSAGE
    PROCEDURE log_msg(p_module VARCHAR2, p_message VARCHAR2, p_level VARCHAR2 DEFAULT 'INFO', p_line NUMBER DEFAULT NULL) IS
    BEGIN
        insert_log(p_module, p_line, p_level, p_message);
    END log_msg;

    -- LOG VARIABLE
    PROCEDURE log_variable(p_module VARCHAR2, p_name VARCHAR2, p_value VARCHAR2, p_line NUMBER DEFAULT NULL) IS
    BEGIN
        insert_log(p_module, p_line, 'DEBUG', p_name || ' = ' || p_value);
    END log_variable;

    --LOG ERROR
    PROCEDURE log_error(p_module IN VARCHAR2, p_err IN VARCHAR2, p_line NUMBER DEFAULT NULL) IS
    BEGIN
        insert_log(p_module, p_line, 'ERROR', p_err);
    END log_error;

END debug_utils;
/