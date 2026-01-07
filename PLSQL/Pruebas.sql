SELECT *
FROM dba_objects
WHERE object_name = 'TY_TRALIX_ROW_ERROR'
;

SELECT *
FROm spriden
WHERE spriden_pidm = 104677
	AND spriden_change_ind IS NULL
;

SELECT * 
FROM general.gtvsdax
WHERE gtvsdax_external_code = 'MICROSERV'
;

SELECT g.*
FROM goradid g JOIN spriden s ON (g.goradid_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00084775'
	AND s.spriden_change_ind IS NULL
;

SELECT *
FROM goradid
WHERE goradid_pidm IN (104871, 104872, 104924)
;

SELECT *
FROM spraddr
WHERE spraddr_zip = '02080'
	AND spraddr_atyp_code LIKE 'F%'
;

UPDATE goradid
SET goradid_additional_id = '*XAXX010101000'
WHERE goradid_pidm = 104677
	AND goradid_adid_code = '1RFC'
;

COMMIT;

SELECT *
FROM goradid 
WHERE goradid_additional_id LIKE '*XAX%'
	-- AND goradid_adid_code LIKE '%RFC'
	-- AND goradid_additional_id LIKE '*%'
;

DELETE
FROM tvrtsta
WHERE tvrtsta_pidm = 104673
	AND tvrtsta_tran_number = 46
;

COMMIT;

SELECT LISTAGG(goradid_additional_id, '')
	WITHIN GROUP (ORDER BY goradid_adid_code) as razon_social
FROM goradid
WHERE goradid_pidm = 104673
	AND goradid_adid_code LIKE '2RS%'
;

UPDATE goradid
SET goradid_additional_id = '605'  -- 605
WHERE goradid_pidm = 104673
	AND goradid_adid_code = '1RFI'
;

UPDATE goradid
SET goradid_additional_id = '*IPA220921UB9'  -- IPA220921UB9
WHERE goradid_pidm = 104673
	AND goradid_adid_code = '2RFC'
;

COMMIT;

SELECT g.*
FROM spraddr g JOIN spriden s ON (g.spraddr_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00084596'
	AND s.spriden_change_ind IS NULL
;

SELECT t.*
FROM TZRPOFI t JOIN spriden s
	ON (t.tzrpofi_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00010493'
	AND s.spriden_change_ind IS NULL
ORDER BY t.tzrpofi_doc_number
;

SELECT t.tbraccd_pidm, t.tbraccd_tran_number, t.tbraccd_detail_code,
	td.tbbdetc_desc, td.tbbdetc_type_ind, t.tbraccd_amount, 
	t.tbraccd_data_origin, t.tbraccd_tran_number_paid,
	t.tbraccd_receipt_number, t.tbraccd_srce_code
FROM tbraccd t JOIN spriden s
	ON (t.tbraccd_pidm = s.spriden_pidm)
	JOIN tbbdetc td ON (t.tbraccd_detail_code = td.tbbdetc_detail_code)
WHERE s.spriden_id = 'A00084666'
	AND s.spriden_change_ind IS NULL
	AND t.tbraccd_receipt_number = 153
	-- AND t.tbraccd_tran_number = 21
	-- AND t.tbraccd_srce_code = 'Z'
ORDER BY t.tbraccd_tran_number DESC
;


SELECT *
FROM smrprle
WHERE smrprle_program LIKE '%AD2%'
;


DECLARE
	reg_comp TBRACCD%ROWTYPE;
	reg_imp TBRACCD%ROWTYPE;
BEGIN
	SELECT t.*
	INTO reg_comp
	FROM tbraccd t
	WHERE t.tbraccd_pidm = 104737
		AND t.tbraccd_tran_number = 21;

	SELECT t.*
	INTO reg_imp
	FROM tbraccd t
	WHERE t.tbraccd_pidm = 104737
		AND t.tbraccd_tran_number = 20;

    DBMS_OUTPUT.PUT_LINE(TO_CHAR(reg_comp.tbraccd_amount, '0.00000000'));
	DBMS_OUTPUT.PUT_LINE('Porcentaje:' || reg_imp.tbraccd_amount / (reg_comp.tbraccd_amount - reg_imp.tbraccd_amount));	
END;

SELECT NVL(SUM(tbraccd_amount), 0)
            FROM tbraccd t JOIN spriden s
	ON (t.tbraccd_pidm = s.spriden_pidm)
            WHERE tbraccd_tran_number != 42
                AND tbraccd_receipt_number = 96
                AND tbraccd_srce_code = 'Z';

SELECT t.*
FROM tbrappl t JOIN spriden s
	ON (t.tbrappl_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00084607'
	AND s.spriden_change_ind IS NULL
    AND t.tbrappl_pay_tran_number = 46
;

SELECT t.*
FROM tzrpofi t JOIN tbraccd t2
	ON (t.tzrpofi_pidm = t2.tbraccd_pidm
		AND t.tzrpofi_docnum_pos = t2.tbraccd_tran_number)
WHERE t.tzrpofi_iac_cde IS NOT NULL
	AND t2.tbraccd_detail_code = 'FANT'
	AND t.tzrpofi_pidm = gb_common.f_get_pidm('A00084824')
;

A000

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00084933')
;

SELECT tvrtsta_seq_no, tvrtsta_dloc_code, tvrtsta_tsta_code, 
	tvrtsta_comments, tvrtsta_activity_date
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00084933')
	AND tvrtsta_tran_number = 37
;

SELECT SUBSTR('PUBGRAL1', 8, 1)
FROM dual;

SELECT *
FROM dba_objects
WHERE object_name = 'TZKSFIP'
;


SELECT t.tzrpofi_activity_date
FROM tzrpofi t JOIN spriden s ON (t.tzrpofi_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00084606'
	AND s.spriden_change_ind IS NULL
	AND t.tzrpofi_docnum_pos = 81
ORDER BY t.tzrpofi_doc_number DESC
;

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00084985';
	tran_number NUMBER := 9;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_factura_tralix(matricula, tran_number, '28', 'PUE');
	-- vlt_respuesta := ipadedev.tztralx.fn_factura_tralix(gb_common.f_get_id(104744), tran_number, '28', 'PUE');
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
FROM gurdbug
ORDER BY gurdbug_date desc
;

SELECT gb_common.f_get_pidm('A00084739')
FROM dual;

SELECT tvrpays_pidm, tvrpays_return_code, tvrpays_return_code_desc
FROM tvrpays
WHERE tvrpays_pidm = gb_common.f_get_pidm('A00084858')
	-- AND tvrpays_return_code = 108
ORDER BY tvrpays_activity_date DESC
;

DELETE
FROM tvrtsta
WHERE tvrtsta_pidm = 104811
	AND tvrtsta_tran_number = 11
;



DECLARE 
    r raw(50); 
    s varchar2(20); 
BEGIN 
	s:='abcdéf'||chr(170); 
	r:=utl_i18n.string_to_raw(s,'utf8'); 
	dbms_output.put_line(r); 
	dbms_output.put_line(utl_i18n.raw_to_char(hextoraw(r), 'utf8'));
end; 

SELECT parameter, value
  FROM v$nls_parameters
 WHERE parameter LIKE '%CHARACTERSET'
;

DELETE FROM tvrpays WHERE tvrpays_pidm = 104663;
COMMIT;

SELECT t.*
FROM tvrpays t JOIN spriden s ON (t.tvrpays_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00084666'
	AND s.spriden_change_ind IS NULL
;

SELECT *
FROM gtvsdax
WHERE GTVSDAX_COMMENTS LIKE '%wallets%'
;

SELECT *
FROM GTVSDAX
      WHERE gtvsdax_external_code = 'MICROSERV'
;



SELECT * /* t.TVRFWTX_FW_AMOUNT,
              t.TVRFWTX_FW_DETAIL_CODE */
            FROM TVRFWTX t
            WHERE t.tvrfwtx_pidm = 30263 -- pidm
                AND t.TVRFWTX_ORIG_TRAN_NUMBER = 17;

UPDATE tzrpofi
SET tzrpofi_iac_cde = '727E9852-4129-46FA-B523-EEAAC561E0DE'  -- '4D40F2BA-65AA-46ED-9993-95A1B7B47FD1'
WHERE tzrpofi_pidm = 104673
	AND tzrpofi_doc_number = 364
;

COMMIT;

SELECT *
FROM goradid
WHERE goradid_pidm = 30263
;

SELECT *
FROM spraddr 
WHERE spraddr_pidm = 30263
;

SELECT tt.tvrtsta_tran_number, tt.tvrtsta_tsta_code, tt.tvrtsta_dloc_code,
	tt.tvrtsta_comments, ta.tvvtsta_desc
FROM tvrtsta tt LEFT JOIN tvvtsta ta ON (tt.tvrtsta_tsta_code = ta.tvvtsta_code)
WHERE tt.tvrtsta_pidm = 30114
	AND tt.tvrtsta_tran_number = 13
;


SELECT c.stvcamp_dicd_code
            FROM sovlcur vr JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
            WHERE vr.sovlcur_pidm = 30114
                AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner;



727E9852-4129-46FA-B523-EEAAC561E0DE


SELECT test_tralix_seq.nextval FROM dual;

DECLARE
	datosFactura  TY_TRALIX_FACTURA;
	pidm NUMBER;
	vlc_num_entidad VARCHAR2(1 CHAR);
	vlc_num_tipoDir VARCHAR2(1 CHAR);
	vlc_camp_code SATURN.STVCAMP.STVCAMP_CODE%TYPE;
BEGIN
	pidm := 30114;
	FOR n IN (
		SELECT c.stvcamp_dicd_code,
			substr(x1.sorxref_edi_qlfr, 3, 1) as empresa
		FROM sovlcur vr 
			JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
			LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
		WHERE vr.sovlcur_pidm = pidm
			AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
			and x1.sorxref_xlbl_code = 'IPADEEM'
	) LOOP 
		vlc_camp_code := n.stvcamp_dicd_code;
		vlc_num_tipoDir := SUBSTR(vlc_camp_code, LENGTH(vlc_camp_code), 1);
        vlc_num_entidad := n.empresa; 
	END LOOP;
	-- linea01 := ty_tralix_linea;,
	datosFactura := ty_tralix_factura('A00010105',pidm, 13, vlc_num_entidad, vlc_num_tipoDir);
	datosFactura.validar;
	dbms_output.put_line('errores: ' || datosFactura.errores.COUNT);

	IF (datosFactura.errores.COUNT > 0) THEN
		FOR i IN datosFactura.errores.FIRST .. datosFactura.errores.LAST
		LOOP
			dbms_output.put_line(datosfactura.errores(i).mensaje);
		END LOOP;
	END IF;

	-- ty_tralix_factura.info_gral_comprobante.taxesTrasladados := 100.5;
	-- dbms_output.put_line(datosFactura.imprimir_linea); 
	-- dbms_output.put_line(TO_CHAR(tztralx.fn_extrae_banner(30114, 13)));
END;


SELECT *
FROM dba_objects
WHERE object_name = 'TBBACCT'
;

SELECT *
FROM tbraccd 
WHERE tbraccd_pidm = 30771
	AND tbraccd_tran_number = 12
;

SELECT *
FROM tbbdetc
;

/* si conoces pidm */
SELECT TZRPOFI_EXP_PDF_LBL_1 as idEmpresa, TZRPOFI_IAC_CDE as uuid
FROM tzrpofi
WHERE tzrpofi_pidm = pidm
	AND tzrpofi_docnum_pos = tran_number
ORDER BY tzrpofi_activity_date DESC
;

/* si solo conoces la matricula */
SELECT t.TZRPOFI_EXP_PDF_LBL_1 as idEmpresa, t.TZRPOFI_IAC_CDE as uuid
FROM tzrpofi t JOIN spriden s ON (t.tzrpofi_pidm = s.spriden_pidm)
WHERE s.spriden_id = matricula
	AND t.tzrpofi_docnum_pos = tran_number
	AND s.spriden_change_ind IS NULL
ORDER BY t.tzrpofi_activity_date DESC
;

SELECT *
FROM spriden
WHERE Spriden_id LIKE 'NOIDEN%'
;

SELECT *
FROM tbrappl
WHERE tbrappl_pidm = 104691
;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = 104691
;

SELECT *
FROM sovlcur 
WHERE sovlcur_pidm = 104691
;

SELECT sr.*
            FROM spraddr sr
                JOIN spriden sp ON (sr.spraddr_pidm = sp.spriden_pidm)
            WHERE sp.spriden_id LIKE 'IPADE%'
                AND sp.spriden_change_ind IS NULL
                -- AND sr.spraddr_atyp_code = 'F'||difEmpresa
;

SELECT sr.*
FROM spraddr sr
	JOIN spriden sp ON (sr.spraddr_pidm = sp.spriden_pidm)
WHERE sp.spriden_id = 'A00084666'
	AND sp.spriden_change_ind IS NULL
	-- AND sr.spraddr_atyp_code = 'F'||difEmpresa
;

UPDATE spraddr
SET spraddr_zip = '02080'
WHERE spraddr_pidm = 104737
;

COMMIT;

SELECT t.tbrappl_pay_tran_number,
	t.tbrappl_amount,
	0 as TVRFWTX_FW_AMOUNT,
	0 as TVRFWTX_ORIG_AMOUNT,
	'' as TVRFWTX_FW_DETAIL_CODE
FROM tbrappl t
WHERE t.tbrappl_pidm = 104701
	AND t.tbrappl_pay_tran_number = 2
;

select tbraccd_pidm, tbraccd_detail_code, tbraccd_tran_number,
	tbraccd_amount, tbraccd_crossref_pidm, tbraccd_crossref_number,
	tbraccd_data_origin
from tbraccd 
where tbraccd_pidm = 104705
ORDER BY TBRACCD_TRAN_NUMBER DESC;

UPDATE tbraccd
SET tbraccd_detail_code = 'FANT'
WHERE tbraccd_pidm = 104705
	AND tbraccd_tran_number = 3
;

COMMIT;

SELECT tbrappl_chg_tran_number, tbrappl_amount
FROM tbrappl 
WHERE tbrappl_pidm = 104705
;

select *
FROM tbbdetc
WHERE tbbdetc_detail_code in ('PPLN', 'EXAM')
;

select *
from tbbdetc
where tbbdetc_dcat_code = 'CSH'
;

SELECT *
FROM dba_objects
WHERE object_name LIKE 'TY_TRALIX%'
;

SELECT TRIM(TO_CHAR(13.79, '9999999990.00'))
FROM dual;

