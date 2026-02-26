-- Tipo Proceso Banner
DECLARE
    vlc_respuesta VARCHAR2(4000 CHAR);
    vlc_tipoPago VARCHAR2(30 CHAR);
    matricula VARCHAR2(20 CHAR) := 'A00085004';
    tran_number NUMBER := 57;
BEGIN
    vlc_respuesta := tztralx.tipo_proceso_tralix(gb_common.f_get_pidm(matricula), tran_number, vlc_tipoPago);
    dbms_output.put_line('1)'||vlc_respuesta|| ' - |'||vlc_tipoPago);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('2)'||sqlerrm);
END;


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
	matricula VARCHAR2(20 CHAR) := 'A00085020';
	tran_number NUMBER := 268;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
	tran_original NUMBER := 41;
	tran_impuestos NUMBER := 33;
	desc_original VARCHAR2(100 CHAR) := '';
BEGIN
	-- vlt_respuesta := TZTRALX.fn_factura_ant_tralix(matricula, tran_number, '99', 'PPD', 'FAC', 
	--  	tran_original, tran_impuestos, desc_original);
	vlt_respuesta := ipadedev.tztralx.fn_cancela_tralix(matricula, tran_number, '01');
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

-- Verificar estatus transacción
SELECT tvrtsta_pidm, tvrtsta_tsta_code, tvrtsta_tran_number,
	tvrtsta_dloc_code, tvrtsta_comments, TO_CHAR(tvrtsta_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085004')
	AND tvrtsta_tran_number = 57
    -- AND tvrtsta_tsta_code LIKE 'CA%'
;

DELETE FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085004')
	AND tvrtsta_tran_number = 57
    -- AND tvrtsta_tsta_code = 'PC1'
;


-- Verificar en debug
SELECT *
FROM gurdbug
WHERE /*gurdbug_value LIKE '%matricula:A00085059%'
    -- AND gurdbug_parm LIKE '%fn_cancelacion_tralix%'
    -- AND*/ gurdbug_activity_date > TO_DATE('26-FEB-2026 11:24:00', 'DD-MON-YYYY HH24:MI:SS')
    AND gurdbug_activity_date < TO_DATE('26-FEB-2026 11:27:00', 'DD-MON-YYYY HH24:MI:SS')
ORDER BY gurdbug_activity_date DESC
;

-- Verifcar en POFI
SELECT tzrpofi_pidm, tzrpofi_sdoc_code, tzrpofi_docnum_pos, tzrpofi_doc_number, 
	tzrpofi_iac_cde, TZRPOFI_EXP_PDF_LBL_1, tzrpofi_exp_pdf_lbl_2, 
	TO_CHAR(tzrpofi_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085020')
	-- AND tzrpofi_doc_number IN ('9989', '9993')
	AND tzrpofi_docnum_pos = 8
	-- tzrpofi_iac_cde = '47ADBBEB-BDD6-4B33-B51B-CED5587A0657'
;

-- En caso de errores
SELECT tvrpays_return_code_desc, tvrpays_return_code, 
	TO_CHAR(tvrpays_activity_date, 'DD-MON-YYYY HH24:MI:SS')
FROM tvrpays
WHERE tvrpays_pidm = gb_common.f_get_pidm('A00085004')
	AND tvrpays_return_code = 57
;


UPDATE tzrpofi
SET tzrpofi_iac_cde = '621197DB-17AD-477A-A044-610BE6BF9EC7',
	tzrpofi_exp_pdf_lbl_1 = '6dfcc2bf-734f-4b36-961c-a23f62569870' 
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00085020')
	AND tzrpofi_docnum_pos = 268
;

COMMIT;

SELECT *
FROM spriden
WHERE spriden_pidm = 105094 
;

DECLARE
	vlc_respuesta VARCHAR2(500 CHAR);
	matricula SPRIDEN.SPRIDEN_ID%TYPE := 'A00085020';
	tran_number NUMBER := 268;
BEGIN
	vlc_respuesta := tztralx.fn_verifica_cancelacion(gb_common.f_get_pidm(matricula), tran_number);
	dbms_output.put_line(vlc_respuesta);
END;


SELECT SUBSTR('CANCELADO_SIN_ACEPTACION', 1, 9), LENGTH('CANCELADO_SIN_ACEPTACION')
FROM dual
;

COMMIT;