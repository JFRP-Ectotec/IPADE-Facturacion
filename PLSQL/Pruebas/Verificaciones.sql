-- Tipo Proceso Banner
DECLARE
    vlc_respuesta VARCHAR2(4000 CHAR);
    vlc_tipoPago VARCHAR2(30 CHAR);
    matricula VARCHAR2(20 CHAR) := 'A00085126';
    tran_number NUMBER := 115;
BEGIN
    vlc_respuesta := tztralx.tipo_proceso_tralix(gb_common.f_get_pidm(matricula), tran_number, vlc_tipoPago);
    dbms_output.put_line('1)'||vlc_respuesta|| ' - |'||vlc_tipoPago);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('2)'||sqlerrm);
END;

SELECT *
FROM TVRTSTA
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085126')
	AND tvrtsta_tran_number = 114
;

-- Generar factura
DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00085004';
	tran_number NUMBER := 57;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
	tran_original NUMBER := 41;
	tran_impuestos NUMBER := 33;
	desc_original VARCHAR2(100 CHAR) := '';
BEGIN
	-- vlt_respuesta := TZTRALX.fn_factura_ant_tralix(matricula, tran_number, '99', 'PPD', 'FAC', 
	--  	tran_original, tran_impuestos, desc_original);
	vlt_respuesta := ipadedev.tztralx.fn_factura_tralix(matricula, tran_number, '28', 'PUE');
    -- vlt_respuesta := TZTRALX.fn_factura_cp_tralix(matricula, tran_number, '01');
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


DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00085155';
	tran_number NUMBER := 27;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
	tran_original NUMBER := 26;
	tran_impuestos NUMBER := 33;
	desc_original VARCHAR2(100 CHAR) := '';
BEGIN
	-- vlt_respuesta := TZTRALX.fn_factura_ant_tralix(matricula, tran_number, '99', 'PPD', 'FAC', 
	--  	tran_original, tran_impuestos, desc_original);
	-- vlt_respuesta := ipadedev.tztralx.fn_cancela_tralix(matricula, tran_number, '01');
    -- vlt_respuesta := TZTRALX.fn_factura_cp_tralix(matricula, tran_number, '01');
	vlt_respuesta := TZTRALX.fn_notacred_tralix(matricula, tran_number, '01', 'PUE',
		'FAC', tran_original, 'DEBUG');
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

SELECT *
FROM TVRTSTA
WHERE TVRTSTA_PIDM = gb_common.f_get_pidm('A00085155')
	AND tvrtsta_TRAN_NUMBER = 27
;


SELECT TO_CHAR(2, '00000') from dual;


-- Verificar estatus transacción
SELECT tvrtsta_pidm, tvrtsta_tsta_code, tvrtsta_tran_number,
	tvrtsta_dloc_code, tvrtsta_comments, TO_CHAR(tvrtsta_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085128')
	AND tvrtsta_tran_number = 6
    -- AND tvrtsta_tsta_code LIKE 'CA%'
;

DELETE FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085128')
	AND tvrtsta_tran_number = 6
	AND tvrtsta_tsta_code IN ('T02', 'F02', 'FV2', 'FP2',
		'T03', 'F03', 'FV3', 'FP3')
    -- AND tvrtsta_tsta_code = 'PC1'
;

COMMIT;

-- Verificar en debug
SELECT *
FROM gurdbug
WHERE /*gurdbug_value LIKE '%mat%A00085155%'
    AND*/ gurdbug_parm LIKE '%TZTRALX%'
    AND gurdbug_activity_date > TO_DATE('05-MAR-2026 11:20:00', 'DD-MON-YYYY HH24:MI:SS')
    AND gurdbug_activity_date < TO_DATE('05-MAR-2026 11:22:00', 'DD-MON-YYYY HH24:MI:SS')
ORDER BY gurdbug_activity_date DESC
;

SELECT *
FROM gurdbug
WHERE /*gurdbug_value LIKE '%A00085126%'
    AND*/ gurdbug_parm LIKE '%fn_factura_cp_tralix%'
    -- AND gurdbug_activity_date > TO_DATE('02-MAR-2026 11:10:00', 'DD-MON-YYYY HH24:MI:SS')
    -- AND gurdbug_activity_date < TO_DATE('02-MAR-2026 11:12:00', 'DD-MON-YYYY HH24:MI:SS') */
ORDER BY gurdbug_activity_date DESC
;

-- Verifcar en POFI
SELECT tzrpofi_pidm, tzrpofi_sdoc_code, tzrpofi_docnum_pos, tzrpofi_doc_number, 
	tzrpofi_iac_cde, TZRPOFI_EXP_PDF_LBL_1, tzrpofi_exp_pdf_lbl_2, 
	TO_CHAR(tzrpofi_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085155')
	-- AND tzrpofi_doc_number IN ('9989', '9993')
	AND tzrpofi_docnum_pos = 19
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
WHERE tvrpays_pidm = gb_common.f_get_pidm('A00085004')
	AND tvrpays_return_code = 57
;


UPDATE tzrpofi
SET tzrpofi_iac_cde = 'D6CCE11C-5D26-4A40-B4F9-33A773F13BFA',
	tzrpofi_exp_pdf_lbl_1 = '6dfcc2bf-734f-4b36-961c-a23f62569870' 
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085149')
	AND tzrpofi_docnum_pos = 42
;

-- Para poder cancelar
-- 745640F4-2189-4367-B6CC-2A08D7DBCC7F
-- 5FE2721B-887D-4BBA-99E7-DB9D199462BB
-- D6CCE11C-5D26-4A40-B4F9-33A773F13BFA

COMMIT;

SELECT *
FROM spriden
WHERE spriden_pidm = 105094 
;

DECLARE
	vlc_respuesta VARCHAR2(500 CHAR);
	matricula SPRIDEN.SPRIDEN_ID%TYPE := 'A00085155';
	tran_number NUMBER := 19;
BEGIN
	vlc_respuesta := tztralx.fn_verifica_cancelacion(gb_common.f_get_pidm(matricula), tran_number);
	dbms_output.put_line(vlc_respuesta);
END;


SELECT SUBSTR('CANCELADO_SIN_ACEPTACION', 1, 9), LENGTH('CANCELADO_SIN_ACEPTACION')
FROM dual
;

COMMIT;