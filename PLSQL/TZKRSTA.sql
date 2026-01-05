CREATE OR REPLACE PACKAGE TZKRSTA IS
    FUNCTION fn_insertar_tvrtsta(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        codigo IN VARCHAR2,
        valor IN VARCHAR2,
        secuencial IN OUT NUMBER)
        RETURN VARCHAR2;

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
    FUNCTION fn_determina_sigNumero_tipo_tran(
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
        WHERE REGEXP_LIKE (tvrtsta_tsta_code, 'T\d\d')
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
    END fn_determina_sigNumero_tipo_tran;

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
        codigo IN VARCHAR2,
        valor IN VARCHAR2,
        secuencial IN OUT NUMBER)
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

        secuencial := secuencial + 1;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_insertar_tvrtsta;

    /* El valor de tipo_transaccion tiene que ser 
    FA - Factura Anticipada
    FP - Factura Público en General
    FC - Factura al Cobro. Default
    */

    FUNCTION fn_registrar_tipo_factura(
        pidm in NUMBER,
        tran_number IN NUMBER,
        tipo_transaccion IN VARCHAR2,
        vln_secuencial IN OUT NUMBER
    ) RETURN VARCHAR2 IS
        vlc_respCall VARCHAR2(1000 CHAR);
        vlc_seqCodigo VARCHAR2(2 CHAR);
        codigo tvrtsta.TVRTSTA_TSTA_CODE%TYPE;
    BEGIN
        IF (tipo_transaccion NOT IN ('FA', 'FC', 'FP')) THEN
            RETURN 'Tipo de factura no válida';
        END IF;

        vlc_seqCodigo := fn_determina_sigNumero_tipo_tran(pidm, tran_number); 

        codigo := 'T'||vlc_seqCodigo;

        INSERT INTO TAISMGR.TVRTSTA (
            TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER, TVRTSTA_SEQ_NO, TVRTSTA_TSTA_CODE, TVRTSTA_DATE_TSTA, 
            TVRTSTA_DLOC_CODE, TVRTSTA_COMMENTS, 
            TVRTSTA_ACTIVITY_DATE, TVRTSTA_USER_ID, TVRTSTA_DATA_ORIGIN
        ) VALUES (
            pidm, tran_number, vln_secuencial, codigo, SYSDATE, 
            tipo_transaccion, tipo_transaccion, 
            SYSDATE, USER, 'Tralix'
        );

        vln_secuencial := vln_secuencial + 1;

        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_registrar_tipo_factura;

    FUNCTION fn_registrar_direccion_fiscal(
        pidm in NUMBER,
        tran_number IN NUMBER,
        numGrupo IN NUMBER,
        vln_secuencial IN OUT NUMBER
    ) RETURN VARCHAR2 IS
        vlc_comment tvrtsta.tvrtsta_comments%TYPE;
        vlc_respCall VARCHAR2(1000 CHAR);
    BEGIN
        FOR i IN (
            SELECT sp.*, st.stvstat_desc, sy.stvcnty_desc, sn.stvnatn_nation
            FROM spraddr sp
                LEFT JOIN stvstat st ON (sp.spraddr_stat_code = st.stvstat_code)
                LEFT JOIN stvcnty sy ON (sp.spraddr_cnty_code = sy.stvcnty_code)
                LEFT JOIN stvnatn sn ON (sp.spraddr_natn_code = sn.stvnatn_code)
            WHERE sp.spraddr_pidm = pidm
                AND spraddr_atyp_code = 'F' || numGrupo
            ORDER BY sp.spraddr_atyp_code DESC, sp.spraddr_activity_date DESC
        ) LOOP
            vlc_comment := i.spraddr_street_line1;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'CL1', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_street_line2;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'CL2', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_street_line3;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'CL3', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_city;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'CIT', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_stat_code;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'STA', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_zip;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'ZIP', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_cnty_code;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'CNT', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            vlc_comment := i.spraddr_natn_code;
            IF (NVL(vlc_comment, '|') != '|') THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    'NAT', 
                    vlc_comment,
                    vln_secuencial
                );    
            END IF;

            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;

            EXIT;
        END LOOP;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_registrar_direccion_fiscal;

    FUNCTION fn_registrar_datos_fiscales(
        pidm in NUMBER,
        tran_number IN NUMBER,
        cfdi IN VARCHAR2,
        vln_secuencial IN OUT NUMBER
    ) RETURN VARCHAR2 IS
        numGrupo NUMBER := 0;
        vlc_rfc  goradid.goradid_additional_id%TYPE;
        vlc_regFiscal goradid.goradid_additional_id%TYPE;
        vlc_respCall VARCHAR2(1000 CHAR);
        vln_regSocial NUMBER := 1;
        vlb_completo BOOLEAN := FALSE;
        vlc_razonSocial tvrtsta.tvrtsta_comments%TYPE;
        vln_numGoradid NUMBER := 0;
    BEGIN
        /* Determinar RFC */
        FOR j IN (
            SELECT *
            FROM goradid 
            WHERE goradid_pidm = pidm
                AND goradid_adid_code LIKE '%RFC'
                AND goradid_additional_id LIKE '*%'
        ) LOOP
            vlc_rfc := REPLACE(j.goradid_additional_id, '*', '');
            numGrupo := SUBSTR(j.goradid_adid_code, 1, 1);
            EXIT;
        END LOOP;

        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'FC'||numGrupo, 
            vlc_rfc,
            vln_secuencial
        );

        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        /* Buscando valores para regimenFiscal y usoCFDI */
        FOR r IN (
            SELECT goradid_additional_id
            FROM goradid
            WHERE goradid_pidm = pidm
                AND goradid_adid_code = numGrupo || 'RFI'
            ORDER BY goradid_adid_code DESC
        ) LOOP
            vlc_regFiscal := r.goradid_additional_id;
        END LOOP;

        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'RF'||numGrupo, 
            vlc_regFiscal,
            vln_secuencial
        );

        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        FOR s IN (
            SELECT goradid_additional_id
            FROM goradid
            WHERE goradid_pidm = pidm
                AND goradid_adid_code LIKE numGrupo || 'RS%'
            ORDER BY goradid_adid_code
        ) LOOP
            IF (vlb_completo) THEN
                vlc_respCall := fn_insertar_tvrtsta(
                    pidm, tran_number,
                    numGrupo||'R'||vln_regSocial, 
                    TRIM(vlc_razonSocial),
                    vln_secuencial
                );

                IF (vlc_respCall != 'OP_EXITOSA') THEN
                    RETURN vlc_respCall;
                END IF;

                vlc_razonSocial := '';
                vlb_completo := FALSE;
                vln_regSocial := vln_regSocial + 1;
            END IF;

            vlc_razonSocial := vlc_razonSocial || ' ' || s.goradid_additional_id;
            -- vln_regSocial := vln_regSocial + 1;
            vln_numGoradid := vln_numGoradid + 1;

            IF (vln_numGoradid > 0 AND (MOD(vln_numGoradid, 2) = 0)) THEN
                vlb_completo := TRUE;
            END IF;
        END LOOP;

        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            numGrupo||'R'||vln_regSocial, 
            TRIM(vlc_regFiscal),
            vln_secuencial
        );

        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'UF'||numGrupo, cfdi, 
            vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        vlc_respCall := fn_registrar_direccion_fiscal(
            pidm, tran_number, numGrupo, vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_registrar_datos_fiscales;

    FUNCTION fn_registrar(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        datos_factura IN TY_TRALIX_REGTSTA)
        RETURN VARCHAR2 IS

        vlc_respCall VARCHAR2(1000 CHAR);
        vln_secuencial NUMBER;
        vlc_seqCodigo VARCHAR2(2 CHAR);

        registros TY_TRALIX_TSTA_ARR;
        registro TY_TRALIX_TSTA_OBJ;
    BEGIN
        SELECT NVL(MAX(tvrtsta_seq_no), 0) + 1
        INTO vln_secuencial
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number;

        vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number);  
        -- vln_secuencial := vln_secuencial + 1;

        -- registros := TY_TRALIX_TSTA_ARR();

        -- registro := TY_TRALIX_TSTA_OBJ('F'||vlc_seqCodigo, '', datos_factura.factura);
        -- registros.EXTEND();
        -- registros(registros.COUNT) := registro;

        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'F'||vlc_seqCodigo, datos_factura.factura,
            vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'SOC', datos_factura.sociedad,
            vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;


        vlc_seqCodigo := SUBSTR(vlc_seqCodigo, 2, 1);

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'FV'||vlc_seqCodigo, TO_CHAR(datos_factura.fechaVenc, 'DD-MON-YYYY'), 
            vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'UI'||vlc_seqCodigo, datos_factura.uuid, 
            vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'FP'||vlc_seqCodigo, datos_factura.formaPago, 
            vln_secuencial
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            ROLLBACK;
            RETURN vlc_respCall;
        END IF;

        IF (TO_NUMBER(vlc_seqCodigo) > 5) THEN
            vlc_seqCodigo := '5';
        END IF;

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_registrar_datos_fiscales(
            pidm, tran_number, 
            datos_factura.usoCfdi, 
            vln_secuencial
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
        SELECT NVL(MAX(tvrtsta_seq_no), 0) + 1
        INTO vln_secuencial
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number
        ;

        vlc_seqCodigo := fn_determina_sigNumero_canc(pidm, tran_number);  

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm, tran_number,
            'CA'||vlc_seqCodigo, motivo_sust, 
            vln_secuencial
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

        SELECT NVL(MAX(tvrtsta_seq_no), 0) + 1
        INTO vln_secuencial
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm_canc
            AND tvrtsta_tran_number = tran_number_canc
        ;

        -- vln_secuencial := vln_secuencial + 1;
        vlc_respCall := fn_insertar_tvrtsta(
            pidm_canc, tran_number_canc,
            'RCL', motivo_sust, vln_secuencial
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
