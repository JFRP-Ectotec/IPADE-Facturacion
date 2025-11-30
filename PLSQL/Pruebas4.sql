DECLARE
    l_function VARCHAR2(50 CHAR) := '/facturatralix/facturatralix';
    l_payload VARCHAR2(4000);
    estatus BOOLEAN;

    l_http_request  UTL_HTTP.req;
    l_http_response UTL_HTTP.resp;
    l_url           VARCHAR2(200); -- := 'https://mstest.ipade.mx/facturatralix/facturatralix';
    l_response      CLOB;
    detException    BOOLEAN := false;

    l_wallet_path VARCHAR2(200) := '/opt/oracle/dcs/commonstore/wallets/DBTEST_vtq_qro/cert';
    l_wallet_password VARCHAR2(200) := 'Ipade2025#$';

    l_indice NUMBER;
    l_ind_fin NUMBER;
    l_statusCodeTag VARCHAR2(20 CHAR) := '"statusCode":';
    l_bodyTag VARCHAR2(10 CHAR) := '"body":';

    lr_status VARCHAR2(5 CHAR);
    lr_body VARCHAR2(4000 CHAR);

    l_payload_def VARCHAR2(4000 CHAR);
BEGIN
    dbms_output.put_line('INICIO');
    estatus := TRUE;

    l_payload := '{"idEmpresa": "472529fa-1b6a-42b5-bb99-15f19feff522" ,"idTipoCfd": "585087f1c503fff95e94fdebe7ace250" ,"idSucursal": "4f96a4aaa817086dace8f96c48b0c4b4" ,"nombre": "A00084607_46.txt" ,"archivoFuente": "00|A00084607_46.txt|FAC|4.0|\\n01|ZPB370|ZPB|370|2025-11-13T22:00:13|431.03|500.00|68.97|||||MXN|1|||||I|PPD|02080||99||01||\\n03|IPA220921UB9|IPA220921UB9|INSTITUTO PANAMERICANO DE ALTA DIRECCION DE EMPRESA|México|AVENIDA AZCAPOTZALCO|145|||Ciudad De Mexico||Azcapotzalco|Ciudad de Mexico|02080|||G03|601|\\n05|86121702||1|FACT_COB_SPE_TDD_MXN_S|431.03|431.03||E48||Linea_1|02|\\n05C|Linea_1|431.03|002|Tasa|0.160000|68.97|\\n06|002|0.160000|68.97|Tasa|431.03|\\n99|7" }';
    
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

        l_payload_def := CONVERT(REPLACE(l_payload, '\\', '\'), 'AL32UTF8', 'WE8ISO8859P1');
        dbms_output.put_line(l_payload_def);

        -- l_payload_def := 
        --     utl_i18n.raw_to_char(
        --         hextoraw(
        --             utl_i18n.string_to_raw(l_payload_def, 'utf8')
        --         ), 'utf8'
        --     )
        -- ;

        -- Add headers
        -- UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json'); 
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
                dbms_output.put_line(l_response);
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
        dbms_output.put_line('ERROR 1:'||l_response);
    ELSE
        dbms_output.put_line('AQUI:'||l_response);
    END IF;

    -- Determinar status de la respuesta
    l_indice := INSTR(l_response, l_statusCodeTag);
    l_ind_fin := INSTR(l_response, ',', l_indice);

    l_indice := l_indice + LENGTH(l_statusCodeTag);

    lr_status := SUBSTR(l_response, l_indice, l_ind_fin - l_indice);

    -- Determinar body
    l_indice := INSTR(l_response, l_bodyTag);
    l_ind_fin := INSTR(l_response, '}', l_indice);

    l_indice := l_indice + LENGTH(l_bodyTag) + 1;

    l_response := SUBSTR(l_response, l_indice + 1, l_ind_fin - l_indice);

    IF (lr_status != '200') THEN
        estatus := FALSE;
    END IF;

    dbms_output.put_line('FIN:'||l_response);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('GENERAL:' || sqlerrm);

END;

SELECT *
FROM sorxref
WHERE sorxref_xlbl_code = 'IPADEEM'
    AND sorxre
;

SELECT c.stvcamp_dicd_code,
    vr.sovlcur_seqno,
    x1.sorxref_edi_qlfr,
    vr.sovlcur_levl_code,
    sl.stvlevl_desc,
    vr.sovlcur_program,
    sv.sovlfos_priority_no,
    sv.sovlfos_cact_code,
    sv.sovlfos_current_ind,
    sv.sovlfos_active_ind,
    sv.sovlfos_current_cde
FROM sovlcur vr 
    JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
    JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
    JOIN stvlevl sl ON (vr.sovlcur_levl_code = sl.stvlevl_code)
    JOIN sovlfos sv ON (vr.sovlcur_pidm = sv.sovlfos_pidm 
        AND vr.sovlcur_seqno = sv.sovlfos_lcur_seqno)
    LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
WHERE sp.spriden_id = 'A00084607'
    AND sp.spriden_change_ind IS NULL
    AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
    and x1.sorxref_xlbl_code = 'IPADEEM' 
;

SELECT sv.*
FROM sovlfos sv
    JOIN spriden sp ON (sv.sovlfos_pidm = sp.spriden_pidm)
WHERE sp.spriden_id = 'A00084607'
    AND sp.spriden_change_ind IS NULL
;

SELECT TEST_TRALIX_SEQ.nextval
FROM dual;

SELECT *
FROM dba_objects
WHERE object_name = 'GZKNUMB'
;

DECLARE 
  vt_prueba_linea3  TY_TRALIX_LINEA_03;
BEGIN
    vt_prueba_linea3 := TY_TRALIX_LINEA_03(104673,2);
    dbms_output.put_line(vt_prueba_linea3.imprimir_linea);
END;

SELECT gzknumb.monto_escrito(101.25) from dual;

DECLARE
    num_letra VARCHAR2(18);
    longitud  NUMBER(10);
    contador  NUMBER(10);
    aux       VARCHAR2(2);
    parte     VARCHAR2(20);
    partee     VARCHAR2(30);
    tempo     VARCHAR2(18);
    may       NUMBER(14,2);
    mil_mil   VARCHAR2(50);
    p_letra   VARCHAR2(250);
    p_monto NUMBER := 100;
BEGIN
    tempo := SUBSTR(LTRIM(TO_CHAR(p_monto,'000000000000.00')),1,16);
    num_letra := tempo;
    contador  := 1;

    dbms_output.put_line(tempo);

    dbms_output.put_line(SUBSTR(num_letra, 10, 3));

    -- gzknumb.cientos(0,
    --     SUBSTR(num_letra,14,2),
    --     parte,
    --     longitud,
    --     SUBSTR(num_letra,2,2));

    -- dbms_output.put_line('parte:' || parte);
    -- dbms_output.put_line('longitud:' || longitud);
END;

SELECT *
FROM tvvtsta
WHERE tvvtsta_code LIKE 'FP%'
;

SELECT t.tzrpofi_sdoc_code, t.tzrpofi_doc_number,
    t.tzrpofi_term_code, t.tzrpofi_activity_date
FROM tzrpofi t JOIN spriden s
    ON (t.tzrpofi_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00084799'
    AND s.spriden_change_ind IS NULL
ORDER BY t.tzrpofi_doc_number DESC
;

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'PUBGRAL1';
	tran_number NUMBER := 142;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_cancela_tralix(matricula, tran_number, '02');
	dbms_output.put_line('Estatus RESP:'||vlt_respuesta.estatus);
	--IF (vlt_respuesta.estatus != 'OK') THEN
	IF (vlt_respuesta.errores.COUNT > 0) THEN
		dbms_output.put_line(vlt_respuesta.errores.COUNT || ' errores');
		FOR m IN vlt_respuesta.errores.FIRST .. vlt_respuesta.errores.LAST
		LOOP
			dbms_output.put_line(num_linea || ' - ' ||vlt_respuesta.errores(m).mensaje);
			num_linea := num_linea + 1;
		END LOOP;
	END IF;
END;

SELECT *
FROM tvrpays
WHERE tvrpays_pidm = 104672
;

SELECT *
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('PUBGRAL1')
    AND tzrpofi_docnum_pos = 142
;

-- select *
delete
from tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('PUBGRAL1')
    AND tvrtsta_tran_number = 142
   AND tvrtsta_seq_no > 7
-- ORDER BY tvrtsta_seq_no
;

SELECT *
FROM tvrtsta
ORDER BY tvrtsta_activity_date DESC
;

commit;

SELECT SUBSTR(NVL(MAX(tvrtsta_tsta_code), '|'), 2, 1)
FROM tvrtsta
WHERE REGEXP_LIKE (tvrtsta_tsta_code, 'CA\d')
    AND tvrtsta_pidm = gb_common.f_get_pidm('PUBGRAL1')
    AND tvrtsta_tran_number = 142
;

INSERT INTO TAISMGR.TVRTSTA (
    TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER, TVRTSTA_SEQ_NO, TVRTSTA_TSTA_CODE, TVRTSTA_DATE_TSTA, 
    TVRTSTA_DLOC_CODE, TVRTSTA_COMMENTS, 
    TVRTSTA_ACTIVITY_DATE, TVRTSTA_USER_ID, TVRTSTA_DATA_ORIGIN
) VALUES (
    104669, 142, 8, 'CA1', SYSDATE, 
    '', 'Cancelada', 
    SYSDATE, USER, 'Tralix'
);

COMMIT;

INSERT INTO "GENERAL".GZVPRMH
(GZVPRMH_CODE, GZVPRMH_DESC, GZVPRMH_CREATE_DATE, GZVPRMH_ACTIVITY_DATE, GZVPRMH_USER_ID, 
GZVPRMH_DATA_ORIGIN)
VALUES('FACTANTICIP', 'Tipos de pago para factura anticipada', SYSDATE, SYSDATE, USER, 
'Carga Inicial');


SELECT g1.GZVPRMD_INTERNAL_CODE, g1.GZVPRMD_SHORT_EXTERNAL
FROM gzvprmd g1
WHERE g1.gzvprmd_prmh_code = 'FACTPAYLINEA'
    AND g1.gzvprmd_seq_no = 
        (SELECT MAX(g2.gzvprmd_seq_no)
        FROM gzvprmd g2
        WHERE g2.GZVPRMD_PRMH_CODE = g1.GZVPRMD_PRMH_CODE 
            AND g2.GZVPRMD_INTERNAL_CODE = g1.GZVPRMD_INTERNAL_CODE)
;

DECLARE
	datos_banner CLOB;
	matricula_orig VARCHAR2(20 CHAR) := 'PUBGRAL1';
	tran_number_orig NUMBER := 142;
    matricula_new VARCHAR2(20 CHAR) := 'A00084798';
	tran_number_new NUMBER := 81;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_sustitucion_tralix(matricula_orig, tran_number_orig, 
        matricula_new, tran_number_new, '01');
	dbms_output.put_line('Estatus RESP:'||vlt_respuesta.estatus);
	--IF (vlt_respuesta.estatus != 'OK') THEN
	IF (vlt_respuesta.errores.COUNT > 0) THEN
		dbms_output.put_line(vlt_respuesta.errores.COUNT || ' errores');
		FOR m IN vlt_respuesta.errores.FIRST .. vlt_respuesta.errores.LAST
		LOOP
			dbms_output.put_line(num_linea || ' - ' ||vlt_respuesta.errores(m).mensaje);
			num_linea := num_linea + 1;
		END LOOP;
	END IF;
END;