-- DROP PACKAGE TZTRALX;
-- /
-- show errors;

DROP SEQUENCE IPADEDEV.TEST_TRALIX_IP2_SEQ;

CREATE SEQUENCE IPADEDEV.TEST_TRALIX_IP2_SEQ START WITH 1400 INCREMENT BY 1 MINVALUE 0 NOCYCLE NOCACHE NOORDER; 

DROP SEQUENCE IPADEDEV.TEST_TRALIX_IP1_SEQ;

CREATE SEQUENCE IPADEDEV.TEST_TRALIX_IP1_SEQ START WITH 100 INCREMENT BY 1 MINVALUE 0 NOCYCLE NOCACHE NOORDER; 

CREATE OR REPLACE PACKAGE TZTRALX IS
    FUNCTION fn_obtener_idEmpresa(numEntidad IN VARCHAR2)
        RETURN VARCHAR2;

    /* TODO: Agregar parametro de si se ejecuta por primera vez, Boolean. */
    FUNCTION fn_factura_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_factura_tralix_json(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2,
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC')
        RETURN CLOB;

    FUNCTION fn_cancela_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        motivo_canc IN VARCHAR2)
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_sustitucion_tralix(
        matricula_orig IN VARCHAR2,
        tran_number_orig IN NUMBER,
        matricula_nuevo IN VARCHAR2,
        tran_number_nuevo IN NUMBER,
        motivo_canc IN VARCHAR2)
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    -- FUNCTION envio_tralix(
    --     l_function VARCHAR2,
    --     l_payload CLOB,
    --     estatus OUT BOOLEAN)
    --     RETURN CLOB;

    FUNCTION fn_factura_ant_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    separador constant varchar2(1) := '|';
END TZTRALX;
/
show errors;

CREATE OR REPLACE PACKAGE BODY TZTRALX IS
    -- Elementos del objeto raiz.
    FUNCTION fn_formateo_guid(guid IN VARCHAR2)
        RETURN VARCHAR2 IS
        vlc_guid VARCHAR2(50 CHAR);
    BEGIN
        vlc_guid := REGEXP_REPLACE ( guid
		       , '(........)(....)(....)(................)'
		       , '{\1-\2-\3-\4}');
		RETURN vlc_guid;
    END fn_formateo_guid;

    FUNCTION fn_obtener_idEmpresa(numEntidad IN VARCHAR2)
        RETURN VARCHAR2 IS
        vlc_idEmpresa VARCHAR2(50 CHAR);
    BEGIN
        FOR i IN (
            SELECT gtvsdax_comments
            FROM gtvsdax
            WHERE gtvsdax_external_code = 'TRALIX_FACT'
                AND gtvsdax_internal_code = 'TRALIX_EMP'
                AND GTVSDAX_INTERNAL_CODE_GROUP = 'IPADE' || numEntidad
        ) LOOP
            vlc_idEmpresa := i.gtvsdax_comments;
        END LOOP;

        RETURN vlc_idEmpresa;
    END fn_obtener_idEmpresa;

    FUNCTION fn_obtener_idTipoCfd(numEntidad IN VARCHAR2)
        RETURN VARCHAR2 IS
        vlc_idTipoCfd VARCHAR2(50 CHAR);
    BEGIN
        FOR i IN (
            SELECT gtvsdax_comments
            FROM gtvsdax
            WHERE gtvsdax_external_code = 'TRALIX_FACT'
                AND gtvsdax_internal_code = 'TRALIX_CFD'
                AND GTVSDAX_INTERNAL_CODE_GROUP = 'IPADE' || numEntidad
        ) LOOP
            vlc_idTipoCfd := i.gtvsdax_comments;
        END LOOP;

        RETURN vlc_idTipoCfd;
    END fn_obtener_idTipoCfd;

    FUNCTION fn_obtener_idSucursal(numEntidad IN VARCHAR2)
        RETURN VARCHAR2 IS
        vlc_idSucursal VARCHAR2(40 CHAR);
    BEGIN
        IF numEntidad = '1' THEN
            vlc_idSucursal := '40aec84a3811b3d1be3d2cd9763dcc9f';
        ELSIF numEntidad = '2' THEN
            vlc_idSucursal := '4f96a4aaa817086dace8f96c48b0c4b4';
        END IF;

        RETURN vlc_idSucursal;
    END fn_obtener_idSucursal;

    FUNCTION fn_generar_nombreArchivo(
        matricula IN VARCHAR2,
        tran_number IN NUMBER)
        RETURN VARCHAR2 IS
        vlc_nombreArchivo VARCHAR2(50 CHAR);
    BEGIN
        vlc_nombreArchivo := matricula || '_' || tran_number || '.txt';
        RETURN vlc_nombreArchivo;
    END fn_generar_nombreArchivo;

    FUNCTION crea_objeto_principal(
        matricula IN VARCHAR2,
        pidm IN NUMBER,
        tran_number IN NUMBER,
        datosFactura IN TY_TRALIX_FACTURA,
        numEntidad IN VARCHAR2) 
        RETURN CLOB IS
        vlc_nombreArchivo VARCHAR2(50 CHAR);

        vlc_campus VARCHAR2(6 CHAR);
        vlc_idSucursal VARCHAR2(60 CHAR);
        vlc_idUsoCfdi VARCHAR2(60 CHAR);
        vlc_respuesta CLOB;
    BEGIN
        gokjson.initialize_clob_output;
        gokjson.open_object(NULL);

        /* Buscar el valor de la sucursal por campus */
        -- FOR j IN (
        --     SELECT DISTINCT sx1.sorxref_desc as sucursal_guid,
        --         sx2.sorxref_desc as usocfdi_guid
        --     FROM sovlcur sv 
        --         JOIN sorxref sx1 ON (sx1.sorxref_edi_value = sv.sovlcur_camp_code)
        --         JOIN sorxref sx2 ON (sx1.sorxref_edi_value = sx2.sorxref_banner_value)
        --     WHERE sv.sovlcur_pidm = pidm
        --         AND sx1.sorxref_xlbl_code = 'SUC_TLIX'
        --         AND sx2.sorxref_xlbl_code = 'CFDI_TLX'
        -- ) LOOP
        --     vlc_idSucursal := j.sucursal_guid;
        --     vlc_idUsoCfdi := j.usocfdi_guid;
        -- END LOOP;

        vlc_idSucursal := fn_obtener_idSucursal(numEntidad);
        vlc_idUsoCfdi := fn_obtener_idTipoCfd(numEntidad);

        gokjson.write('idEmpresa', fn_obtener_idEmpresa(numEntidad));
        gokjson.write('idTipoCfd', vlc_idUsoCfdi);
        gokjson.write('idSucursal', vlc_idSucursal);
        vlc_nombreArchivo := fn_generar_nombreArchivo(matricula, tran_number);
        gokjson.write('nombre', vlc_nombreArchivo);
        gokjson.write('archivoFuente', datosFactura.imprimir_linea);
        gokjson.close_object;

        vlc_respuesta := gokjson.get_clob_output;
	    gokjson.free_output;
        RETURN vlc_respuesta;
    END crea_objeto_principal;

    FUNCTION envio_tralix(
        l_function VARCHAR2,
        l_payload CLOB,
        estatus OUT BOOLEAN)
        RETURN CLOB IS
        l_http_request  UTL_HTTP.req;
        l_http_response UTL_HTTP.resp;
        l_url           VARCHAR2(200); -- := 'https://mstest.ipade.mx/facturatralix/facturatralix';
        l_response      CLOB;
        detException    BOOLEAN := false;

        l_wallet_path VARCHAR2(200); -- := '/opt/oracle/dcs/commonstore/wallets/DBTEST_vtq_qro/cert';
        l_wallet_password VARCHAR2(200); -- := 'Ipade2025#$';

        l_indice NUMBER;
        l_ind_fin NUMBER;
        l_statusCodeTag VARCHAR2(20 CHAR) := '"statusCode":';
        l_bodyTag VARCHAR2(10 CHAR) := '"body":';

        lr_status VARCHAR2(5 CHAR);
        lr_body VARCHAR2(4000 CHAR);

        l_payload_def VARCHAR2(32767);
        l_payload_temp VARCHAR2(32767);
    BEGIN
        estatus := TRUE;

        -- Obtener valores para llamar a webservices
        FOR h IN (
            SELECT TO_CHAR(GTVSDAX_COMMENTS) as valor
            FROM general.gtvsdax
            WHERE gtvsdax_external_code = 'MICROSERV'
                AND gtvsdax_internal_code = 'INTG_IPADE'
                AND gtvsdax_internal_code_group = 'WALLET_L'
        ) LOOP
            l_wallet_path := h.valor;
        END LOOP;

        FOR j IN (
            SELECT TO_CHAR(GTVSDAX_COMMENTS) as valor
            FROM general.gtvsdax
            WHERE gtvsdax_external_code = 'MICROSERV'
                AND gtvsdax_internal_code = 'INTG_IPADE'
                AND gtvsdax_internal_code_group = 'WALLET_P'
        ) LOOP
            l_wallet_password := j.valor;
        END LOOP;

        FOR i IN (
            SELECT TO_CHAR(GTVSDAX_COMMENTS) as valor
            FROM general.gtvsdax
            WHERE gtvsdax_external_code = 'MICROSERV'
                AND gtvsdax_internal_code = 'INTG_IPADE'
                AND gtvsdax_internal_code_group = 'INTEGR_TX'
        ) LOOP
            l_url := i.valor;
        END LOOP;

        l_url := l_url || l_function;
        dbms_output.put_line('URL:'||l_url);
        UTL_HTTP.set_wallet('file:/'||l_wallet_path , l_wallet_password );
        UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(true);
        BEGIN
            l_http_request := UTL_HTTP.begin_request(
                url    => l_url,
                method => 'POST',
                http_version => 'HTTP/1.1'
            );

            l_payload_temp := DBMS_LOB.SUBSTR(l_payload);

            -- l_payload_def := REPLACE(l_payload_temp, '\\', '\');
            l_payload_def := CONVERT(REPLACE(l_payload_temp, '\\', '\'), 'AL32UTF8', 'WE8ISO8859P1');
            -- l_payload_def := CONVERT(dbms_lob.substr(l_payload_def, dbms_lob.getlength(l_payload_def)),
            --      'AL32UTF8', NLS_CHARSET_NAME(NLS_CHARSET_ID('AL32UTF8')));
            -- dbms_output.put_line(l_payload_def);

            -- l_payload_def := 
            --     utl_i18n.raw_to_char(
            --         hextoraw(
            --             utl_i18n.string_to_raw(l_payload_def, 'utf8')
            --         ), 'utf8'
            --     )
            -- ;

            -- Add headers
            -- UTL_HTTP.SET_BODY_CHARSET('UTF-8');
            UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json;charset=UTF-8'); 
            UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_payload_def));

            -- Write the payload
            UTL_HTTP.write_text(l_http_request, l_payload_def);
            -- UTL_HTTP.WRITE_RAW(r => l_http_request, data => utl_i18n.string_to_raw(l_payload_def, 'utf8'));

            -- Send the request and get the response 
            l_http_response := UTL_HTTP.get_response(l_http_request);

            -- Read the response 
            BEGIN 
                LOOP 
                    UTL_HTTP.read_text(l_http_response, l_response); 
                END LOOP; 
            EXCEPTION 
                WHEN UTL_HTTP.end_of_body THEN 
                    NULL;
                when utl_http.request_failed then
			        NULL;
            END;

            -- Close the response
            UTL_HTTP.end_response(l_http_response);
        EXCEPTION
            WHEN OTHERS THEN
                UTL_HTTP.GET_DETAILED_EXCP_SUPPORT(detException);
                IF (detException) THEN
                    l_response := l_response || ' - ' || utl_http.get_detailed_sqlerrm;
                ELSE
                    l_response := l_response || ' - ' || sqlerrm;
                END IF;
                estatus := FALSE;
        END;
        UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(false);

        IF NOT(estatus) THEN
            RETURN l_response;
        END IF;

        dbms_output.put_line('Resp RAW:' || l_response);

        -- Determinar status de la respuesta
        l_indice := INSTR(l_response, l_statusCodeTag);
        l_ind_fin := INSTR(l_response, ',', l_indice);

        l_indice := l_indice + LENGTH(l_statusCodeTag);

        lr_status := SUBSTR(l_response, l_indice, l_ind_fin - l_indice);

        -- Determinar body
        l_indice := INSTR(l_response, l_bodyTag);
	    l_ind_fin := INSTR(l_response, '}', l_indice);

        IF (l_function LIKE '%cancela%') THEN
            l_indice := l_indice + LENGTH(l_bodyTag) + 1;
            l_response := SUBSTR(l_response, l_indice, l_ind_fin - l_indice - 1);
        ELSE
            l_indice := l_indice + LENGTH(l_bodyTag) + 1;
            l_response := SUBSTR(l_response, l_indice + 1, l_ind_fin - l_indice);
        END IF;

        IF (lr_status != '200') THEN
            estatus := FALSE;
        END IF;

        RETURN l_response;
    END envio_tralix;

    FUNCTION envio_factura_tralix(
        l_payload CLOB,
        estatus OUT BOOLEAN)
        RETURN CLOB IS
        l_response      CLOB;
        
    BEGIN
        l_response := envio_tralix('/facturatralix/facturatralix', l_payload, estatus);
        
        RETURN l_response;
    END envio_factura_tralix;

    FUNCTION fn_limpia_string_error(
        mensaje IN CLOB
    ) RETURN CLOB IS
        buffer CLOB;
    BEGIN
        buffer := REPLACE(mensaje, '\\n', '.');
        buffer := REPLACE(buffer, '\u', '\');
        buffer := UNISTR(buffer);
        
        RETURN buffer;
    END fn_limpia_string_error;

    PROCEDURE pr_log_error(vln_pidm IN NUMBER,
        vln_numFactura IN VARCHAR2,
        bufferMensaje IN CLOB,
        vln_monto IN NUMBER,
        tipo_pago_banner IN VARCHAR2,
        tran_number IN NUMBER) IS

        mensaje_desc TVRPAYS.TVRPAYS_RETURN_CODE_DESC%TYPE;
    BEGIN
        IF (LENGTH(bufferMensaje) >= 1000) THEN
            mensaje_desc := SUBSTR(bufferMensaje, 1, 1000);
        ELSE
            mensaje_desc := bufferMensaje;
        END IF;

        MERGE INTO TAISMGR.TVRPAYS tgt
            USING (
                SELECT vln_pidm as TVRPAYS_PIDM,
                    NVL(vln_numFactura, 'NO_TRAN') as TVRPAYS_BANK_TRAN_ID,
                    mensaje_desc as TVRPAYS_RETURN_CODE_DESC,
                    NVL(vln_monto, 0) as TVRPAYS_AMOUNT,
                    tipo_pago_banner as TVRPAYS_SRV_CODE,
                    TO_CHAR(tran_number) AS TVRPAYS_RETURN_CODE
                FROM dual
            ) src
                ON (tgt.TVRPAYS_PIDM=src.TVRPAYS_PIDM 
                    AND tgt.TVRPAYS_BANK_TRAN_ID=src.TVRPAYS_BANK_TRAN_ID)
            WHEN MATCHED
                THEN UPDATE SET
                    tgt.TVRPAYS_STATUS='T', 
                    tgt.TVRPAYS_ACTIVITY_DATE=SYSDATE, 
                    tgt.TVRPAYS_DATA_ORIGIN='Tralix',
                    tgt.TVRPAYS_RETURN_CODE_DESC=src.TVRPAYS_RETURN_CODE_DESC,
                    tgt.TVRPAYS_SEQNO=tgt.TVRPAYS_SEQNO + 1,
                    tgt.TVRPAYS_SRV_CODE=src.TVRPAYS_SRV_CODE,
                    tgt.TVRPAYS_RETURN_CODE=src.TVRPAYS_RETURN_CODE
            WHEN NOT MATCHED
                THEN INSERT (TVRPAYS_PIDM, 
                    TVRPAYS_AMOUNT, 
                    TVRPAYS_BANK_TRAN_ID, 
                    TVRPAYS_TRAN_DATE, 
                    TVRPAYS_STATUS, 
                    TVRPAYS_USER_ID, 
                    TVRPAYS_ACTIVITY_DATE, 
                    TVRPAYS_DATA_ORIGIN, 
                    TVRPAYS_CREATE_DATE, 
                    TVRPAYS_CREATE_USER, 
                    TVRPAYS_RETURN_CODE,
                    TVRPAYS_RETURN_CODE_DESC,
                    TVRPAYS_SEQNO,
                    TVRPAYS_SRV_CODE)
                VALUES (src.TVRPAYS_PIDM, 
                    src.TVRPAYS_AMOUNT, 
                    src.TVRPAYS_BANK_TRAN_ID, 
                    SYSDATE, 
                    'T', 
                    USER, 
                    SYSDATE, 
                    'Tralix', 
                    SYSDATE, 
                    USER, 
                    src.TVRPAYS_RETURN_CODE,
                    src.TVRPAYS_RETURN_CODE_DESC, 
                    1,
                    src.TVRPAYS_SRV_CODE)
                ;
    END;

    FUNCTION fn_reenviar(bufferMensaje CLOB)
        RETURN BOOLEAN IS

        vlb_respuesta BOOLEAN := FALSE;
    BEGIN
        IF ((INSTR(bufferMensaje, 'La clave del campo RegimenFiscalR no corresponde de acuerdo al RFC del receptor') > 0) OR
            (INSTR(bufferMensaje, 'La clave del campo RegimenFiscalR debe corresponder con el tipo de persona (física o moral)') > 0)) THEN
            vlb_respuesta := TRUE;
        END IF;

        RETURN vlb_respuesta;
    END fn_reenviar;

    FUNCTION fn_factura_base_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE', 
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        proceso_factura IN VARCHAR2 DEFAULT 'DEF')   -- DEF = Default, ANT = Anticipada, CP = Complemento de Pago
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlc_respuesta CLOB;
        ipade_pidm NUMBER;
        datosFactura  TY_TRALIX_FACTURA;
        vlc_estatus VARCHAR2(50 CHAR);
        vlc_errores VARCHAR2(1000 CHAR);

        vlc_prefijo VARCHAR2(20 CHAR);
        vln_numFactura NUMBER;

        vlc_camp_code  SATURN.STVCAMP.STVCAMP_CODE%TYPE;
        vlc_num_entidad  VARCHAR2(1 CHAR);
        vlc_num_tipoDir VARCHAR2(1 CHAR);
        vlc_objeto_principal CLOB;
        vln_pidm SATURN.SPRIDEN.SPRIDEN_PIDM%TYPE;

        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
        vlc_envioTralix CLOB;
        vlb_estatusEnvio BOOLEAN;

        vln_monto NUMBER;
        bufferMensaje CLOB;

        uuidTralix VARCHAR2(40 CHAR);
        campoUUID VARCHAR2(100 CHAR) := '"uuid":';
        l_indice NUMBER := 0;
        l_ind_fin NUMBER := 0;

        vlc_llamada VARCHAR2(4000 CHAR);
        registro_tsta TY_TRALIX_REGTSTA;

        pubgral BOOLEAN := FALSE;

        vlc_tipo_pago_banner VARCHAR2(10 CHAR);
    BEGIN
        BEGIN
            vln_pidm := gb_common.f_get_pidm(matricula);
        EXCEPTION
            WHEN OTHERS THEN
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := datosFactura.errores('No existe la matrícula');
                RETURN vlt_respuesta;
        END;

        vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
        vlt_respuesta.validar_datos;

        IF (vlt_respuesta.estatus != 'OK') THEN
            -- vlc_respuesta := vlt_respuesta.imprimir_json();
            pr_log_error(vln_pidm, '', vlt_respuesta.imprimir_json(),
                vln_monto, tipo_pago_banner, tran_number);
            RETURN vlt_respuesta;
        END IF;

        IF (matricula LIKE 'PUBGRAL%') THEN
            vlc_num_entidad := SUBSTR(matricula, 8, 1);
            vlc_num_tipoDir := 1;
            pubgral := TRUE;
        ELSIF (matricula NOT LIKE 'NOIDEN%') THEN
            FOR n IN (
                SELECT c.stvcamp_dicd_code,
                    substr(x1.sorxref_edi_qlfr, 3, 1) as empresa
                FROM sovlcur vr 
                    JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
                    JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
                    LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
                WHERE sp.spriden_id = matricula
                    AND sp.spriden_change_ind IS NULL
                    AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
                    and x1.sorxref_xlbl_code = 'IPADEEM'
                    AND vr.sovlcur_seqno < 4   -- Temporal
            ) LOOP 
                vlc_camp_code := n.stvcamp_dicd_code;
                vlc_num_tipoDir := SUBSTR(vlc_camp_code, LENGTH(vlc_camp_code), 1);
                vlc_num_entidad := n.empresa;
            END LOOP;
        ELSE
            vlc_num_entidad := SUBSTR(matricula, 7, 1);
            vlc_num_tipoDir := 1;
        END IF;

        -- dbms_output.put_line('camp_code:'||vlc_camp_code);
        -- dbms_output.put_line('num_tipoDir:'||vlc_num_tipoDir);
        dbms_output.put_line('num_entidad:'||vlc_num_entidad);

        IF (NVL(vlc_num_entidad, '|') = '|') THEN
            -- pr_log_error(vln_pidm, '', 'La carrera del alumno no está registrada con etiqueta IPADEEM en SOAXREF',
            --     vln_monto, tipo_pago_banner, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.errores.EXTEND;
            vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('La carrera del alumno no está registrada con etiqueta IPADEEM en SOAXREF');
            RETURN vlt_respuesta;
        END IF;

        vlc_tipo_pago_banner := tipo_pago_banner;
        IF (tipo_pago_facturar = 'PPD') THEN
            vlc_tipo_pago_banner := '99';
        END IF;

        datosFactura := ty_tralix_factura(matricula, tran_number, vlc_num_entidad, 
            1, vlc_tipo_pago_banner, tipo_pago_facturar, proceso_factura);       

        datosFactura.validar;
        IF (datosFactura.errores.COUNT > 0) THEN
            vlt_respuesta.estatus := 'ERROR';
            FOR m IN datosFactura.errores.FIRST .. datosFactura.errores.LAST
            LOOP
                vlt_respuesta.errores.EXTEND;
                -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(datosFactura.errores(m).mensaje);
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := datosFactura.errores(m);
            END LOOP;
            -- vlc_respuesta := vlt_respuesta.imprimir_json();
            pr_log_error(vln_pidm, '', vlt_respuesta.imprimir_json(),
                vln_monto, tipo_pago_banner, tran_number);
            RETURN vlt_respuesta;
        END IF;
        
        /* Obtener número de factura */
        vlc_prefijo := 'ZPB';
        IF (vlc_num_entidad = 1) THEN
            vlc_prefijo := 'PBA';
        END IF;

        IF (matricula NOT LIKE 'NOIDEN%') THEN
            FOR i in (
                SELECT x1.sorxref_banner_value as programa, 
                    substr(x1.sorxref_edi_qlfr, 1, 3) as empresa,
                    NVL(x2.sorxref_edi_qlfr, vlc_prefijo) as prefijo
                FROM sovlcur cur
                    JOIN sorxref x1 ON (cur.sovlcur_program = x1.sorxref_banner_value)
                    LEFT JOIN (
                        SELECT * 
                        FROM sorxref
                        WHERE sorxref_xlbl_code = 'FOLIOFAC') x2 ON (cur.sovlcur_program = x2.sorxref_edi_qlfr)
                WHERE cur.sovlcur_pidm = vln_pidm
                    and cur.sovlcur_lmod_code = sb_curriculum_str.f_learner
                    and x1.sorxref_xlbl_code = 'IPADEEM'
                    and cur.sovlcur_active_ind = 'Y'
            )
            LOOP
                vlc_prefijo := i.prefijo;
            END LOOP;
        END IF;

        FOR j IN (
            SELECT TVRSDSQ_MAX_SEQ + 1 as secuencial
            FROM TVRSDSQ t
            WHERE TVRSDSQ_SDOC_CODE = vlc_prefijo
            FOR UPDATE
        )
        LOOP
            vln_numFactura := j.secuencial;
        END LOOP;

        -- TEMPORAL
        IF (vlc_prefijo IN ('ZPB', 'PBA')) THEN
            IF (vlc_num_entidad = 1) THEN
                vln_numFactura := test_tralix_ip1_seq.nextval;
            ELSE
                vln_numFactura := test_tralix_ip2_seq.nextval;
            END IF;
        END IF;
        -- TEMPORAL

        datosFactura.info_gral_comprobante.set_folio(vlc_prefijo, TO_CHAR(vln_numFactura));
        IF pubgral THEN
            datosFactura.receptor.datos_pubgral;
        END IF;
        datosFactura.ajustar_pubgral;
        vlc_objeto_principal := crea_objeto_principal(matricula, vln_pidm, tran_number, 
            datosFactura, vlc_num_entidad);
        vlt_respuesta.mainData := vlc_objeto_principal;

        dbms_output.put_line('payload:' || vlc_objeto_principal);

        vlc_envioTralix := envio_factura_tralix(vlc_objeto_principal, vlb_estatusEnvio);

        vln_monto := 0;

        bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

        dbms_output.put_line('bufferMensaje1:' || bufferMensaje);

        IF (NOT(vlb_estatusEnvio)) THEN
            ROLLBACK;

            /* TODO: Si aqui hay un error de  "La clave del campo RegimenFiscalR no corresponde de acuerdo al RFC del receptor" 
            y es primera vez volver a enviar pero indicando que es segunda vez y como si fuera a PubGral. */

            dbms_output.put_line('CON ERROR: ' || bufferMensaje);

            IF (NOT(pubgral) AND fn_reenviar(bufferMensaje)) THEN
                datosFactura.receptor.datos_pubgral;
                datosFactura.ajustar_pubgral;
                vlc_objeto_principal := crea_objeto_principal(matricula, vln_pidm, tran_number, 
                    datosFactura, vlc_num_entidad);
                vlt_respuesta.mainData := vlc_objeto_principal;

                dbms_output.put_line('payload 2nd:' || vlc_objeto_principal);

                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('Situación con Régimen Fiscal. Se envía a PUBLICO EN GENERAL.');

                vlc_envioTralix := envio_factura_tralix(vlc_objeto_principal, vlb_estatusEnvio);

                vln_monto := 0;

                bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

                dbms_output.put_line('bufferMensaje 2nd:' || bufferMensaje);
            END IF;

            IF (NOT(vlb_estatusEnvio)) THEN
                ROLLBACK;
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(bufferMensaje);

                FOR j IN datosFactura.conceptos.FIRST .. datosFactura.conceptos.LAST
                LOOP
                    vln_monto := vln_monto + datosFactura.conceptos(j).importe;
                END LOOP;

                /* Guardar en TZRPAYS, con status = 'T' */
                BEGIN
                    pr_log_error(vln_pidm, vln_numFactura, bufferMensaje,
                        vln_monto, tipo_pago_banner, tran_number);

                EXCEPTION
                    WHEN OTHERS THEN
                        rollback;
                        vlt_respuesta.estatus := 'ERROR';
                        vlt_respuesta.errores.EXTEND;
                        vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(sqlerrm);
                        RETURN vlt_respuesta;
                END;
            END IF;

            COMMIT;
        END IF;

        /* No se pone en un ELSE porque puede cambiar en el 2do. intento */
        IF (vlb_estatusEnvio) THEN
            -- Actualizar secuencial
            UPDATE tvrsdsq
            SET TVRSDSQ_MAX_SEQ = vln_numFactura
            WHERE TVRSDSQ_SDOC_CODE = vlc_prefijo; 
            
            COMMIT;

            l_indice := INSTR(bufferMensaje, campoUUID);
            l_ind_fin := INSTR(bufferMensaje, ',', l_indice);

            uuidTralix := SUBSTR(bufferMensaje, l_indice + LENGTH(campoUUID) + 1, l_ind_fin - (l_indice + LENGTH(campoUUID) + 2));

            dbms_output.put_line('UUID_Value:'||uuidTralix);

            BEGIN
                INSERT INTO TAISMGR.TZRPOFI (
                    TZRPOFI_PIDM, TZRPOFI_SDOC_CODE, TZRPOFI_DOC_NUMBER, TZRPOFI_DOC_STATUS, TZRPOFI_TERM_CODE, 
                    TZRPOFI_DCAT_CODE, TZRPOFI_IAC_CDE, TZRPOFI_INCL_BARCODE_IND, TZRPOFI_INCL_PI_IND, 
                    TZRPOFI_PI_IND, TZRPOFI_INCL_DOCNUM_IND, TZRPOFI_DOCNUM_POS, TZRPOFI_EXP_PDF_LBL_1,
                    TZRPOFI_INCL_SCHG_LABEL, TZRPOFI_DATE_CHG_1, TZRPOFI_DETC_CODE_CHG_1, 
                    TZRPOFI_DATA_ORIGIN, TZRPOFI_CREATE_USER_ID, TZRPOFI_CREATE_DATE, 
                    TZRPOFI_USER_ID, TZRPOFI_ACTIVITY_DATE
                ) VALUES (
                    vln_pidm, vlc_prefijo, TO_CHAR(vln_numFactura), 'A', tipo_pago_banner, 
                    'CSH', uuidTralix, 'N', 'N', 
                    'N', 'N', tran_number, fn_obtener_idEmpresa(vlc_num_entidad),
                    'N', SYSDATE, 'X', 
                    'Tralix', USER, SYSDATE, 
                    USER, SYSDATE
                );

                -- Insertar en TZRTSTA
                registro_tsta := TY_TRALIX_REGTSTA(
                    vlc_prefijo||'-'||vln_numFactura,
                    'IPADE'||vlc_num_entidad, 
                    datosFactura.receptor.rfc, 
                    uuidTralix, 
                    datosFactura.info_gral_comprobante.fecha,
                    datosFactura.receptor.usoCFDI,
                    tipo_pago_facturar);

                -- dbms_output.put_line('Registrar en TSTA');

                vlc_llamada := tzkrsta.fn_registrar(vln_pidm, tran_number, registro_tsta);

                IF (vlc_llamada != 'OP_EXITOSA') THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.errores.EXTEND;
                    vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(vlc_llamada);
                    RETURN vlt_respuesta;
                END IF;
                COMMIT;

            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.errores.EXTEND;
                    vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(sqlerrm);
                    RETURN vlt_respuesta;
            END;

            COMMIT;
        END IF;

        RETURN vlt_respuesta;
    END fn_factura_base_tralix;

    FUNCTION fn_factura_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE', 
        etiqueta IN VARCHAR2 DEFAULT 'FAC')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
    BEGIN
        RETURN fn_factura_base_tralix(matricula, tran_number, tipo_pago_banner,
            tipo_pago_facturar, etiqueta, 'DEF');
    END fn_factura_tralix;

    FUNCTION fn_factura_tralix_json(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2,
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE', 
        etiqueta IN VARCHAR2 DEFAULT 'FAC')
        RETURN CLOB IS
        vlc_respuesta CLOB;
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
    BEGIN
        vlt_respuesta := fn_factura_tralix(matricula, tran_number,
            tipo_pago_banner, tipo_pago_facturar, etiqueta);
        
        vlc_respuesta := vlt_respuesta.imprimir_json();
        RETURN vlc_respuesta;
    END fn_factura_tralix_json;

    FUNCTION crea_objeto_sust_tralix(
        folio_canc IN VARCHAR2,
        folio_sust IN VARCHAR2 DEFAULT NULL,
        motivo_sust IN VARCHAR2,
        idEmpresa IN VARCHAR2) 
        RETURN CLOB IS
        vlc_respuesta CLOB;
    BEGIN
        gokjson.initialize_clob_output;
        gokjson.open_object(NULL);
        gokjson.write('idEmpresa', idEmpresa);
        gokjson.write('motivo', motivo_sust);
        IF ((motivo_sust = '01') AND (NVL(folio_sust, '|') != '|')) THEN
            gokjson.write('folioSustitucion', folio_sust);
        END IF;

        gokjson.open_array('uuid');
        gokjson.write('X2', folio_canc);
        gokjson.close_array;

        gokjson.close_object;

        vlc_respuesta := gokjson.get_clob_output;
	    gokjson.free_output;

        vlc_respuesta := REPLACE(vlc_respuesta, '"X2":', '');

        RETURN vlc_respuesta;
    END crea_objeto_sust_tralix;

    FUNCTION envio_canc_tralix(
        l_payload IN CLOB,
        l_operacion IN VARCHAR2,
        estatus OUT BOOLEAN)
        RETURN CLOB IS
        l_response      CLOB;

    BEGIN
        -- dbms_output.put_line('Payload:'||l_payload);
        l_response := envio_tralix('/facturatralix/cancelaCFDI', l_payload, estatus);
        
        -- TEMPORAL forzar para demo INICIO
        IF (l_operacion = 'CANC') THEN
            
            l_response := '{"statusCode":200,"headers":{"Content-Type":"application/json"},"body":"Error en el servicio de cancelaci\u00F3n"}';
            estatus := TRUE;
        END IF;
        -- TEMPORAL forzar para demo FIN
        
        RETURN l_response;
    END envio_canc_tralix;

    FUNCTION fn_cancela_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        motivo_canc IN VARCHAR2)
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlc_respuesta CLOB;
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
        vln_pidm NUMBER;
        vlc_num_entidad  VARCHAR2(1 CHAR);
        vlc_objeto_principal CLOB;
        vlc_envioTralix CLOB;
        bufferMensaje CLOB;

        vlc_guid_cancelar VARCHAR2(40 CHAR);
        vlb_estatusEnvio BOOLEAN;
        vlc_llamada VARCHAR2(4000 CHAR);
        vlc_numFactura VARCHAR2(100 CHAR);
        vlc_empresa VARCHAR2(100 CHAR);
        vlc_full_motivo_canc VARCHAR2(1000 CHAR);
    BEGIN
        vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
        IF (vlt_respuesta.estatus != 'OK') THEN
            -- vlc_respuesta := vlt_respuesta.imprimir_json();
            RETURN vlt_respuesta;
        END IF;

        BEGIN
            vln_pidm := gb_common.f_get_pidm(matricula);
        EXCEPTION
            WHEN OTHERS THEN
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la matrícula');
                RETURN vlt_respuesta;
        END;

        FOR n IN (
            SELECT c.stvcamp_dicd_code,
                substr(x1.sorxref_edi_qlfr, 3, 1) as empresa
            FROM sovlcur vr 
                JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
                JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
                LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
            WHERE sp.spriden_id = matricula
                AND sp.spriden_change_ind IS NULL
                AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
                and x1.sorxref_xlbl_code = 'IPADEEM'
                AND vr.sovlcur_seqno < 4   -- Temporal
        ) LOOP 
            vlc_num_entidad := n.empresa;
        END LOOP;

        FOR i IN (
            SELECT TZRPOFI_IAC_CDE, TZRPOFI_DOC_NUMBER, TZRPOFI_EXP_PDF_LBL_1
            FROM tzrpofi
            WHERE tzrpofi_pidm = vln_pidm
                AND TZRPOFI_DOCNUM_POS = tran_number
        ) LOOP
            vlc_guid_cancelar := i.TZRPOFI_IAC_CDE;
            vlc_numFactura := i.TZRPOFI_DOC_NUMBER;
            vlc_empresa := i.TZRPOFI_EXP_PDF_LBL_1; 
        END LOOP;

        IF (NVL(vlc_guid_cancelar, '|') = '|') THEN
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.errores.EXTEND;
            vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la factura a cancelar');
            RETURN vlt_respuesta;
        END IF;

        vlc_objeto_principal := crea_objeto_sust_tralix(vlc_guid_cancelar, '', motivo_canc, vlc_empresa);
        vlt_respuesta.mainData := vlc_objeto_principal;
        vlc_envioTralix := envio_canc_tralix(vlc_objeto_principal, 'CANC', vlb_estatusEnvio);
        bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

        IF (vlb_estatusEnvio) THEN
            vlc_full_motivo_canc := motivo_canc;
            IF (motivo_canc = '02') THEN
                vlc_full_motivo_canc := vlc_full_motivo_canc || '- Comprobante emitido con errores sin relación.';
            ELSIF (motivo_canc = '03') THEN
                vlc_full_motivo_canc := vlc_full_motivo_canc || '- No se llevó a cabo la operación.';
            ELSIF (motivo_canc = '04') THEN
                vlc_full_motivo_canc := vlc_full_motivo_canc || '- Operación nominativa relacionada en una factura global.';
            END IF;
            vlc_llamada := tzkrsta.fn_cancelar_factura(vln_pidm, tran_number, vlc_full_motivo_canc);

            IF (vlc_llamada != 'OP_EXITOSA') THEN
                rollback;
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(vlc_llamada);
                RETURN vlt_respuesta;
            END IF;
            COMMIT;
        ELSE
            /* Guardar en TZRPAYS, con status = 'T' */
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.errores.EXTEND;
            vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(bufferMensaje);
            BEGIN
                pr_log_error(vln_pidm, vlc_numFactura, bufferMensaje,
                    0, motivo_canc, tran_number);
            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.errores.EXTEND;
                    vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(sqlerrm);
                    RETURN vlt_respuesta;
            END;
        END IF;

        RETURN vlt_respuesta;
    END fn_cancela_tralix;

    FUNCTION fn_sustitucion_tralix(
        matricula_orig IN VARCHAR2,
        tran_number_orig IN NUMBER,
        matricula_nuevo IN VARCHAR2,
        tran_number_nuevo IN NUMBER,
        motivo_canc IN VARCHAR2)
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlc_respuesta CLOB;
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
        vln_pidm_orig NUMBER;
        vln_pidm_nuevo NUMBER;
        vlc_num_entidad  VARCHAR2(1 CHAR);
        vlc_objeto_principal CLOB;
        vlc_envioTralix CLOB;
        bufferMensaje CLOB;

        vlc_guid_cancelar VARCHAR2(40 CHAR);
        vlc_guid_sustituir VARCHAR2(40 CHAR);
        vlb_estatusEnvio BOOLEAN;
        vlc_llamada VARCHAR2(4000 CHAR);

        vlc_numFactura VARCHAR2(100 CHAR);
        vlc_empresa VARCHAR2(100 CHAR);
    BEGIN
        vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula_nuevo, tran_number_nuevo);

        IF (vlt_respuesta.estatus != 'OK') THEN
            -- vlc_respuesta := vlt_respuesta.imprimir_json();
            RETURN vlt_respuesta;
        END IF;

        BEGIN
            vln_pidm_orig := gb_common.f_get_pidm(matricula_orig);
        EXCEPTION
            WHEN OTHERS THEN
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la matrícula de la factura cancelada.');
                RETURN vlt_respuesta;
        END;

        BEGIN
            vln_pidm_nuevo := gb_common.f_get_pidm(matricula_nuevo);
        EXCEPTION
            WHEN OTHERS THEN
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la matrícula de la factura que sustituirá.');
                RETURN vlt_respuesta;
        END;

        FOR i IN (
            SELECT TZRPOFI_IAC_CDE
            FROM tzrpofi
            WHERE tzrpofi_pidm = vln_pidm_orig
                AND TZRPOFI_DOCNUM_POS = tran_number_orig
        ) LOOP
            vlc_guid_cancelar := i.TZRPOFI_IAC_CDE;
        END LOOP;

        -- dbms_output.put_line('UUID 1:'||vlc_guid_cancelar);

        IF (NVL(vlc_guid_cancelar, '|') = '|') THEN
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.errores.EXTEND;
            vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la factura a cancelar');
            RETURN vlt_respuesta;
        END IF;

        FOR j IN (
            SELECT TZRPOFI_IAC_CDE, TZRPOFI_DOC_NUMBER, TZRPOFI_EXP_PDF_LBL_1
            FROM tzrpofi
            WHERE tzrpofi_pidm = vln_pidm_nuevo
                AND TZRPOFI_DOCNUM_POS = tran_number_nuevo
        ) LOOP
            vlc_guid_sustituir := j.TZRPOFI_IAC_CDE;
            vlc_numFactura := j.TZRPOFI_DOC_NUMBER;
            vlc_empresa := j.TZRPOFI_EXP_PDF_LBL_1; 
        END LOOP;

        -- dbms_output.put_line('UUID 2:'||vlc_guid_sustituir);

        IF (NVL(vlc_guid_sustituir, '|') = '|') THEN
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.errores.EXTEND;
            vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la factura que sustituirá');
            RETURN vlt_respuesta;
        END IF;

        FOR n IN (
            SELECT c.stvcamp_dicd_code,
                substr(x1.sorxref_edi_qlfr, 3, 1) as empresa
            FROM sovlcur vr 
                JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
                JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
                LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
            WHERE sp.spriden_id = matricula_nuevo
                AND sp.spriden_change_ind IS NULL
                AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
                and x1.sorxref_xlbl_code = 'IPADEEM'
                AND vr.sovlcur_seqno < 4   -- Temporal
        ) LOOP 
            vlc_num_entidad := n.empresa;
        END LOOP;

        vlc_objeto_principal := crea_objeto_sust_tralix(vlc_guid_cancelar, vlc_guid_sustituir, motivo_canc, vlc_empresa);
        vlt_respuesta.mainData := vlc_objeto_principal;
        vlc_envioTralix := envio_canc_tralix(vlc_objeto_principal, 'SUST', vlb_estatusEnvio);
        bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

        dbms_output.put_line('buffer:'||bufferMensaje);

        IF (vlb_estatusEnvio) THEN
            -- vlc_full_motivo_canc := motivo_canc;
            -- IF (motivo_canc = '02') THEN
            --     vlc_full_motivo_canc := vlc_full_motivo_canc || '- Comprobante emitido con errores sin relación.';
            -- ELSIF (motivo_canc = '03') THEN
            --     vlc_full_motivo_canc := vlc_full_motivo_canc || '- No se llevó a cabo la operación.';
            -- ELSIF (motivo_canc = '04') THEN
            --     vlc_full_motivo_canc := vlc_full_motivo_canc || '- Operación nominativa relacionada en una factura global.';
            -- END IF;

            vlc_llamada := tzkrsta.fn_sustituir_factura(vln_pidm_orig, tran_number_orig, matricula_nuevo);

            IF (vlc_llamada != 'OP_EXITOSA') THEN
                rollback;
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.errores.EXTEND;
                vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(vlc_llamada);
                RETURN vlt_respuesta;
            END IF;
            COMMIT;
        ELSE
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.errores.EXTEND;
            vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(bufferMensaje);

            /* Guardar en TZRPAYS, con status = 'T' */
            BEGIN
                pr_log_error(vln_pidm_orig, vlc_numFactura, bufferMensaje,
                    0, motivo_canc, tran_number_orig);
            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.errores.EXTEND;
                    vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(sqlerrm);
                    RETURN vlt_respuesta;
            END;
        END IF;

        RETURN vlt_respuesta;
    END fn_sustitucion_tralix;

    FUNCTION fn_factura_ant_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE', 
        etiqueta IN VARCHAR2 DEFAULT 'FAC')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
    BEGIN
        RETURN fn_factura_base_tralix(matricula, tran_number, tipo_pago_banner,
            tipo_pago_facturar, etiqueta, 'ANT');
    END fn_factura_ant_tralix;
END TZTRALX;
/
show errors;