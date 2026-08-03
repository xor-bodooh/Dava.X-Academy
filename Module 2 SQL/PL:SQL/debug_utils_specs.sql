CREATE OR REPLACE PACKAGE debug_utils AS
    -- Global flag for debug mode
    g_debug_mode BOOLEAN := FALSE;

    -- Enable/disable debug mode dynamically in the current session
    PROCEDURE enable_debug;
    PROCEDURE disable_debug;

    -- Core logging procedures
    PROCEDURE log_msg(p_module VARCHAR2, p_message VARCHAR2, p_level VARCHAR2 DEFAULT 'INFO', p_line NUMBER DEFAULT NULL);
    PROCEDURE log_variable(p_module VARCHAR2, p_name VARCHAR2, p_value VARCHAR2, p_line NUMBER DEFAULT NULL);
    PROCEDURE log_error(p_module VARCHAR2, p_err VARCHAR2, p_line NUMBER DEFAULT NULL);
END debug_utils;
/