CREATE OR REPLACE PACKAGE TZKRSTA IS
    FUNCTION fn_registrar(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        datos_factura IN TY_TRALIX_REGTSTA)
        RETURN VARCHAR2;

    FUNCTION fn_cancelar_factura(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        motivo_sust IN VARCHAR2) 
        RETURN VARCHAR2;

    FUNCTION fn_sustituir_factura(
        pidm_canc IN NUMBER,
        tran_number_canc IN NUMBER,
        motivo_sust IN VARCHAR2) 
        RETURN VARCHAR2;    
END TZKRSTA;
/
show errors;

CREATE OR REPLACE PACKAGE BODY TZKRSTA IS
    FUNCTION fn_determina_sigNumero(
        pidm IN NUMBER,
        tran_number IN NUMBER)
        RETURN VARCHAR2 IS

        vln_respuesta NUMBER := 1;
        vlc_respuesta VARCHAR2(2 CHAR);
        vlc_tipoCodigo tvrtsta.tvrtsta_tsta_code%TYPE;
    BEGIN
        SELECT NVL(MAX(tvrtsta_tsta_code), '|')
        INTO vlc_tipoCodigo
        FROM tvrtsta
        WHERE REGEXP_LIKE (tvrtsta_tsta_code, 'F\d\d')
            AND tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number
        ;

        IF (vlc_tipoCodigo != '|') THEN
            vln_respuesta := TO_NUMBER(SUBSTR(vlc_tipoCodigo, 2, 2)) + 1;
        END IF;

        IF (vln_respuesta > 9) THEN
            vln_respuesta := 9;
        END IF;

        vlc_respuesta := TRIM(TO_CHAR(vln_respuesta, '00'));

        RETURN vlc_respuesta;
    END fn_determina_sigNumero;

    FUNCTION fn_insertar_tvrtsta(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        secuencial IN NUMBER,
        codigo IN VARCHAR2,
        valor IN VARCHAR2)
        RETURN VARCHAR2 IS
    BEGIN
        -- dbms_output.put_line('Insertar coidgo TSTA:' || codigo);
        INSERT INTO TAISMGR.TVRTSTA (
            TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER, TVRTSTA_SEQ_NO, TVRTSTA_TSTA_CODE, TVRTSTA_DATE_TSTA, 
            TVRTSTA_DLOC_CODE, TVRTSTA_COMMENTS, 
            TVRTSTA_ACTIVITY_DATE, TVRTSTA_USER_ID, TVRTSTA_DATA_ORIGIN
        ) VALUES (
            pidm, tran_number, secuencial, codigo, SYSDATE, 
            '', valor, 
            SYSDATE, USER, 'Tralix'
        );

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_insertar_tvrtsta;

    FUNCTION fn_registrar(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        datos_factura IN TY_TRALIX_REGTSTA)
        RETURN VARCHAR2 IS

        vlc_respCall VARCHAR2(1000 CHAR);
        vln_secuencial NUMBER;
        vlc_seqCodigo VARCHAR2(2 CHAR);
    BEGIN
        SELECT NVL(MAX(tvrtsta_seq_no), 0)
        INTO vln_secuencial
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number;

        vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number);  
        vln_secuencial := vln_secuencial + 1;

        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'F'||vlc_seqCodigo, datos_factura.factura
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'SOC', datos_factura.sociedad
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        -- IF (TO_NUMBER(vlc_seqCodigo) > 5) THEN
        --     vlc_seqCodigo := '5';
        -- END IF;

        -- vln_secuencial := vln_secuencial + 1;
        -- vlc_respCall := fn_insertar_tvrtsta(
        --     pidm, tran_number, vln_secuencial,
        --     'RF'||vlc_seqCodigo, datos_factura.regFiscal
        -- );
        -- IF (vlc_respCall != 'OP_EXITOSA') THEN
        --     ROLLBACK;
        --     RETURN vlc_respCall;
        -- END IF;

        vlc_seqCodigo := SUBSTR(vlc_seqCodigo, 2, 1);

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'FV'||vlc_seqCodigo, TO_CHAR(datos_factura.fechaVenc, 'DD-MON-YYYY')
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'UI'||vlc_seqCodigo, datos_factura.uuid
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'FP'||vlc_seqCodigo, datos_factura.formaPago
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        IF (TO_NUMBER(vlc_seqCodigo) > 5) THEN
            vlc_seqCodigo := '5';
        END IF;

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'UF'||vlc_seqCodigo, datos_factura.usoCfdi
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'RF'||vlc_seqCodigo, datos_factura.regFiscal
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        RETURN 'OP_EXITOSA';
    END fn_registrar;

    FUNCTION fn_determina_sigNumero_canc(
        pidm IN NUMBER,
        tran_number IN NUMBER)
        RETURN VARCHAR2 IS

        vln_respuesta NUMBER := 1;
        vlc_respuesta VARCHAR2(2 CHAR);
        vlc_tipoCodigo tvrtsta.tvrtsta_tsta_code%TYPE;
    BEGIN
        SELECT NVL(MAX(tvrtsta_tsta_code), '|')
        INTO vlc_tipoCodigo
        FROM tvrtsta
        WHERE REGEXP_LIKE (tvrtsta_tsta_code, 'CA\d')
            AND tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number
        ;

        IF (vlc_tipoCodigo != '|') THEN
            vln_respuesta := TO_NUMBER(SUBSTR(vlc_tipoCodigo, 3, 1)) + 1;
        END IF;

        vlc_respuesta := TRIM(TO_CHAR(vln_respuesta, '0'));

        RETURN vlc_respuesta;
    END fn_determina_sigNumero_canc;

    FUNCTION fn_cancelar_factura(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        motivo_sust IN VARCHAR2) 
        RETURN VARCHAR2 IS
        vln_secuencial NUMBER;
        vlc_seqCodigo VARCHAR2(1 CHAR);
        vlc_respCall VARCHAR2(1000 CHAR);
    BEGIN
        SELECT NVL(MAX(tvrtsta_seq_no), 0)
        INTO vln_secuencial
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number
        ;

        vlc_seqCodigo := fn_determina_sigNumero_canc(pidm, tran_number);  

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number, vln_secuencial,
            'CA'||vlc_seqCodigo, motivo_sust
        );
        
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;
        
        RETURN 'OP_EXITOSA';
    END fn_cancelar_factura;

    FUNCTION fn_sustituir_factura(
        pidm_canc IN NUMBER,
        tran_number_canc IN NUMBER,
        motivo_sust IN VARCHAR2) 
        RETURN VARCHAR2 IS
        vln_secuencial NUMBER;
        vlc_seqCodigo VARCHAR2(1 CHAR);
        vlc_respCall VARCHAR2(1000 CHAR);
    BEGIN
        -- vlc_respCall := fn_cancelar_factura(pidm_canc, tran_number_canc);
        -- IF (vlc_respCall != 'OP_EXITOSA') THEN
        --     ROLLBACK;
        --     RETURN vlc_respCall;
        -- END IF;

        SELECT NVL(MAX(tvrtsta_seq_no), 0)
        INTO vln_secuencial
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm_canc
            AND tvrtsta_tran_number = tran_number_canc
        ;

        vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm_canc, tran_number_canc, vln_secuencial,
            'RCL', motivo_sust
        );
        
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;
        
        RETURN 'OP_EXITOSA';
    END fn_sustituir_factura;
END TZKRSTA;
/
show errors;
