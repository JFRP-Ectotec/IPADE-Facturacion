DECLARE
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

        l_payload_def CLOB;
        l_function VARCHAR2(50 CHAR) := '/facturatralix/facturatralix';
        l_payload CLOB; 
        estatus BOOLEAN;
    BEGIN
        estatus := TRUE;

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
        DBMS_OUTPUT.PUT_LINE(l_url);

        UTL_HTTP.set_wallet('file:/'||l_wallet_path , l_wallet_password );
        UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(true);
        BEGIN
            l_http_request := UTL_HTTP.begin_request(
                url    => l_url,
                method => 'POST',
                http_version => 'HTTP/1.1'
            );

            l_payload_def := REPLACE(l_payload, '\\', '\');
            -- dbms_output.put_line(l_payload_def);

            -- Add headers
            UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json'); 
            UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_payload_def));

            -- Write the payload
            UTL_HTTP.write_text(l_http_request, l_payload_def);

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
            DBMS_OUTPUT.PUT_LINE('Zona 1:' || l_response);
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

        DBMS_OUTPUT.PUT_LINE('Zona 2:'||l_response);
    END;

SELECT *
FROM tbrappl
;

SELECT s.spriden_id, t.tbraccd_tran_number, t.tbraccd_detail_code, t.tbraccd_amount
FROM tbraccd t
    JOIN tbbdetc d ON (t.tbraccd_detail_code = d.tbbdetc_detail_code)
    JOIN spriden s ON (t.tbraccd_pidm = s.spriden_pidm)
WHERE d.tbbdetc_dcat_code = 'CSH'
;  -- 1-4, 6-7

SELECT *
FROM tbbdetc
;

SELECT *
FROM spriden
WHERE spriden_id LIKE 'IPADE%'
;

SELECT sr.*
FROM spraddr sr
    JOIN spriden sp ON (sr.spraddr_pidm = sp.spriden_pidm)
WHERE sp.spriden_id LIKE 'IPADE%'
;

SELECT *
FROM GORADID
WHERE goradid_additional_id = 'CACX7605101P8'
;

SELECT c.stvcamp_dicd_code,
    substr(x1.sorxref_edi_qlfr, 3, 1) as empresa
FROM sovlcur vr 
    JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
    JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
    LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
WHERE sp.spriden_id = 'A00084596'
    AND sp.spriden_change_ind IS NULL
    AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
    and x1.sorxref_xlbl_code = 'IPADEEM'
;

SELECT spriden_pidm, spriden_id
FROM spriden
WHERE spriden_id LIKE 'PUBGRAL%'
;

SELECT s.spriden_id, g.*
FROM goradid g
	JOIN spriden s ON (s.spriden_pidm = g.goradid_pidm)
WHERE --- g.goradid_pidm = pidm
	-- AND g.goradid_adid_code = 'FRFC'
	s.spriden_id LIKE 'PUBGRAL%'
	AND s.spriden_change_ind IS NULL
;

INSERT INTO GORADID 
(GORADID_PIDM, GORADID_ADDITIONAL_ID, GORADID_ADID_CODE, GORADID_USER_ID, GORADID_ACTIVITY_DATE,
GORADID_DATA_ORIGIN)
SELECT 104670, GORADID_ADDITIONAL_ID, GORADID_ADID_CODE, GORADID_USER_ID, SYSDATE, 'Testing'
FROM goradid
WHERE goradid_pidm = 104669
    AND goradid_additional_id = '616'
;

COMMIT;

SELECT *
FROM spraddr
where spraddr_pidm in (104669, 104670)
;

SELECT *
FROM tbraccd
WHERE tbraccd_detail_code = 'IIVA'
;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = 97013
ORDER BY tbraccd_tran_number
;

SELECT *
FROM tbbdetc
WHERE tbbdetc_detail_code IN ('PLM2', 'PAGM')
;

DECLARE
    vln_pidm NUMBER := 104663;
    vlc_prefijo VARCHAR2(20 CHAR) := 'ZPB';
    vln_numFactura NUMBER := 224;
    tipo_pago_banner VARCHAR2(6 CHAR) := '1';
    uuidTralix VARCHAR2(40 CHAR) := '832A4494-5AFA-4247-A99E-D48DEE70CA88';
    tran_number NUMBER := 3;

BEGIN
    INSERT INTO TAISMGR.TZRPOFI (
        TZRPOFI_PIDM, TZRPOFI_SDOC_CODE, TZRPOFI_DOC_NUMBER, TZRPOFI_DOC_STATUS, TZRPOFI_TERM_CODE, 
        TZRPOFI_DCAT_CODE, TZRPOFI_IAC_CDE, TZRPOFI_INCL_BARCODE_IND, TZRPOFI_INCL_PI_IND, 
        TZRPOFI_PI_IND, TZRPOFI_INCL_DOCNUM_IND, TZRPOFI_DOCNUM_POS,
        TZRPOFI_INCL_SCHG_LABEL, TZRPOFI_DATE_CHG_1, TZRPOFI_DETC_CODE_CHG_1, 
        TZRPOFI_DATA_ORIGIN, TZRPOFI_CREATE_USER_ID, TZRPOFI_CREATE_DATE, 
        TZRPOFI_USER_ID, TZRPOFI_ACTIVITY_DATE
    ) VALUES (
        vln_pidm, vlc_prefijo, TO_CHAR(vln_numFactura), 'A', tipo_pago_banner, 
        'CSH', uuidTralix, 'N', 'N', 
        'N', 'N', tran_number,
        'N', SYSDATE, 'X', 
        'Tralix', USER, SYSDATE, 
        USER, SYSDATE
    );

    dbms_output.put_line('Todo bien');
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(sqlerrm);
END;

DECLARE
    pidm NUMBER := 104663;
    tran_number NUMBER := 3;
    
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

    dbms_output.put_line('codigo: ' || vlc_tipoCodigo);

    IF (vlc_tipoCodigo != '|') THEN
        vln_respuesta := TO_NUMBER(SUBSTR(vlc_tipoCodigo, 2, 1)) + 1;
    END IF;

    vlc_respuesta := TRIM(TO_CHAR(vln_respuesta, '0'));

    dbms_output.put_line(vlc_respuesta);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(sqlerrm);
END;


SELECT *
FROM tzrpofi
WHERE tzrpofi_pidm = 104663
;

SELECT *
FROM tvrtsta
WHERE tvrtsta_pidm = 104663
;

SELECT SUBSTR(MAX(tvrtsta_tsta_code), 2, 2)
FROM tvrtsta
WHERE REGEXP_LIKE (tvrtsta_tsta_code, 'F\d\d')
    AND tvrtsta_pidm = 104663
    AND tvrtsta_tran_number = 4
;

COMMIT;