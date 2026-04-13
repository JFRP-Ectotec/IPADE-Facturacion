SELECT *
FROM sorxref
WHERE sorxref_xlbl_code = 'IMPUESTO'
;


-- Tipo Proceso Banner
DECLARE
    vlc_respuesta VARCHAR2(4000 CHAR);
    vlc_tipoPago VARCHAR2(30 CHAR);
    matricula VARCHAR2(20 CHAR) := 'A00085126';
    tran_number NUMBER := 27;
BEGIN
    vlc_respuesta := tztralx.tipo_proceso_tralix(gb_common.f_get_pidm('A00085344'), tran_number, vlc_tipoPago);
    dbms_output.put_line('1)'||vlc_respuesta|| ' - |'||vlc_tipoPago);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('2)'||sqlerrm);
END;

SELECT tbraccd_pidm, tbraccd_tran_number, tbraccd_detail_code, 
	tbraccd_amount, /*tbraccd_balance, tbraccd_effective_date,*/ tbraccd_receipt_number,
	tbraccd_tran_number_paid, tbraccd_payment_id
FROM tbraccd
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00085020')
	AND tbraccd_tran_number IN (469, 467, 466)
	-- AND tbraccd_receipt_number IN (2655)
;

SELECT tb2.tbraccd_amount as impuestos
                FROM tbraccd tb1
                    JOIN tbraccd tb2 ON (
                        tb1.tbraccd_pidm = tb2.tbraccd_pidm
                        AND tb1.tbraccd_payment_id = tb2.tbraccd_tran_number)    
                WHERE tb1.tbraccd_pidm = gb_common.f_get_pidm('A00085298')
                    AND tb1.tbraccd_tran_number = 24
;

SELECT NVL(SUM(tc.tbraccd_amount), 0)
FROM tvrtsta ta JOIN tzrpofi tz
	ON (ta.tvrtsta_pidm = tz.tzrpofi_pidm
		AND ta.tvrtsta_comments = tz.tzrpofi_iac_cde)
	JOIN tbraccd tc ON (tc.tbraccd_pidm = tz.tzrpofi_pidm
		AND tc.tbraccd_tran_number = tz.tzrpofi_docnum_pos)
WHERE ta.tvrtsta_pidm = gb_common.f_get_pidm('A00085277')
	AND ta.tvrtsta_tran_number = 329
	AND REGEXP_LIKE (ta.tvrtsta_tsta_code, 'UI\d')
;

SELECT * FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085277')
	AND tvrtsta_tran_number = 329
	-- AND tvrtsta_seq_no = 21
;

COMMIT;

SELECT tzrpofi_doc_number, tzrpofi_docnum_pos, tzrpofi_activity_date, tzrpofi_iac_cde
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085531')
	AND tzrpofi_docnum_pos = 6
ORDER BY tzrpofi_activity_date DESC
;

-- Revisar luego el calculo de impuestos.
DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00085568';
	tran_number NUMBER := 11;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 23;
	tran_original NUMBER := 10;
	tran_impuestos NUMBER := 9;
	desc_original VARCHAR2(100 CHAR) := 'S';
	fecha_emision DATE := TO_DATE('11-APR-2026', 'DD-MON-YYYY');
	tipo_pago VARCHAR2(10 CHAR) := '03';
	pago_factura VARCHAR2(10 CHAR) := 'PPD';
	data_origin VARCHAR2(50 CHAR) := 'DEBUG';
BEGIN
	-- vlt_respuesta := TZTRALX.fn_factura_ant_tralix(matricula, tran_number, '99', 'PPD',
	-- 	'FAC',  tran_original, tran_impuestos, desc_original, fecha_emision, 'DEBUG');
	-- vlt_respuesta := TZTRALX.fn_factura_tralix(matricula, tran_number, tipo_pago, 
	-- 	pago_factura, 'FAC', fecha_emision, data_origin);
	-- vlt_respuesta := ipadedev.tztralx.fn_cancela_tralix(matricula, tran_number, '01');
    vlt_respuesta := TZTRALX.fn_factura_cp_tralix(matricula, tran_number, '03', 'CDP', 
		tran_original, fecha_emision, 'DEBUG');
	-- vlt_respuesta := TZTRALX.fn_notacred_tralix(matricula, tran_number, '01', 'PUE',
	-- 	'FAC', tran_original, 'DEBUG');
	-- vlt_respuesta := TZTRALX.fn_factsust_tralix(matricula, tran_number, '01', 'PUE',
	-- 	'FAC', matricula, tran_original, tran_impuestos, NULL, 'DEBUG');

	dbms_output.put_line('Estatus RESP:'||vlt_respuesta.estatus);
	IF (vlt_respuesta.errores.COUNT > 0) THEN
		dbms_output.put_line(vlt_respuesta.errores.COUNT || ' errores');
		FOR m IN vlt_respuesta.errores.FIRST .. vlt_respuesta.errores.LAST
		LOOP
			dbms_output.put_line(num_linea || ' - ' ||vlt_respuesta.errores(m).mensaje);
			num_linea := num_linea + 1;
		END LOOP;
	END IF;
END;


-- Verificar estatus transacción
SELECT tvrtsta_pidm, tvrtsta_tsta_code, tvrtsta_tran_number,
	tvrtsta_dloc_code, tvrtsta_comments, TO_CHAR(tvrtsta_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085149')
	AND tvrtsta_tran_number = 42
    AND tvrtsta_tsta_code LIKE 'CA%'
;

COMMIT;

SELECT TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
from dual;

-- Verificar en debug
SELECT *
FROM gurdbug
WHERE gurdbug_value LIKE '%matricula:%'   -- 85489
    AND gurdbug_parm LIKE '%TZTRALX%fn_factura_cp%'
    --AND*/ gurdbug_activity_date > TO_DATE('06-APR-2026 11:54:00', 'DD-MON-YYYY HH24:MI:SS')
    AND gurdbug_activity_date < TO_DATE('12-APR-2026 11:56:00', 'DD-MON-YYYY HH24:MI:SS') 
	-- AND gurdbug_value LIKE '%CON ERROR:%'
	AND gurdbug_parm NOT LIKE '%sfkfees%'
ORDER BY gurdbug_activity_date DESC
;

SELECT tbrappl_chg_tran_number
FROM tbrappl
WHERE tbrappl_pidm = gb_common.f_get_pidm('A00085398')
	AND tbrappl_pay_tran_number = 171
	AND tbrappl_reappl_ind IS NULL
;


SELECT tvrtsta_seq_no, tvrtsta_tsta_code, tvrtsta_dloc_code
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085296')
	AND tvrtsta_tran_number = 37
	AND tvrtsta_tsta_code LIKE 'F0%'
;

-- Verifcar en POFI
SELECT tzrpofi_pidm, tzrpofi_sdoc_code, tzrpofi_docnum_pos, tzrpofi_doc_number, 
	tzrpofi_iac_cde, TZRPOFI_EXP_PDF_LBL_1, tzrpofi_exp_pdf_lbl_2, 
	TO_CHAR(tzrpofi_activity_date, 'DD-MON-YYYY HH24:MI:SS') as tzrpofi_activity_date,
	TO_CHAR(tzrpofi_pdf_date, 'DD-MON-YYYY HH24:MI:SS') as tzrpofi_pdf_date
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085519')
	-- AND tzrpofi_doc_number IN ('9989', '9993')
--	AND tzrpofi_docnum_pos = 476
	-- tzrpofi_iac_cde = '47ADBBEB-BDD6-4B33-B51B-CED5587A0657'
;

SELECT LENGTH(NVL(TZRPOFI_IAC_CDE, ''))
                FROM tzrpofi
                WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085155')
                    AND tzrpofi_docnum_pos = 19
                ORDER BY tzrpofi_activity_date DESC
;

-- En caso de errores
SELECT tvrpays_return_code_desc, tvrpays_return_code, 
	TO_CHAR(tvrpays_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tvrpays
WHERE tvrpays_pidm = gb_common.f_get_pidm('A00085519')
--	AND tvrpays_return_code IN (3, 4, 5)
;


UPDATE tzrpofi
SET tzrpofi_iac_cde = '06E4C8DE-B9C4-40F6-B4FB-D7D2D6DEC8CF',
	tzrpofi_exp_pdf_lbl_1 = '6dfcc2bf-734f-4b36-961c-a23f62569870' 
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085155')
	AND tzrpofi_docnum_pos = 53
;

COMMIT;

COMMIT;

-- Para poder cancelar
-- 745640F4-2189-4367-B6CC-2A08D7DBCC7F
-- 5FE2721B-887D-4BBA-99E7-DB9D199462BB
-- D6CCE11C-5D26-4A40-B4F9-33A773F13BFA

COMMIT;

DECLARE
	vlc_respuesta VARCHAR2(500 CHAR);
	matricula SPRIDEN.SPRIDEN_ID%TYPE := 'A00085149';
	tran_number NUMBER := 41;
BEGIN
	vlc_respuesta := tztralx.fn_verifica_cancelacion(gb_common.f_get_pidm(matricula), tran_number);
	dbms_output.put_line(vlc_respuesta);
END;

SELECT *
FROM tvrtpdc
;

SELECT *
FROM goradid
WHERE /*goradid_adid_code LIKE 'RS%'
	AND*/ goradid_additional_id LIKE '%STEEL%'
;

SELECT *
FROM goradid
WHERE goradid_pidm = gb_common.f_get_pidm('A00085510')
;

-- Revisar luego el calculo de impuestos.
DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00085463';
	tran_number NUMBER := 16;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
	tran_original NUMBER := 19;
	tran_impuestos NUMBER := NULL;
	desc_original VARCHAR2(100 CHAR) := 'S';
	fecha_emision DATE := TO_DATE('25-MAR-2026', 'DD-MON-YYYY');
BEGIN
	vlt_respuesta := TZTRALX.fn_sustitucion_tralix(matricula, tran_number, 
		matricula, 'CDP', 
		tran_original, fecha_emision, 'DEBUG');
	
	dbms_output.put_line('Estatus RESP:'||vlt_respuesta.estatus);
	IF (vlt_respuesta.errores.COUNT > 0) THEN
		dbms_output.put_line(vlt_respuesta.errores.COUNT || ' errores');
		FOR m IN vlt_respuesta.errores.FIRST .. vlt_respuesta.errores.LAST
		LOOP
			dbms_output.put_line(num_linea || ' - ' ||vlt_respuesta.errores(m).mensaje);
			num_linea := num_linea + 1;
		END LOOP;
	END IF;
END;

SELECT NVL(SUM(tbraccd_amount), 0),
	MAX(tbraccd_detail_code)
FROM tbraccd
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00085402')
	AND tbraccd_tran_number != 15
	AND tbraccd_receipt_number = 2655
	AND tbraccd_detail_code IN
	(
		SELECT DISTINCT t3.tvrtpdc_detc_code
		FROM 
			(SELECT DISTINCT sorxref_banner_value
			FROM sorxref s1
			WHERE sorxref_xlbl_code = 'IMPUESTO') plan_imp
			JOIN tvvtxpr t1 ON (plan_imp.sorxref_banner_value = t1.tvvtxpr_code)
			JOIN tvrtxpr t2 ON (t1.tvvtxpr_code = t2.tvrtxpr_code)
			JOIN tvrtpdc t3 ON (t1.tvvtxpr_code = t3.tvrtpdc_txpr_code)
		WHERE SYSDATE between t2.tvrtxpr_date_from AND NVL(t2.tvrtxpr_date_to, TO_DATE('31-12-2099', 'DD-MM-YYYY'))
	)
;

SELECT tb2.tbraccd_amount
FROM tbraccd tb1
	JOIN tbraccd tb2 ON (
		tb1.tbraccd_pidm = tb2.tbraccd_pidm
		AND tb1.tbraccd_receipt_number = tb2.tbraccd_receipt_number)
WHERE tb1.tbraccd_pidm = gb_common.f_get_pidm('A00085402')
	AND tb1.tbraccd_tran_number = 15
	AND tb2.tbraccd_tran_number != 15
	AND tb2.tbraccd_detail_code IN
	(
		SELECT DISTINCT t3.tvrtpdc_detc_code
		FROM 
			(SELECT DISTINCT sorxref_banner_value
			FROM sorxref s1
			WHERE sorxref_xlbl_code = 'IMPUESTO') plan_imp
			JOIN tvvtxpr t1 ON (plan_imp.sorxref_banner_value = t1.tvvtxpr_code)
			JOIN tvrtxpr t2 ON (t1.tvvtxpr_code = t2.tvrtxpr_code)
			JOIN tvrtpdc t3 ON (t1.tvvtxpr_code = t3.tvrtpdc_txpr_code)
		WHERE SYSDATE between t2.tvrtxpr_date_from AND NVL(t2.tvrtxpr_date_to, TO_DATE('31-12-2099', 'DD-MM-YYYY'))
	)
;

SELECT *
FROM user_objects
WHERE status = 'INVALID'
;


SELECT INSTR('Resp RAW:<html>
<head><title>504 Gateway Time-out</title></head>
<body>
<center><h1>504 Gateway Time-out</h1></center>
<hr><center></center>
</body>
</html>
', '"statusCode":') FROM dual;
