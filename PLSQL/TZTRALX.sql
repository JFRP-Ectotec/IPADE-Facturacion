-- DROP PACKAGE TZTRALX;
-- /
-- show errors;

DROP SEQUENCE IPADEDEV.TEST_TRALIX_IP2_SEQ;

CREATE SEQUENCE IPADEDEV.TEST_TRALIX_IP2_SEQ START WITH 6125 INCREMENT BY 1 MINVALUE 0 NOCYCLE NOCACHE NOORDER; 

DROP SEQUENCE IPADEDEV.TEST_TRALIX_IP1_SEQ;

CREATE SEQUENCE IPADEDEV.TEST_TRALIX_IP1_SEQ START WITH 12519 INCREMENT BY 1 MINVALUE 0 NOCYCLE NOCACHE NOORDER; 

SELECT test_tralix_ip2_seq.nextval from dual;

CREATE OR REPLACE PACKAGE TZTRALX IS
    FUNCTION fn_obtener_idEmpresa(numEntidad IN VARCHAR2)
        RETURN VARCHAR2;

    /* TODO: Agregar parametro de si se ejecuta por primera vez, Boolean. */
    FUNCTION fn_factura_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_factura_tralix_json(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2,
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN CLOB;

    FUNCTION fn_cancela_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        motivo_canc IN VARCHAR2,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_sustitucion_tralix(
        matricula_orig IN VARCHAR2,
        tran_number_orig IN NUMBER,
        matricula_nuevo IN VARCHAR2,
        tran_number_nuevo IN NUMBER,
        motivo_canc IN VARCHAR2,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
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
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        tran_number_original IN NUMBER DEFAULT 0,
        tran_number_imp IN NUMBER DEFAULT 0,
        desc_adicional IN VARCHAR2 DEFAULT '',
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_factura_cp_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        tran_a_pagar IN NUMBER,
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_notacred_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        tran_number_original IN NUMBER,
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    FUNCTION fn_factsust_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        matricula_original IN VARCHAR2,
        tran_number_original IN NUMBER,
        tran_impuestos_orig IN NUMBER,
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE;

    separador constant varchar2(1) := '|';

    FUNCTION existe_factura(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER)
        RETURN BOOLEAN;

    FUNCTION tipo_proceso_tralix(
        pin_pidm in NUMBER,
        pin_tran_number IN NUMBER,
        tipo_pago_banner OUT VARCHAR2)
        RETURN VARCHAR2;

    PROCEDURE registrar_error_fa_pue(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER,
        pic_tipo_pago IN VARCHAR2);

    FUNCTION fn_verifica_cancelacion(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER
    ) RETURN VARCHAR2;

END TZTRALX;
/
show errors;

CREATE OR REPLACE PACKAGE BODY TZTRALX IS
    cgc_estatus_debug     CONSTANT VARCHAR2(1) := 'A'; --Estatus de debug en GURDBUG D debug, O Output, A Ambos, I Inactivo
	cgc_raiz_debug        CONSTANT VARCHAR2(100) := 'TZTRALX-';

    PROCEDURE pr_registrar_debug (
        pic_procedimiento	IN	VARCHAR2,
        pic_texto   		IN  VARCHAR2
    ) IS
	BEGIN
		IF cgc_estatus_debug IN ('A','D') THEN
			P_BAN_DEBUG(cgc_raiz_debug||pic_procedimiento,pic_texto);
		END IF;
		
		IF cgc_estatus_debug IN ('A','O') THEN
			DBMS_OUTPUT.PUT_LINE(pic_procedimiento||' -> '||pic_texto);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;

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

    FUNCTION crea_objeto_estatus_fact(
        pic_uuid IN VARCHAR2,
        pic_empresa IN VARCHAR2
    ) RETURN CLOB IS
        vlc_respuesta CLOB;
    BEGIN
        IF (LENGTH(NVL(pic_uuid, '')) < 1) THEN
            RETURN vlc_respuesta;
        END IF;

        gokjson.initialize_clob_output;
        gokjson.open_object(NULL);

        gokjson.write('idEmpresa', pic_empresa);
        gokjson.write('uuid', pic_uuid);
        gokjson.write('produccion', 'true');

        gokjson.close_object;
        vlc_respuesta := gokjson.get_clob_output;
	    gokjson.free_output;
        RETURN vlc_respuesta;
    END crea_objeto_estatus_fact;

    FUNCTION crea_objeto_conscanc_fact(
        pic_uuid IN VARCHAR2,
        pic_empresa IN VARCHAR2
    ) RETURN CLOB IS
        vlc_respuesta CLOB;
    BEGIN
        IF (LENGTH(NVL(pic_uuid, '')) < 1) THEN
            RETURN vlc_respuesta;
        END IF;

        gokjson.initialize_clob_output;
        gokjson.open_object(NULL);

        gokjson.open_array('uuid');
        gokjson.write('X2', pic_uuid);
        gokjson.close_array;

        gokjson.write('idEmpresa', pic_empresa);

        gokjson.close_object;
        vlc_respuesta := gokjson.get_clob_output;
	    gokjson.free_output;

        vlc_respuesta := REPLACE(vlc_respuesta, '"X2":', '');

        RETURN vlc_respuesta;
    END crea_objeto_conscanc_fact;

    FUNCTION crea_objeto_principal(
        matricula IN VARCHAR2,
        pidm IN NUMBER,
        tran_number IN NUMBER,
        datosFactura IN TY_TRALIX_FACTURA,
        datosFacturaCP IN TY_TRALIX_COMPPAGO,
        numEntidad IN VARCHAR2,
        procesoFactura IN VARCHAR2) 
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
        IF (procesoFactura = 'CP') THEN
            gokjson.write('archivoFuente', datosFacturaCP.imprimir_linea);
        ELSE
            gokjson.write('archivoFuente', datosFactura.imprimir_linea);
        END IF;
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
            FROM gtvsdax
            WHERE gtvsdax_external_code = 'MICROSERV'
                AND gtvsdax_internal_code = 'INTG_IPADE'
                AND gtvsdax_internal_code_group = 'WALLET_L'
        ) LOOP
            l_wallet_path := h.valor;
        END LOOP;

        FOR j IN (
            SELECT TO_CHAR(GTVSDAX_COMMENTS) as valor
            FROM gtvsdax
            WHERE gtvsdax_external_code = 'MICROSERV'
                AND gtvsdax_internal_code = 'INTG_IPADE'
                AND gtvsdax_internal_code_group = 'WALLET_P'
        ) LOOP
            l_wallet_password := j.valor;
        END LOOP;

        FOR i IN (
            SELECT TO_CHAR(GTVSDAX_COMMENTS) as valor
            FROM gtvsdax
            WHERE gtvsdax_external_code = 'MICROSERV'
                AND gtvsdax_internal_code = 'INTG_IPADE'
                AND gtvsdax_internal_code_group = 'INTEGR_TX'
        ) LOOP
            l_url := i.valor;
        END LOOP;

        l_url := l_url || l_function;

        pr_registrar_debug('envio_tralix', 'URL:'||l_url);

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

            pr_registrar_debug('envio_tralix', 'Payload:'||l_payload_def);
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

        pr_registrar_debug('envio_tralix', 'Resp RAW:' || l_response);

        -- Determinar status de la respuesta
        l_indice := INSTR(l_response, l_statusCodeTag);

        IF (l_indice < 1) THEN
            RETURN l_response;
        END IF;
        l_ind_fin := INSTR(l_response, ',', l_indice);

        l_indice := l_indice + LENGTH(l_statusCodeTag);

        lr_status := SUBSTR(l_response, l_indice, l_ind_fin - l_indice);

        pr_registrar_debug('envio_tralix', 'Estatus:' || lr_status);

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
        tran_number IN NUMBER,
        data_origin IN VARCHAR DEFAULT 'FACT') IS

        mensaje_desc TVRPAYS.TVRPAYS_RETURN_CODE_DESC%TYPE;
    BEGIN
        pr_registrar_debug('pr_log_error', bufferMensaje);

        IF (LENGTH(bufferMensaje) >= 1000) THEN
            mensaje_desc := SUBSTR(bufferMensaje, 1, 1000);
        ELSE
            mensaje_desc := bufferMensaje;
        END IF;

        -- pr_registrar_debug('pr_log_error', 'TVRPAYS_PIDM: '||vln_pidm);
        -- pr_registrar_debug('pr_log_error', 'TVRPAYS_BANK_TRAN_ID: '||NVL(vln_numFactura, 'NO_TRAN'));
        -- pr_registrar_debug('pr_log_error', 'TVRPAYS_RETURN_CODE_DESC: '||mensaje_desc);
        -- pr_registrar_debug('pr_log_error', 'TVRPAYS_AMOUNT: '||NVL(vln_monto, 0));
        -- pr_registrar_debug('pr_log_error', 'TVRPAYS_SRV_CODE: '||tipo_pago_banner);
        -- pr_registrar_debug('pr_log_error', 'TVRPAYS_RETURN_CODE: '||TO_CHAR(tran_number));

        MERGE INTO TVRPAYS tgt
            USING (
                SELECT vln_pidm as TVRPAYS_PIDM,
                    NVL(vln_numFactura, 'NO_TRAN') as TVRPAYS_BANK_TRAN_ID,
                    mensaje_desc as TVRPAYS_RETURN_CODE_DESC,
                    NVL(vln_monto, 0) as TVRPAYS_AMOUNT,
                    tipo_pago_banner as TVRPAYS_SRV_CODE,
                    TO_CHAR(tran_number) AS TVRPAYS_RETURN_CODE,
                    data_origin AS TVRPAYS_CURRENCY
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
                    tgt.TVRPAYS_SEQNO=
                        CASE WHEN tgt.TVRPAYS_SEQNO < 999 
                            THEN tgt.TVRPAYS_SEQNO + 1
                            ELSE 999
                            END,
                    tgt.TVRPAYS_SRV_CODE=src.TVRPAYS_SRV_CODE,
                    tgt.TVRPAYS_RETURN_CODE=src.TVRPAYS_RETURN_CODE,
                    tgt.TVRPAYS_CURRENCY=src.TVRPAYS_CURRENCY
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
                    TVRPAYS_SRV_CODE,
                    TVRPAYS_CURRENCY)
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
                    src.TVRPAYS_SRV_CODE,
                    src.TVRPAYS_CURRENCY)
                ;
    END;

    FUNCTION fn_reenviar(bufferMensaje CLOB)
        RETURN BOOLEAN IS

        vlb_respuesta BOOLEAN := FALSE;
    BEGIN
        IF ((INSTR(bufferMensaje, 'La clave del campo RegimenFiscalR no corresponde de acuerdo al RFC del receptor') > 0) OR
            (INSTR(bufferMensaje, 'La clave del campo RegimenFiscalR debe corresponder con el tipo de persona (física o moral)') > 0) OR
            (INSTR(bufferMensaje, 'RFC del receptor no existe en la lista de RFC inscritos no cancelados del SAT') > 0) OR
            (INSTR(bufferMensaje, 'debe encontrarse en la lista de RFC inscritos no cancelados en el SAT') > 0)
            ) THEN
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
        proceso_factura IN VARCHAR2 DEFAULT 'DEF',
        tran_number_orig_ant IN NUMBER DEFAULT 0,
        tran_number_imp IN NUMBER DEFAULT 0,
        desc_adicional IN VARCHAR2 DEFAULT '',
        matricula_orig_ant IN VARCHAR2 DEFAULT '',
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')   -- DEF = Default, ANT = Anticipada, CP = Complemento de Pago
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlc_respuesta CLOB;
        ipade_pidm NUMBER;
        datosFactura  TY_TRALIX_FACTURA;
        datosCompPago TY_TRALIX_COMPPAGO;
        vlc_estatus VARCHAR2(50 CHAR);
        vlc_errores VARCHAR2(1000 CHAR);

        vlc_prefijo VARCHAR2(20 CHAR);
        vln_numFactura NUMBER;

        vlc_camp_code  STVCAMP.STVCAMP_CODE%TYPE;
        vlc_num_entidad VARCHAR2(1 CHAR);
        vlc_num_tipoDir VARCHAR2(1 CHAR);
        vlc_objeto_principal CLOB;
        vln_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;

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

        vlc_tipoFactura_TSTA VARCHAR2(2 CHAR) := 'FC';
        vln_tran_number_orig NUMBER;
        vln_contador NUMBER;
        vlc_programa_buscar VARCHAR2(100 CHAR);
    BEGIN
        pr_registrar_debug('fn_factura_base', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number||' tipo_pago_banner:'||
            tipo_pago_banner||' tipo_pago_facturar:'||tipo_pago_facturar||' proceso_factura:'||proceso_factura||' mat_orig_ant:'||matricula_orig_ant
            ||' tran_number_orig_ant:'||tran_number_orig_ant||' tran_number_imp:'||tran_number_imp
            ||' desc_adicional:'||desc_adicional||' fecha_emision:'||TO_CHAR(fecha_emision, 'DD-MON-YYYY'));

        vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);

        BEGIN
            vln_pidm := gb_common.f_get_pidm(matricula);
        EXCEPTION
            WHEN OTHERS THEN
                vlt_respuesta.estatus := 'ERROR';
                -- vlt_respuesta.errores.EXTEND;
                -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := datosFactura.errores('No existe la matrícula');
                vlt_respuesta.agregar_error('No existe la matrícula');
                RETURN vlt_respuesta;
        END;

        IF (tipo_pago_banner = '00') THEN
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('EL tipo de pago no es valor válido.');
            RETURN vlt_respuesta;   
        END IF;

        vlt_respuesta.validar_datos;

        IF (vlt_respuesta.estatus != 'OK') THEN
            -- vlc_respuesta := vlt_respuesta.imprimir_json();
            pr_registrar_debug('fn_factura_base', 'ERROR:'||vlt_respuesta.imprimir_json());
            pr_log_error(vln_pidm, '', vlt_respuesta.imprimir_json(),
                vln_monto, tipo_pago_banner, tran_number);
            COMMIT;
            RETURN vlt_respuesta;
        END IF;

        IF (matricula LIKE 'PUBGRAL%') THEN
            vlc_num_entidad := SUBSTR(matricula, 8, 1);
            vlc_num_tipoDir := 1;
            pubgral := TRUE;
        ELSIF (matricula NOT LIKE 'NOIDEN%') THEN
            FOR n IN (
                SELECT c.stvcamp_dicd_code,
                    substr(x1.sorxref_edi_qlfr, 3, 1) as empresa,
                    sovlcur_program 
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
                vlc_programa_buscar := n.sovlcur_program;
            END LOOP;
        ELSE
            vlc_num_entidad := SUBSTR(matricula, 7, 1);
            vlc_num_tipoDir := 1;
        END IF;

        -- dbms_output.put_line('camp_code:'||vlc_camp_code);
        -- dbms_output.put_line('num_tipoDir:'||vlc_num_tipoDir);
        
        pr_registrar_debug('fn_factura_base', 'num_entidad:'||vlc_num_entidad);

        IF (NVL(vlc_num_entidad, '|') = '|') THEN
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('La carrera '||vlc_programa_buscar||' del alumno no está registrada con etiqueta IPADEEM en SOAXREF');

            pr_registrar_debug('fn_factura_base', 'ERROR: La carrera del alumno no está registrada con etiqueta IPADEEM en SOAXREF');
            pr_log_error(vln_pidm, '', 'La carrera '||vlc_programa_buscar||' del alumno no está registrada con etiqueta IPADEEM en SOAXREF',
                vln_monto, tipo_pago_banner, tran_number);
            COMMIT;
            RETURN vlt_respuesta;
        END IF;

        vlc_tipo_pago_banner := tipo_pago_banner;
        IF (tipo_pago_facturar = 'PPD') THEN
            vlc_tipo_pago_banner := '99';
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

        pr_registrar_debug('fn_factura_base', 'proceso_Factura: '||proceso_factura);
        IF (proceso_factura != 'CP') THEN
            -- IF (NVL(datosFactura.receptor.numGrupo, 0) NOT IN (1, 2)) THEN
            --     pubgral := TRUE;
            --     datosFactura.receptor.datos_pubgral;
            -- END IF;

            datosFactura := ty_tralix_factura(matricula, tran_number, vlc_num_entidad, 
                1, vlc_tipo_pago_banner, tipo_pago_facturar, proceso_factura,
                tran_number_orig_ant, tran_number_imp, desc_adicional, 
                matricula_orig_ant, fecha_emision);       

            datosFactura.validar;
            IF (datosFactura.errores.COUNT > 0) THEN
                vlt_respuesta.estatus := 'ERROR';
                FOR m IN datosFactura.errores.FIRST .. datosFactura.errores.LAST
                LOOP
                    vlt_respuesta.errores.EXTEND;
                    vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := datosFactura.errores(m);
                END LOOP;
                -- vlc_respuesta := vlt_respuesta.imprimir_json();
                pr_log_error(vln_pidm, '', vlt_respuesta.imprimir_json(),
                    vln_monto, tipo_pago_banner, tran_number);
                COMMIT;
                RETURN vlt_respuesta;
            END IF;

            pr_registrar_debug('fn_factura_base', 'datosFactura.receptor.numGrupo: '||datosFactura.receptor.numGrupo);
            IF (NVL(datosFactura.receptor.numGrupo, 0) NOT IN (1, 2, 3, 4, 5)) THEN
                pubgral := TRUE;
            END IF;
        
            datosFactura.info_gral_comprobante.set_folio(vlc_prefijo, TO_CHAR(vln_numFactura));
            IF pubgral THEN
                pr_registrar_debug('fn_factura_base', 'Asignando PUBGRAL');
                datosFactura.receptor.datos_pubgral;
            END IF;
            -- datosFactura.ajustar_pubgral;
        ELSE   -- Complemento de Pago
            vln_tran_number_orig := tran_number_orig_ant;

            IF (NVL(vln_tran_number_orig, 0) = 0) THEN
                FOR z IN (
                    SELECT tbrappl_chg_tran_number
                    FROM tbrappl
                    WHERE tbrappl_pidm = vln_pidm
                        AND tbrappl_pay_tran_number = tran_number
                        AND tbrappl_reappl_ind IS NULL
                ) LOOP
                    vln_tran_number_orig := z.tbrappl_chg_tran_number;
                END LOOP;

                IF (NVL(vln_tran_number_orig, 0) = 0) THEN
                    FOR w IN (
                    SELECT tbraccd_tran_number_paid
                    FROM tbraccd
                    WHERE tbraccd_pidm = vln_pidm
                        AND tbraccd_tran_number = tran_number
                    ) LOOP
                        vln_tran_number_orig := w.tbraccd_tran_number_paid;
                    END LOOP;
                END IF;
            END IF;

            IF (NVL(vln_tran_number_orig, 0) = 0) THEN
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.agregar_error('El complemento no tiene una transacción válida para pagar.');
                RETURN vlt_respuesta;   
            END IF;

            FOR x IN (
                SELECT tvrtsta_dloc_code
                FROM tvrtsta
                WHERE tvrtsta_pidm = vln_pidm
                    AND tvrtsta_tran_number = vln_tran_number_orig
                    AND tvrtsta_tsta_code LIKE 'F0%'
                ORDER BY 1 DESC
            ) LOOP
                IF (x.tvrtsta_dloc_code != 'PPD') THEN
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.agregar_error('La factura original no tiene un método de pago PPD.');
                END IF;    
                EXIT;
            END LOOP;

            -- vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlc_tipo_pago_banner := tipo_pago_banner;
            datosCompPago := ty_tralix_comppago(matricula, tran_number, vln_tran_number_orig,
                vlc_num_entidad, 1, vlc_tipo_pago_banner, tipo_pago_facturar, fecha_emision);
            datosCompPago.validar;
            IF (datosCompPago.errores.COUNT > 0) THEN
                vlt_respuesta.estatus := 'ERROR';
                FOR m IN datosCompPago.errores.FIRST .. datosCompPago.errores.LAST
                LOOP
                    vlt_respuesta.errores.EXTEND;
                    vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := datosCompPago.errores(m);
                END LOOP;
                -- vlc_respuesta := vlt_respuesta.imprimir_json();
                pr_log_error(vln_pidm, '', vlt_respuesta.imprimir_json(),
                    vln_monto, tipo_pago_banner, tran_number);
                COMMIT;
                RETURN vlt_respuesta;
            END IF;
            -- datosCompPago.info_gral_comprobante.subTotalNum := 0;

            datosCompPago.info_gral_comprobante.set_folio(vlc_prefijo, TO_CHAR(vln_numFactura));
            IF pubgral THEN
                datosCompPago.receptor.datos_pubgral;
                vlc_tipoFactura_TSTA := 'FP';
            END IF;
            datosCompPago.ajustar_pubgral;
        END IF;
        vlc_objeto_principal := crea_objeto_principal(matricula, vln_pidm, tran_number, 
            datosFactura, datosCompPago, vlc_num_entidad, proceso_factura);

        vlt_respuesta.mainData := vlc_objeto_principal;

        pr_registrar_debug('fn_factura_base_tralix', 'payload:' || vlc_objeto_principal);
        
        -- vlt_respuesta.estatus := 'ERROR';
        -- vlt_respuesta.agregar_error('No se envía, probando.');
        -- RETURN vlt_respuesta;
        
        vlc_envioTralix := envio_factura_tralix(vlc_objeto_principal, vlb_estatusEnvio);
        vln_monto := 0;

        bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

        pr_registrar_debug('fn_factura_base_tralix', 'bufferMensaje1:' || bufferMensaje);

        IF (NOT(vlb_estatusEnvio)) THEN
            ROLLBACK;

            /* TODO: Si aqui hay un error de  "La clave del campo RegimenFiscalR no corresponde de acuerdo al RFC del receptor" 
            y es primera vez volver a enviar pero indicando que es segunda vez y como si fuera a PubGral. */

            pr_registrar_debug('fn_factura_base_tralix', 'CON ERROR: ' || bufferMensaje || ' proceso_factura:' || proceso_factura);

            IF (NOT(pubgral) AND fn_reenviar(bufferMensaje)) THEN
                IF (proceso_factura != 'CP') THEN
                    datosFactura.receptor.datos_pubgral;
                    -- datosFactura.ajustar_pubgral;
                ELSE
                    datosCompPago.receptor.datos_pubgral;
                    -- datosCompPago.ajustar_pubgral;
                END IF;

                vlc_objeto_principal := crea_objeto_principal(matricula, vln_pidm, tran_number, 
                    datosFactura, datosCompPago, vlc_num_entidad, proceso_factura);
                vlt_respuesta.mainData := vlc_objeto_principal;

                pr_registrar_debug('fn_factura_base_tralix', 'payload 2nd:' || vlc_objeto_principal);

                vlt_respuesta.agregar_error('Situación con Régimen Fiscal. Se envía a PUBLICO EN GENERAL.');
                -- vlt_respuesta.errores.EXTEND;
                -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('Situación con Régimen Fiscal. Se envía a PUBLICO EN GENERAL.');

                vlc_envioTralix := envio_factura_tralix(vlc_objeto_principal, vlb_estatusEnvio);

                vln_monto := 0;

                bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

                pr_registrar_debug('fn_factura_base_tralix', 'bufferMensaje 2nd:' || bufferMensaje);
            END IF;

            IF (NOT(vlb_estatusEnvio)) THEN
                ROLLBACK;
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.agregar_error(bufferMensaje);
                -- vlt_respuesta.errores.EXTEND;
                -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR(bufferMensaje);

                IF (proceso_factura != 'CP') THEN
                    FOR j IN datosFactura.conceptos.FIRST .. datosFactura.conceptos.LAST
                    LOOP
                        vln_monto := vln_monto + datosFactura.conceptos(j).importe;
                    END LOOP;
                ELSE
                    FOR j IN datosCompPago.conceptos.FIRST .. datosCompPago.conceptos.LAST
                    LOOP
                        vln_monto := vln_monto + datosCompPago.conceptos(j).importe;
                    END LOOP;
                END IF;

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

            -- pr_registrar_debug('fn_factura_base_tralix', 'UUID_Value:'||uuidTralix);

            BEGIN
                INSERT INTO TZRPOFI (
                    TZRPOFI_PIDM, TZRPOFI_SDOC_CODE, TZRPOFI_DOC_NUMBER, TZRPOFI_DOC_STATUS, TZRPOFI_TERM_CODE, 
                    TZRPOFI_DCAT_CODE, TZRPOFI_IAC_CDE, TZRPOFI_INCL_BARCODE_IND, TZRPOFI_INCL_PI_IND, 
                    TZRPOFI_PI_IND, TZRPOFI_INCL_DOCNUM_IND, TZRPOFI_DOCNUM_POS, TZRPOFI_EXP_PDF_LBL_1,
                    TZRPOFI_INCL_SCHG_LABEL, TZRPOFI_DATE_CHG_1, TZRPOFI_DETC_CODE_CHG_1, TZRPOFI_PDF_DATE,
                    TZRPOFI_OVRD_FEE_1, TZRPOFI_PO_AMT_1, TZRPOFI_PO_OVRD_AMT_1,
                    TZRPOFI_DATA_ORIGIN, TZRPOFI_CREATE_USER_ID, TZRPOFI_CREATE_DATE, 
                    TZRPOFI_USER_ID, TZRPOFI_ACTIVITY_DATE
                ) VALUES (
                    vln_pidm, vlc_prefijo, TO_CHAR(vln_numFactura), 'A', tipo_pago_banner, 
                    'CSH', uuidTralix, 'N', 'N', 
                    'N', 'N', tran_number, fn_obtener_idEmpresa(vlc_num_entidad),
                    'N', SYSDATE, 'X', fecha_emision,
                    tran_number_orig_ant, tran_number_imp, datosFactura.info_gral_comprobante.tipoCambio,
                    'Tralix', USER, SYSDATE, 
                    USER, SYSDATE
                );

                -- Insertar en TZRTSTA
                -- registro_tsta := TY_TRALIX_REGTSTA(
                --     vlc_prefijo||'-'||vln_numFactura,
                --     'IPADE'||vlc_num_entidad, 
                --     uuidTralix, 
                --     datosFactura.info_gral_comprobante.fecha,
                --     datosFactura.receptor.usoCFDI,
                --     tipo_pago_facturar);

                -- dbms_output.put_line('Registrar en TSTA');

                -- vlc_llamada := tzkrsta.fn_registrar(vln_pidm, tran_number, registro_tsta);
                pr_registrar_debug('fn_factura_base_tralix', '1) proceso_factura:'||proceso_factura||' - vlcTipoFacturaTSTA:'||vlc_tipoFactura_TSTA);
                
                IF (proceso_factura = 'ANT' /* AND vlc_tipoFactura_TSTA != 'FC'*/ ) THEN
                    vlc_tipoFactura_TSTA := 'FA';
                ELSIF (proceso_factura = 'NDC') THEN
                    vlc_tipoFactura_TSTA := 'NC';
                ELSIF (proceso_factura = 'CP') THEN
                    vlc_tipoFactura_TSTA := 'FP';
                END IF;

                pr_registrar_debug('fn_factura_base_tralix', '2) vlcTipoFacturaTSTA:'||vlc_tipoFactura_TSTA);

                vlc_llamada := tzkrsta.fn_registrar(vln_pidm, tran_number, vln_tran_number_orig,
                    uuidTralix, datosFactura, datosCompPago, vlc_tipoFactura_TSTA);
                
                IF (vlc_llamada != 'OP_EXITOSA') THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.agregar_error(vlc_llamada);
                    RETURN vlt_respuesta;
                END IF;
                COMMIT;

            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.agregar_error('TZRPOFI: '||sqlerrm);
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
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
    BEGIN
        pr_registrar_debug('fn_factura_tralix', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number
            ||' tipo_pago_banner:'||tipo_pago_banner||' tipo_pago_facturar:'||tipo_pago_facturar
            ||' fecha_emision:'||fecha_emision);

        IF (NVL(matricula, '|') = '|' OR LENGTH(matricula) < 2
            OR NVL(tran_number, 0) = 0) THEN
            vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('Matrícula y Número de transacción Banner son necesarios.');
            RETURN vlt_respuesta;
        END IF;

        RETURN fn_factura_base_tralix(matricula, tran_number, NVL(tipo_pago_banner, '99'),
            NVL(tipo_pago_facturar, 'PUE'), NVL(etiqueta, 'FAC'), 'DEF', 0, 0,
            '', '', fecha_emision, data_origin);
    END fn_factura_tralix;

    FUNCTION fn_factura_tralix_json(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2,
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE', 
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN CLOB IS
        vlc_respuesta CLOB;
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
    BEGIN
        vlt_respuesta := fn_factura_tralix(matricula, tran_number,
            tipo_pago_banner, tipo_pago_facturar, etiqueta, data_origin);
        
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
        -- IF (l_operacion = 'CANC') THEN
            
        --     l_response := '{"statusCode":200,"headers":{"Content-Type":"application/json"},"body":{"status":"201","descripcion":"CANCELADO_SIN_ACEPTACION"}}';
        --     estatus := TRUE;
        -- END IF;
        -- TEMPORAL forzar para demo FIN
        
        RETURN l_response;
    END envio_canc_tralix;

    FUNCTION fn_cancela_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        motivo_canc IN VARCHAR2,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
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

        ln_indice NUMBER := 0;
        ln_indFin NUMBER := 0;
        vlc_buscarTag VARCHAR2(100 CHAR);
        vlc_respuestaCanc VARCHAR2(200 CHAR);
        vlc_status VARCHAR2(20 CHAR);
        vlc_descEstatus VARCHAR2(100 CHAR);
    BEGIN
        pr_registrar_debug('fn_cancela_tralix', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number
            ||' motivo_canc:'||motivo_canc);

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
                vlt_respuesta.agregar_error('No existe la matrícula');
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
            vlt_respuesta.agregar_error('No existe la factura a cancelar');
            RETURN vlt_respuesta;
        END IF;

        vlc_objeto_principal := crea_objeto_sust_tralix(vlc_guid_cancelar, '', motivo_canc, vlc_empresa);
        vlt_respuesta.mainData := vlc_objeto_principal;

        vlc_envioTralix := envio_canc_tralix(vlc_objeto_principal, 'CANC', vlb_estatusEnvio);

        pr_registrar_debug('fn_cancela_tralix', 'buffer:'||vlc_envioTralix);
        -- bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));

        bufferMensaje := REPLACE(vlc_envioTralix, ' ', '');

        vlc_respuestaCanc := motivo_canc || ' - ';

        /* Obtener código de estatus de la respuesta */
        vlc_buscarTag := '\u0022status\u0022:\u0022';
        ln_indice := INSTR(bufferMensaje, vlc_buscarTag);
        ln_indFin := INSTR(bufferMensaje, '\u0022', ln_indice + LENGTH(vlc_buscarTag));
        vlc_status := SUBSTR(bufferMensaje, ln_indice + LENGTH(vlc_buscarTag), 
            ln_indFin - (ln_indice + LENGTH(vlc_buscarTag)));

        pr_registrar_debug('fn_cancela_tralix', 'vlc_status:'||vlc_status);    

        vlc_respuestaCanc := vlc_respuestaCanc || vlc_status || ' - ';
        
        vlc_buscarTag := '\u0022descripcion\u0022:\u0022';
        ln_indice := INSTR(bufferMensaje, vlc_buscarTag);
        ln_indFin := INSTR(bufferMensaje, '\u0022', ln_indice + LENGTH(vlc_buscarTag));
        vlc_descEstatus := SUBSTR(bufferMensaje, ln_indice + LENGTH(vlc_buscarTag), 
            ln_indFin - (ln_indice + LENGTH(vlc_buscarTag)));
        vlc_respuestaCanc := vlc_respuestaCanc || vlc_descEstatus;

        IF (vlc_status != '201') THEN
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error(vlc_status || '-' || vlc_descEstatus);
            BEGIN
                pr_log_error(vln_pidm, vlc_numFactura, vlc_status || '-' || vlc_descEstatus,
                    0, motivo_canc, tran_number, 'CANC');
            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.agregar_error(sqlerrm);
                    RETURN vlt_respuesta;
            END;
        END IF;

        /* UPDATE en TZRPOFI la respuesta */
        UPDATE tzrpofi
        SET TZRPOFI_EXP_PDF_LBL_2 = vlc_respuestaCanc
        WHERE tzrpofi_pidm = vln_pidm
            AND tzrpofi_docnum_pos = tran_number
            AND tzrpofi_iac_cde = vlc_guid_cancelar
        ;

        IF (NOT(vlb_estatusEnvio)) THEN
            /* Guardar en TZRPAYS, con status = 'T' */
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error(bufferMensaje);
            BEGIN
                pr_log_error(vln_pidm, vlc_numFactura, bufferMensaje,
                    0, motivo_canc, tran_number, 'CANC');
            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.agregar_error(sqlerrm);
                    RETURN vlt_respuesta;
            END;
        ELSE
            /* Insertar en TVRTSTA */
            vlc_llamada := TZKRSTA.fn_registrar_canc_1(vln_pidm, tran_number, motivo_canc);
            IF (vlc_llamada != 'OP_EXITOSA') THEN
                rollback;
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.agregar_error(vlc_llamada);
                RETURN vlt_respuesta;
            END IF;
        END IF;

        COMMIT;

        RETURN vlt_respuesta;
    END fn_cancela_tralix;

    FUNCTION fn_sustitucion_tralix(
        matricula_orig IN VARCHAR2,
        tran_number_orig IN NUMBER,
        matricula_nuevo IN VARCHAR2,
        tran_number_nuevo IN NUMBER,
        motivo_canc IN VARCHAR2,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
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
        pr_registrar_debug('fn_sustitucion_tralix', 'DO:'||data_origin||' matricula_orig:'||matricula_orig
            ||' tran_number_orig:'||tran_number_orig||' matricula_nuevo:'||matricula_nuevo
            ||' tran_number_nuevo:'||tran_number_nuevo||' motivo_canc:'||motivo_canc);
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
                vlt_respuesta.agregar_error('No existe la matrícula de la factura cancelada.');
                -- vlt_respuesta.errores.EXTEND;
                -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la matrícula de la factura cancelada.');
                RETURN vlt_respuesta;
        END;

        BEGIN
            vln_pidm_nuevo := gb_common.f_get_pidm(matricula_nuevo);
        EXCEPTION
            WHEN OTHERS THEN
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.agregar_error('No existe la matrícula de la factura que sustituirá.');
                -- vlt_respuesta.errores.EXTEND;
                -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la matrícula de la factura que sustituirá.');
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
            vlt_respuesta.agregar_error('No existe la factura a cancelar');
            -- vlt_respuesta.errores.EXTEND;
            -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la factura a cancelar');
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
            vlt_respuesta.agregar_error('No existe la factura que sustituirá');
            -- vlt_respuesta.errores.EXTEND;
            -- vlt_respuesta.errores(vlt_respuesta.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la factura que sustituirá');
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

        pr_registrar_debug('fn_sustitucion_tralix', 'buffer:'||bufferMensaje);
                

        IF (vlb_estatusEnvio) THEN
            vlc_llamada := tzkrsta.fn_sustituir_factura(vln_pidm_orig, tran_number_orig, vlc_guid_sustituir);

            IF (vlc_llamada != 'OP_EXITOSA') THEN
                rollback;
                vlt_respuesta.estatus := 'ERROR';
                vlt_respuesta.agregar_error(vlc_llamada);
                RETURN vlt_respuesta;
            END IF;
            COMMIT;
        ELSE
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error(bufferMensaje);

            /* Guardar en TZRPAYS, con status = 'T' */
            BEGIN
                pr_log_error(vln_pidm_orig, vlc_numFactura, bufferMensaje,
                    0, motivo_canc, tran_number_orig, 'CANC');
                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    vlt_respuesta.estatus := 'ERROR';
                    vlt_respuesta.agregar_error(sqlerrm);
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
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        tran_number_original IN NUMBER DEFAULT 0,
        tran_number_imp IN NUMBER DEFAULT 0,
        desc_adicional IN VARCHAR2 DEFAULT '',
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
    BEGIN
        pr_registrar_debug('fn_factura_ant_tralix', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number
            ||' tipo_pago_banner:'||tipo_pago_banner||' tipo_pago_facturar:'||tipo_pago_facturar
            ||' tran_number_original:'||tran_number_original||' tran_number_imp:'||tran_number_imp
            ||' desc_adicional:'||desc_adicional||' fecha_emision:'||TO_CHAR(fecha_emision, 'DD-MON-YYYY HH24:MI:SS'));

        IF (NVL(matricula, '|') = '|' OR LENGTH(matricula) < 2
            OR NVL(tran_number, 0) = 0) THEN
            vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('Matrícula y Número de transacción Banner son necesarios.');
            RETURN vlt_respuesta;
        END IF;

        RETURN fn_factura_base_tralix(matricula, tran_number, NVL(tipo_pago_banner, '99'),
            NVL(tipo_pago_facturar, 'PUE'), NVL(etiqueta, 'FAC'), 'ANT', tran_number_original, 
            tran_number_imp, translate(desc_adicional, chr(10) || chr(13) || chr(09), ' '), 
            '', fecha_emision, data_origin);
    END fn_factura_ant_tralix;

    FUNCTION pago_de_fa(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER
    ) RETURN VARCHAR2 IS
        vln_contador NUMBER := 0;
        vlc_respuesta tvrtsta.tvrtsta_dloc_code%TYPE := 'XXX';
    BEGIN
        SELECT COUNT(*)
        INTO vln_contador
        FROM tvrtsta t1
        WHERE t1.tvrtsta_pidm = pin_pidm
            AND t1.tvrtsta_tran_number = pin_tran_number
            AND t1.tvrtsta_dloc_code = 'FA'
            AND t1.tvrtsta_tsta_code =
            (SELECT MAX(t2.tvrtsta_tsta_code)
            FROM tvrtsta t2
            WHERE t2.tvrtsta_pidm = t1.tvrtsta_pidm
                AND t2.tvrtsta_tran_number = t1.tvrtsta_tran_number
                AND t2.tvrtsta_tsta_code LIKE 'T0%' 
            ) 
        ;

        IF (vln_contador > 0) THEN
            FOR i IN (
                SELECT t1.tvrtsta_dloc_code
                FROM tvrtsta t1
                WHERE t1.tvrtsta_pidm = pin_pidm
                    AND t1.tvrtsta_tran_number = pin_tran_number
                    --AND t1.tvrtsta_dloc_code = 'PPD'
                    AND t1.tvrtsta_tsta_code =
                    (SELECT MAX(t2.tvrtsta_tsta_code)
                    FROM tvrtsta t2
                    WHERE t2.tvrtsta_pidm = t1.tvrtsta_pidm
                        AND t2.tvrtsta_tran_number = t1.tvrtsta_tran_number
                        AND t2.tvrtsta_tsta_code LIKE 'F0%' 
                    )
            ) LOOP
                vlc_respuesta := i.tvrtsta_dloc_code;
            END LOOP;
        END IF;

        RETURN vlc_respuesta;
    END pago_de_fa;

    FUNCTION fn_factura_cp_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        tran_a_pagar IN NUMBER,
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vln_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
        vlc_tipo_pago_anticipada tvrtsta.tvrtsta_dloc_code%TYPE;
        vlc_mensaje_error VARCHAR2(200 CHAR);
    BEGIN
        pr_registrar_debug('fn_factura_cp_tralix', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number
            ||' tipo_pago_banner:'||tipo_pago_banner||' etiqueta:'||etiqueta||' tran_a_pagar:'||tran_a_pagar
            ||' fecha_emision:'||TO_CHAR(fecha_emision, 'DD-MON-YYYY'));

        IF (NVL(matricula, '|') = '|' OR LENGTH(matricula) < 2
            OR NVL(tran_number, 0) = 0) THEN
            vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('Matrícula y Número de transacción Banner son necesarios.');
            RETURN vlt_respuesta;
        END IF;

        vln_pidm := gb_common.f_get_pidm(matricula);
        vlc_tipo_pago_anticipada := pago_de_fa(vln_pidm, tran_a_pagar);
        vlc_mensaje_error := 'La factura anticipada no debe ser con tipo pago PUE';
        IF (vlc_tipo_pago_anticipada = 'PUE') THEN
            pr_log_error(vln_pidm, TO_CHAR(tran_a_pagar), vlc_mensaje_error,
                0, tipo_pago_banner, tran_a_pagar, data_origin);
            
            vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error(vlc_mensaje_error);
            RETURN vlt_respuesta;
        END IF;

        RETURN fn_factura_base_tralix(matricula, tran_number, NVL(tipo_pago_banner, '99'),
            'PPD', NVL(etiqueta, 'FAC'), 'CP', tran_a_pagar, 0, '', '', fecha_emision, data_origin);
    END fn_factura_cp_tralix;

    FUNCTION fn_notacred_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        tran_number_original IN NUMBER,
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
    BEGIN
        pr_registrar_debug('fn_notacred_tralix', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number
            ||' tipo_pago_banner:'||tipo_pago_banner||' tipo_pago_facturar:'||tipo_pago_facturar
            ||' tran_number_original:'||tran_number_original||' fecha_emision:'||TO_CHAR(fecha_emision, 'DD-MON-YYYY'));

        IF (NVL(matricula, '|') = '|' OR LENGTH(matricula) < 2
            OR NVL(tran_number, 0) = 0) THEN
            vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('Matrícula y Número de transacción Banner son necesarios.');
            RETURN vlt_respuesta;
        END IF;

        RETURN fn_factura_base_tralix(matricula, tran_number, NVL(tipo_pago_banner, '99'),
            NVL(tipo_pago_facturar, 'PUE'), NVL(etiqueta, 'FAC'), 'NDC', tran_number_original, 
            0, '', '', fecha_emision, data_origin);
    END fn_notacred_tralix;

    FUNCTION fn_factsust_tralix(
        matricula IN VARCHAR2,
        tran_number IN NUMBER,
        tipo_pago_banner IN VARCHAR2 DEFAULT '99',
        tipo_pago_facturar IN VARCHAR2 DEFAULT 'PUE',  /* Valores válidos 'PUE', 'PPD' */
        etiqueta IN VARCHAR2 DEFAULT 'FAC',
        matricula_original IN VARCHAR2,
        tran_number_original IN NUMBER,
        tran_impuestos_orig IN NUMBER,
        fecha_emision IN DATE,
        data_origin IN VARCHAR2 DEFAULT 'LOCAL')
        RETURN TY_TRALIX_ENVIOFAC_RESPONSE IS
        vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
    BEGIN
        pr_registrar_debug('fn_factsust_tralix', 'DO:'||data_origin||' matricula:'||matricula||' tran_number:'||tran_number
            ||' tipo_pago_banner:'||tipo_pago_banner||' tipo_pago_facturar:'||tipo_pago_facturar
            ||' matricula_original:'||matricula_original||' tran_number_original:'||tran_number_original
            ||' tran_impuestos_orig:'||tran_impuestos_orig||' fecha_emision:'||TO_CHAR(fecha_emision, 'DD-MON-YYYY'));

        IF (NVL(matricula, '|') = '|' OR LENGTH(matricula) < 2
            OR NVL(tran_number, 0) = 0) THEN
            vlt_respuesta := TY_TRALIX_ENVIOFAC_RESPONSE(matricula, tran_number);
            vlt_respuesta.estatus := 'ERROR';
            vlt_respuesta.agregar_error('Matrícula y Número de transacción Banner son necesarios.');
            RETURN vlt_respuesta;
        END IF;

        RETURN fn_factura_base_tralix(matricula, tran_number, NVL(tipo_pago_banner, '99'),
            NVL(tipo_pago_facturar, 'PUE'), NVL(etiqueta, 'FAC'), 'FST', tran_number_original, 
            tran_impuestos_orig, '', matricula_original, fecha_emision, data_origin);
    END fn_factsust_tralix;

    FUNCTION existe_factura(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER)
        RETURN BOOLEAN IS
        vlb_respuesta BOOLEAN := FALSE;
        vln_contador NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO vln_contador
        FROM tbraccd t1
            JOIN tbbdetc t2 ON (t1.tbraccd_detail_code = t2.tbbdetc_detail_code)
        WHERE t1.tbraccd_pidm = pin_pidm
            AND t1.tbraccd_tran_number = pin_tran_number
            AND t2.tbbdetc_desc LIKE '%SPE_DEP%'
            AND tbbdetc_type_ind = 'P'
            AND tbbdetc_dcat_code = 'CSH'
        ;

        IF (vln_contador > 0) THEN
            SELECT COUNT(*)
            INTO vln_contador
            FROM tzrpofi
            WHERE tzrpofi_pidm = pin_pidm
                AND tzrpofi_docnum_pos = pin_tran_number;

            vlb_respuesta := (vln_contador > 0);
        END IF;

        RETURN vlb_respuesta;
    END existe_factura;

    FUNCTION transaccion_es_fa(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER
    ) RETURN BOOLEAN IS
        vlb_respuesta BOOLEAN := false;
    BEGIN
        vlb_respuesta := (pago_de_fa(pin_pidm, pin_tran_number) = 'PPD');

        RETURN vlb_respuesta;
    END transaccion_es_fa;

    FUNCTION tipo_proceso_tralix(
        pin_pidm in NUMBER,
        pin_tran_number IN NUMBER,
        tipo_pago_banner OUT VARCHAR2)
        RETURN VARCHAR2 IS
        vlc_respuesta VARCHAR2(3 CHAR) := 'ER';  
        vlc_cod_detalle TBRACCD.TBRACCD_DETAIL_CODE%TYPE;
        vln_contador NUMBER;
    BEGIN
        pr_registrar_debug('tipo_proceso_tralix', 'PIDM:'||pin_pidm||' Tran_Number:'||pin_tran_number);

        BEGIN
            FOR i IN (
                SELECT tbraccd_detail_code
                FROM tbraccd
                WHERE tbraccd_pidm = pin_pidm
                    AND tbraccd_tran_number = pin_tran_number
            ) LOOP
                vlc_cod_detalle := i.tbraccd_detail_code;
            END LOOP;

            IF (NVL(vlc_cod_detalle, '|') = '|') THEN
                RETURN vlc_respuesta;
            END IF;

            /* Verificar si está en proceso de cancelación */
            SELECT COUNT(*)
            INTO vln_contador
            FROM tvrtsta
            WHERE tvrtsta_pidm = pin_pidm
                AND tvrtsta_tran_number = pin_tran_number
                AND tvrtsta_tsta_code LIKE 'PC%';

            IF (vln_contador > 0) THEN
                RETURN 'CN';
            END IF;

            FOR k IN (
                SELECT tvrtsta_comments
                FROM tvrtsta
                WHERE tvrtsta_pidm = pin_pidm
                    AND tvrtsta_tran_number = pin_tran_number
                    AND tvrtsta_tsta_code LIKE 'FP%'
                ORDER BY tvrtsta_tsta_code
            ) LOOP
                tipo_pago_banner := k.tvrtsta_comments;
                EXIT;
            END LOOP;

            IF (transaccion_es_fa(pin_pidm, pin_tran_number)) THEN
                vlc_respuesta := 'FA';
                -- pr_registrar_debug('tipo_proceso_tralix', 'Factura anticipada');
                RETURN vlc_respuesta;
            ELSE
                FOR j IN (
                    SELECT DISTINCT tbrappl_pay_tran_number
                    FROM tbrappl
                    WHERE tbrappl_pidm = pin_pidm
                        AND tbrappl_chg_tran_number = pin_tran_number
                ) LOOP
                    IF (transaccion_es_fa(pin_pidm, j.tbrappl_pay_tran_number)) THEN
                        vlc_respuesta := 'FP';
                        -- pr_registrar_debug('tipo_proceso_tralix', 'Factura anticipada');
                        RETURN vlc_respuesta;
                    END IF;
                END LOOP;
            END IF;

            -- Buscar todas las transacciones relacionadas con esta 
            vlc_respuesta := 'FC';
            FOR k IN (
                SELECT t1.tbraccd_tran_number, t1.tbraccd_receipt_number
                FROM tbraccd t1
                WHERE t1.tbraccd_pidm = pin_pidm
                    AND t1.tbraccd_tran_number != pin_tran_number
                    AND t1.tbraccd_detail_code = 'FANT'
                    AND EXISTS
                    (
                        SELECT 1
                        FROM tbraccd t2
                        WHERE t2.tbraccd_pidm = t1.tbraccd_pidm
                            AND t2.tbraccd_receipt_number = t1.tbraccd_receipt_number
                            AND t2.tbraccd_tran_number = pin_tran_number
                    )
            ) LOOP
                pr_registrar_debug('tipo_proceso_tralix', 'PIDM:'||pin_pidm||' Tran_Number:'||pin_tran_number);
                vlc_respuesta := 'ER';
                IF (transaccion_es_fa(pin_pidm, k.tbraccd_tran_number)) THEN
                    vlc_respuesta := 'FP';
                END IF;
                EXIT;
            END LOOP;
                
        EXCEPTION
            WHEN OTHERS THEN
                pr_registrar_debug('tipo_proceso_tralix', sqlerrm);
                vlc_respuesta := 'ER';
        END;

        pr_registrar_debug('tipo_proceso_tralix', 'Respuesta:'||vlc_respuesta);
        RETURN vlc_respuesta;
    END tipo_proceso_tralix;

    PROCEDURE registrar_error_fa_pue(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER,
        pic_tipo_pago IN VARCHAR2) IS
        vlc_factura VARCHAR2(50 CHAR);
    BEGIN
        FOR i IN (
            SELECT tvrtsta_comments
            FROM tvrtsta
            WHERE tvrtsta_pidm = pin_pidm
                AND tvrtsta_tran_number = pin_tran_number
                AND tvrtsta_tsta_code LIKE 'F0%'
            ORDER BY tvrtsta_tsta_code DESC
        ) LOOP
            vlc_factura := i.tvrtsta_comments;
            EXIT;
        END LOOP;

        pr_log_error(pin_pidm, NVL(vlc_factura, TO_CHAR(pin_tran_number)), 
            'No se puede facturar anticipada con pago PUE',
            0, '99', pin_tran_number, 'CANC');
    END registrar_error_fa_pue;

    FUNCTION fn_verifica_cancelacion(
        pin_pidm IN NUMBER,
        pin_tran_number IN NUMBER
    ) RETURN VARCHAR2 IS
        vlc_respuesta VARCHAR2(500 CHAR) := 'OP_EXITOSA';
        vlc_objeto_estatus CLOB;
        bufferMensaje CLOB;
        vlc_envioTralix CLOB;
        estatus BOOLEAN := TRUE;
        vlc_uuid VARCHAR2(100 CHAR);
        vlc_empresa VARCHAR2(100 CHAR);
        vlc_motivo_canc VARCHAR2(200 CHAR);
        ln_indice NUMBER := 0;
        ln_indFin NUMBER := 0;
        vlc_tagBuscar VARCHAR2(100 CHAR) := ' - ';
        vlc_estatus_Factura VARCHAR2(50 CHAR);
        vlc_llamada VARCHAR2(200 CHAR);
        vlc_full_motivo_canc VARCHAR2(500 CHAR);
        vlc_llam_tsta VARCHAR2(500 CHAR);
    BEGIN
        BEGIN
            pr_registrar_debug('fn_verifica_cancelacion','pidm:'||pin_pidm||' tran_number:'||pin_tran_number);
            FOR i IN (
                SELECT TZRPOFI_IAC_CDE, TZRPOFI_EXP_PDF_LBL_1,
                    TZRPOFI_EXP_PDF_LBL_2
                FROM tzrpofi
                WHERE tzrpofi_pidm = pin_pidm
                    AND tzrpofi_docnum_pos = pin_tran_number
                ORDER BY tzrpofi_activity_date DESC
            ) LOOP
                vlc_uuid := i.TZRPOFI_IAC_CDE;
                vlc_empresa := i.TZRPOFI_EXP_PDF_LBL_1;
                vlc_motivo_canc := i.TZRPOFI_EXP_PDF_LBL_2;
                EXIT;
            END LOOP;

            pr_registrar_debug('fn_verifica_cancelacion','uuid:'||vlc_uuid);
            -- vlc_objeto_estatus := crea_objeto_estatus_fact(vlc_uuid, vlc_empresa);
            
            IF (LENGTH(NVL(vlc_uuid, '')) > 1) THEN
                vlc_objeto_estatus := crea_objeto_conscanc_fact(vlc_uuid, vlc_empresa);
                vlc_envioTralix := envio_tralix('/facturatralix/consultaCancelacion', vlc_objeto_estatus, estatus);   
                -- Linea TEMPORAL, quitar antes de enviar a PROD.
                --vlc_envioTralix := '[{"uuid": "EEA19FE5-E428-4B8D-BA5B-39462E423BB3", "fecha": "2026-02-12 00:00:00.0","serie": "WS","folio": "28","rfc": "CCM660128HR9","iva": "0.000000","monto": "1.000000","descuento": "0.000000","subtotal": "1.000000","tipoCambio": "1.0000","tipoMoneda": "MXN","idCfd": "d8e6ccc0c345a697a5e61e2557849d89","idSucursal": "40aec84a3811b3d1be3d2cd9763dcc9f","status": "CANCELADO","produccion": true,"fechaCancelacion": "2026-02-12 16:38:16.0","tienePDF": "true"}]';  
                if NOT(estatus) THEN
                    vlc_respuesta := 'ERROR_AL_PEDIR_ESTATUS';
                ELSE
                    /* Ver si ya está cancelada */
                    bufferMensaje := fn_limpia_string_error(TO_CHAR(vlc_envioTralix));
                    bufferMensaje := REPLACE(bufferMensaje, ' ', '');
                    dbms_output.put_line('bufferMensaje:'||bufferMensaje);

                    vlc_tagBuscar := '"status":"';
                    ln_indice := INSTR(bufferMensaje, vlc_tagBuscar);
                    ln_indFin := INSTR(bufferMensaje, '"', ln_indice + LENGTH(vlc_tagBuscar));
                    vlc_estatus_Factura := SUBSTR(bufferMensaje, ln_indice + LENGTH(vlc_tagBuscar), 
                        ln_indFin - (ln_indice + LENGTH(vlc_tagBuscar)));

                    pr_registrar_debug('fn_verifica_cancelacion','estatus:'||vlc_estatus_Factura);

                    IF ((LENGTH(vlc_estatus_Factura) >= 10) AND (SUBSTR(vlc_estatus_Factura, 1, 9) = 'CANCELADO')) THEN
                        vlc_tagBuscar := ' - ';
                        --ln_indice := INSTR(vlc_motivo_canc, vlc_tagBuscar);
                        vlc_motivo_canc := SUBSTR(vlc_motivo_canc, 1, 2);

                        vlc_full_motivo_canc := vlc_motivo_canc;
                        IF (vlc_motivo_canc = '02') THEN
                            vlc_full_motivo_canc := vlc_full_motivo_canc || '- Comprobante emitido con errores sin relación.';
                        ELSIF (vlc_motivo_canc = '03') THEN
                            vlc_full_motivo_canc := vlc_full_motivo_canc || '- No se llevó a cabo la operación.';
                        ELSIF (vlc_motivo_canc = '04') THEN
                            vlc_full_motivo_canc := vlc_full_motivo_canc || '- Operación nominativa relacionada en una factura global.';
                        END IF;

                        vlc_respuesta := tzkrsta.fn_cancelar_factura(pin_pidm, pin_tran_number, vlc_full_motivo_canc);
                    ELSE
                        vlc_respuesta := 'NO_CANCELADO';
                    END IF;
                END IF;
            ELSE
                vlc_respuesta := 'ERROR_OBJETO';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                vlc_respuesta := sqlerrm;
        END;
        IF (vlc_respuesta != 'OP_EXITOSA') THEN
            ROLLBACK;
        ELSE
            COMMIT;
        END IF;
        pr_registrar_debug('fn_verifica_cancelacion','Respuesta:'||vlc_respuesta);
        RETURN vlc_respuesta;
    END fn_verifica_cancelacion;
END TZTRALX;
/

show errors;