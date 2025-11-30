CREATE OR REPLACE PACKAGE BANINST1.GOKJSON AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : GOKJSON
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Fri May 08 18:10:20 2020
-- MSGSIGN : #0000000000000000
--TMI18N.ETR DO NOT CHANGE--
    --
    -- FILE NAME..: gokjson.sql
    -- RELEASE....: 9.20
    -- OBJECT NAME: GOKJSON
    -- PRODUCT....: GENERAL
    -- USAGE......: Package to build JSON object for 9x Self-service
    -- COPYRIGHT..: Copyright 2020 Ellucian Company L.P. and its affiliates.
    --
    -- DESCRIPTION:
    --
    --  This package includes procedures and functions to build
    --  JSON object which can used to render 9x UI for Self-service application.
    --
    -- DESCRIPTION END
    --

    -- global variables
    gv_message_args_arr gokwtli.vc_arr;
    gv_empty_vc_arr gokwtli.vc_arr;

    TYPE json_arr_type IS table of varchar2(8000) INDEX BY BINARY_INTEGER;

    FUNCTION get_clob_output RETURN CLOB ;

    PROCEDURE initialize_clob_output;

    PROCEDURE free_output;

    PROCEDURE open_begin(key VARCHAR2, with_exception BOOLEAN DEFAULT FALSE);

    PROCEDURE open_object(key VARCHAR2 DEFAULT NULL, with_exception BOOLEAN DEFAULT FALSE);

    PROCEDURE open_array(key VARCHAR2);

    PROCEDURE write(key VARCHAR2, value VARCHAR2);

    PROCEDURE write(key VARCHAR2, value BOOLEAN);

    PROCEDURE write(key VARCHAR2, value DATE);

    PROCEDURE write(key VARCHAR2, value TIMESTAMP);

    PROCEDURE write(key VARCHAR2, value TIMESTAMP WITH TIME ZONE);

    PROCEDURE write(key VARCHAR2, value TIMESTAMP WITH LOCAL TIME ZONE);

    PROCEDURE close_array;

    PROCEDURE close_object;

    PROCEDURE close_for_return;

    PROCEDURE close_for_exception;

    PROCEDURE put_exception_info(p_errorCode number, p_errorMsg varchar2);

    PROCEDURE p_printmessage(message VARCHAR2,
                             message_type VARCHAR2 DEFAULT NULL,
                             message_key VARCHAR2 DEFAULT NULL,
                             message_args gokwtli.vc_arr DEFAULT gv_message_args_arr);

END GOKJSON;
/

CREATE OR REPLACE PACKAGE BODY BANINST1.GOKJSON AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : GOKJSO1
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Mon Sep 13 12:26:48 2021
-- MSGSIGN : #0000000000000000
--TMI18N.ETR DO NOT CHANGE--
    --
    -- FILE NAME..: gokjso1.sql
    -- RELEASE....: 9.25
    -- OBJECT NAME: GOKJSON
    -- PRODUCT....: GENERAL
    -- USAGE......: Package to build JSON object for 9x Self-service
    -- COPYRIGHT..: Copyright 2021 Ellucian Company L.P. and its affiliates.
    --
    -- DESCRIPTION:
    --
    --  This package includes procedures and functions to build
    --  JSON object which can used to render 9x UI for Self-service application.
    --
    -- DESCRIPTION END
    --

    TYPE t_varchar2 IS table of varchar2(5) INDEX BY BINARY_INTEGER;
    TYPE t_number IS table of number INDEX BY BINARY_INTEGER;
    TYPE t_boolean IS table of boolean INDEX BY BINARY_INTEGER;

    brackets_arr t_varchar2;
    json_arr json_arr_type;
    clob_out CLOB := empty_clob();
    open_begin_arr t_boolean;
    open_exception_arr t_boolean;
    is_next_comma boolean := FALSE;

    FUNCTION f_remove_spl_chars(p_string varchar2)
        RETURN varchar2 AS
        lv_hold_string varchar2(8000);
        lv_result      varchar2(8000);
    BEGIN
        lv_hold_string := p_string;
        lv_result := replace(lv_hold_string, '\', '\\');
        lv_result := replace(lv_result, '"', '\"');
        RETURN (lv_result);
    END f_remove_spl_chars;

    FUNCTION convert_date(p_date_str VARCHAR2) RETURN DATE IS
        lv_date date;
    BEGIN
        RETURN to_date(p_date_str, G$_DATE.GET_NLS_DATE_FORMAT || ' HH24:MI:SS');
    END convert_date;

    FUNCTION is_date(p_date_str VARCHAR2) RETURN BOOLEAN IS
        lv_date date;
    BEGIN
        lv_date := convert_date(p_date_str);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END is_date;

    FUNCTION get_greg_date(p_date date)
        RETURN varchar2 IS
        CURSOR c_date_format IS
            SELECT value
            FROM nls_session_parameters
            WHERE parameter = 'NLS_DATE_FORMAT';
        lv_date_format varchar2(15);
        lv_greg_date   varchar2(30);
    BEGIN
        OPEN c_date_format;
        FETCH c_date_format
            INTO lv_date_format;
        CLOSE c_date_format;
        lv_greg_date := to_char(p_date, 'rrrr-mm-dd hh24:mi:ss', 'nls_calendar=''gregorian''');
        RETURN lv_greg_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_greg_date;

    PROCEDURE writeInCLob(lob_loc  IN OUT NOCOPY  CLOB, offset IN OUT NOCOPY INTEGER, str IN CLOB) AS
        pos NUMBER;
        max_length NUMBER;
        readed NUMBER;
    BEGIN
        readed := 1;
        max_length := 2000;
        pos := DBMS_LOB.GETLENGTH(str);

        WHILE pos > 0
            LOOP
                if(max_length > pos) then
                    max_length := pos;
                end if;
                DBMS_LOB.WRITE(lob_loc, max_length, offset, DBMS_LOB.SUBSTR(str, max_length,readed));
                offset := offset + max_length;
                readed := readed + max_length;
                pos := pos - max_length;
            END LOOP;
    END;

    PROCEDURE AppendText(io_clob    IN OUT NOCOPY CLOB
    , io_buffer  IN OUT NOCOPY VARCHAR2
    , i_text     IN            VARCHAR2
    , offset IN OUT NOCOPY NUMBER) IS
    BEGIN
        io_buffer := io_buffer || i_text;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF io_clob IS NULL THEN
                io_clob := io_buffer;
            ELSE
                writeInCLob(io_clob, offset, io_buffer);
                io_buffer := i_text;
            END IF;
    END AppendText;

    FUNCTION get_clob_output
        RETURN CLOB AS
        m_buffer VARCHAR2(32767);
        offset NUMBER := 1;

    BEGIN

        dbms_lob.createtemporary(clob_out, TRUE, DBMS_LOB.CALL);
        dbms_lob.OPEN(clob_out, DBMS_LOB.LOB_READWRITE);
        IF json_arr.count > 0 THEN
            FOR i IN 1..json_arr.last
                LOOP
                    AppendText(clob_out, m_buffer,  json_arr(i), offset);
                    --   DBMS_LOB.writeappend(clob_out, length(json_arr(i)), json_arr(i));
                END LOOP;
            writeInCLob(clob_out, offset, m_buffer);
        END IF;
        RETURN (clob_out);
    END get_clob_output;

    PROCEDURE initialize_clob_output
    AS
    BEGIN
        json_arr.delete;
        brackets_arr.delete;
        open_begin_arr.delete;
        open_exception_arr.delete;
        is_next_comma := FALSE;
    END initialize_clob_output;

    PROCEDURE free_output
    AS
    BEGIN
        dbms_lob.CLOSE(clob_out);
        dbms_lob.freetemporary(clob_out);
        initialize_clob_output;
    END free_output;

    PROCEDURE p_check_next_comma AS
    BEGIN
        IF is_next_comma THEN
            json_arr(json_arr.count + 1) := ',';
        END IF;
    END p_check_next_comma;

    PROCEDURE open_begin(key VARCHAR2, with_exception BOOLEAN DEFAULT FALSE)
    AS
    BEGIN
        p_check_next_comma;
        json_arr(json_arr.count + 1) := '"' || key || '":{';
        brackets_arr(brackets_arr.count + 1) := '}';
        open_begin_arr(open_begin_arr.count + 1) := TRUE;
        is_next_comma := FALSE;

        IF with_exception THEN
            open_exception_arr(open_exception_arr.count + 1) := TRUE;
        ELSE
            open_exception_arr(open_exception_arr.count + 1) := FALSE;
        END IF;

    END open_begin;

    PROCEDURE open_object(key VARCHAR2 DEFAULT NULL, with_exception BOOLEAN DEFAULT FALSE)
    AS
    BEGIN
        p_check_next_comma;
        IF key IS NOT NULL THEN
            json_arr(json_arr.count + 1) := '"' || key || '":{';
        ELSE
            json_arr(json_arr.count + 1) := '{';
        END IF;
        brackets_arr(brackets_arr.count + 1) := '}';
        open_begin_arr(open_begin_arr.count + 1) := FALSE;
        is_next_comma := FALSE;

        IF with_exception THEN
            open_exception_arr(open_exception_arr.count + 1) := TRUE;
        ELSE
            open_exception_arr(open_exception_arr.count + 1) := FALSE;
        END IF;
    END open_object;

    PROCEDURE close_object AS
    BEGIN
        json_arr(json_arr.count + 1) := '}';
        brackets_arr.delete(brackets_arr.count);
        open_begin_arr.delete(open_begin_arr.count);
        open_exception_arr.delete(open_exception_arr.count);
        is_next_comma := TRUE;
    END close_object;

    PROCEDURE open_array(key VARCHAR2)
    AS
    BEGIN
        p_check_next_comma;
        json_arr(json_arr.count + 1) := '"' || key || '":[';
        brackets_arr(brackets_arr.count + 1) := ']';
        open_begin_arr(open_begin_arr.count + 1) := FALSE;
        open_exception_arr(open_exception_arr.count + 1) := FALSE;
        is_next_comma := FALSE;
    END open_array;

    PROCEDURE close_array AS
    BEGIN
        json_arr(json_arr.count + 1) := ']';
        brackets_arr.delete(brackets_arr.count);
        open_begin_arr.delete(open_begin_arr.count);
        open_exception_arr.delete(open_exception_arr.count);
        is_next_comma := TRUE;
    END close_array;

    PROCEDURE write_date(key VARCHAR2, value DATE)
    AS
    BEGIN
        IF value IS NOT NULL THEN
            -- Regular value
            p_check_next_comma;
            json_arr(json_arr.count + 1) := '"' || key || '": "' || value || '" ';
            is_next_comma := TRUE;
            -- Standardized value
            p_check_next_comma;
            json_arr(json_arr.count + 1) := '"' || trim(key) || '_GREGORIAN": "' || get_greg_date(value) || '" ';
            is_next_comma := TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END write_date;

    PROCEDURE write(key VARCHAR2, value VARCHAR2)
    AS
    BEGIN
        IF trim(value) IS NOT NULL THEN
            p_check_next_comma;
            json_arr(json_arr.count + 1) := '"' || key || '": "' || f_remove_spl_chars(value) || '" ';
            is_next_comma := TRUE;

            IF is_date(value) THEN
                p_check_next_comma;
                json_arr(json_arr.count + 1) :=
                            '"' || trim(key) || '_GREGORIAN": "' || get_greg_date(convert_date(value)) || '" ';
                is_next_comma := TRUE;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END write;

    PROCEDURE write(key VARCHAR2, value NUMBER)
    AS
    BEGIN
        IF trim(value) IS NOT NULL THEN
            p_check_next_comma;
            json_arr(json_arr.count + 1) := '"' || key || '": ' || value;
            is_next_comma := TRUE;
        END IF;
    END write;

    PROCEDURE write(key VARCHAR2, value BOOLEAN)
    AS
    BEGIN
        IF value IS NOT NULL THEN
            p_check_next_comma;
            IF value THEN
                json_arr(json_arr.count + 1) := '"' || key || '": true';
            ELSE
                json_arr(json_arr.count + 1) := '"' || key || '": false';
            END IF;
            is_next_comma := TRUE;
        END IF;
    END write;

    PROCEDURE write(key VARCHAR2, value DATE)
    AS
    BEGIN
        write_date(key, value);
    END write;

    PROCEDURE write(key VARCHAR2, value TIMESTAMP)
    AS
    BEGIN
        write_date(key, CAST(value AS DATE));
    END write;

    PROCEDURE write(key VARCHAR2, value TIMESTAMP WITH TIME ZONE)
    AS
    BEGIN
        write_date(key, CAST(value AS DATE));
    END write;

    PROCEDURE write(key VARCHAR2, value TIMESTAMP WITH LOCAL TIME ZONE)
    AS
    BEGIN
        write_date(key, CAST(value AS DATE));
    END write;

    PROCEDURE close_for_return AS
        lv_bracket varchar2(3);
        lv_begin   boolean;
    BEGIN
        IF open_begin_arr.count > 0 THEN
            WHILE TRUE
                LOOP
                    lv_bracket := brackets_arr(brackets_arr.count);
                    brackets_arr.delete(brackets_arr.count);
                    lv_begin := open_begin_arr(open_begin_arr.count);
                    open_begin_arr.delete(open_begin_arr.count);
                    open_exception_arr.delete(open_exception_arr.count);
                    json_arr(json_arr.count + 1) := lv_bracket;
                    IF lv_begin THEN
                        EXIT;
                    END IF;
                END LOOP;

            is_next_comma := TRUE;
        END IF;
    END close_for_return;

    PROCEDURE close_for_exception AS
        lv_bracket   varchar2(3);
        lv_exception boolean;
    BEGIN
        IF open_exception_arr.count > 0 THEN
            WHILE TRUE
                LOOP
                    lv_exception := open_exception_arr(open_exception_arr.count);
                    open_exception_arr.delete(open_exception_arr.count);
                    IF lv_exception THEN
                        open_exception_arr(open_exception_arr.count + 1) := lv_exception;
                        EXIT;
                    END IF;
                    lv_bracket := brackets_arr(brackets_arr.count);
                    brackets_arr.delete(brackets_arr.count);
                    open_begin_arr.delete(open_begin_arr.count);
                    json_arr(json_arr.count + 1) := lv_bracket;

                    is_next_comma := TRUE;
                END LOOP;
        END IF;
    END close_for_exception;

    PROCEDURE put_exception_info(p_errorCode number, p_errorMsg varchar2)
    AS
    BEGIN
        open_object('EXCEPTION_INFO');

        write('ERROR_CODE', p_errorCode);
        write('ERROR_MESSAGE', p_errorMsg);

        close_object;
    END;

    PROCEDURE p_printmessage(message VARCHAR2,
                             message_type VARCHAR2 DEFAULT NULL,
                             message_key VARCHAR2 DEFAULT NULL,
                             message_args gokwtli.vc_arr DEFAULT gv_message_args_arr) IS
        lv_msg_type varchar2(15) := message_type;
        error_table gokwtli.msgtab;
    BEGIN
        IF COALESCE(message_type, 'x') = '1' OR UPPER(COALESCE(message_type, 'x')) = 'ERROR' THEN
            lv_msg_type := 'ERROR';
        ELSIF COALESCE(message_type, 'x') = '2' OR UPPER(COALESCE(message_type, 'x')) = 'WARNING' THEN
            lv_msg_type := 'WARNING';
        ELSIF COALESCE(message_type, 'x') = '3' OR UPPER(COALESCE(message_type, 'x')) = 'NOTE' THEN
            lv_msg_type := 'NOTE';
        ELSIF COALESCE(message_type, 'x') = '4' OR UPPER(COALESCE(message_type, 'x')) = 'FIELD_ERROR' THEN
            lv_msg_type := 'FIELD_ERROR';
        ELSE
            lv_msg_type := '';
        END IF;

        IF INSTR(message, gokwtli.ERR_DELIMITER, 1) > 0 THEN
            error_table := gokwtli.f_err_msg_remove_delim_tbl(message);
        ELSE
            error_table(1) := message;
        END IF;

        write('message_type', lv_msg_type);
        open_array('messages');
        FOR error_index IN 1..error_table.COUNT
            LOOP
                open_object;
                write('message_seq', error_index);
                write('message', error_table(error_index));
                IF message_key IS NOT NULL THEN
                    write('message_key', message_key);
                END IF;
                IF message_args.COUNT >= 1 THEN
                    open_array('message_args');
                    FOR idx IN message_args.FIRST..message_args.LAST LOOP
                            open_object;
                            write('argument', message_args(idx));
                            close_object;
                        END LOOP;
                    close_array;
                    GOKJSON.gv_message_args_arr := GOKJSON.gv_empty_vc_arr;
                END IF;
                close_object;
            END LOOP;
        close_array;
    END p_printmessage;

END GOKJSON;
/