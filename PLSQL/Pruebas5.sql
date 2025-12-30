SELECT t.tbraccd_tran_number, t.tbraccd_detail_code,
    t.tbraccd_amount
FROM tbraccd t
WHERE t.tbraccd_pidm = gb_common.f_get_pidm('A00084755')
ORDER BY t.tbraccd_tran_number
;

SELECT t.tzrpofi_sdoc_code, t.tzrpofi_doc_number,
    t.tzrpofi_iac_cde, t.tzrpofi_docnum_pos
FROM tzrpofi t 
WHERE t.tzrpofi_pidm = gb_common.f_get_pidm('A00084824')
ORDER BY tzrpofi_doc_number DESC
;

SELECT *
FROM spriden
WHERE spriden_pidm = 39522
;

SELECT *
FROM sovlcur
WHERE sovlcur_pidm = gb_common.f_get_pidm('A00084970')
;

SELECT c.stvcamp_dicd_code,
	substr(x1.sorxref_edi_qlfr, 3, 1) as empresa,
	vr.sovlcur_program
FROM sovlcur vr 
	JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
	JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
	LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
WHERE sp.spriden_id = 'A00084970'
	AND sp.spriden_change_ind IS NULL
	-- AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
	-- and x1.sorxref_xlbl_code = 'IPADEEM'
;

SELECT *
FROM sorxref
WHERE sorxref_banner_value = 'CAAD2'
;

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00084970';
	tran_number NUMBER := 3;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_factura_ant_tralix(matricula, tran_number, '28', 'PPD');
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

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00084755';
	tran_number NUMBER := 73;
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

DECLARE
	matricula VARCHAR2(20 CHAR) := 'A00019509';
	tran_number NUMBER := 1;
	vlt_compPago TY_TRALIX_COMPPAGO;
BEGIN
	dbms_output.put_line('*'||TO_CHAR(tran_number, '000000')||'*');
	-- vlt_compPago := TY_TRALIX_COMPPAGO(matricula, tran_number, '1', '1', '28', 'PPD');
	-- dbms_output.put_line(vlt_compPago.imprimir_linea);
END;

SELECT *
FROM DBA_OBJECTS
WHERE object_name LIKE 'TY_TRALIX%'
;

SELECT *
FROM spraddr 
WHERE spraddr_pidm = gb_common.f_get_pidm('A00084966')
;

SELECT s.spriden_id, g.*
FROM goradid g JOIN spriden s ON (g.goradid_pidm = s.spriden_pidm)
WHERE s.spriden_id IN ('A00084966', 'A00084933')
	AND g.goradid_adid_code LIKE '1RS%'
	AND s.spriden_change_ind IS NULL
ORDER BY s.spriden_id, g.goradid_adid_code
;

UPDATE goradid
SET goradid_additional_id = 'IPA220921UB9'
WHERE goradid_pidm = gb_common.f_get_pidm('A00084966')
	AND goradid_adid_code = '1RFC'
;

UPDATE goradid
SET goradid_additional_id = '*SPE661112KJ4'
WHERE goradid_pidm = gb_common.f_get_pidm('A00084966')
	AND goradid_adid_code = '2RFC'
;

COMMIT;

SELECT *
FROM tbrappl
WHERE tbrappl_pidm = gb_common.f_get_pidm('A00084933')
;

SELECT t.tbraccd_pidm, t.tbraccd_tran_number, t.tbraccd_detail_code,
  t.tbraccd_receipt_number, t.tbraccd_amount
FROM tbraccd t
WHERE t.tbraccd_pidm = gb_common.f_get_pidm('A00084970')
;

SELECT *
FROM tbrappl
WHERE tbrappl_pidm = gb_common.f_get_pidm('A00084755')
	AND tbrappl_pay_tran_number = 73
;

SELECT *
FROM tbraccd
Where tbraccd_pidm = gb_common.f_get_pidm('A00084933')
	and tbraccd_tran_number != 35
	AND tbraccd_receipt_number = 811
;

SELECT tzrpofi_docnum_pos, tzrpofi_doc_number, tzrpofi_iac_cde, 
	tzrpofi_activity_date - 6/24
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00084969')
;

SELECT tvrpays_pidm, tvrpays_return_code, tvrpays_return_code_desc, 
	tvrpays_activity_date - 6/24
FROM tvrpays
WHERE tvrpays_pidm = gb_common.f_get_pidm('A00084967')
	-- AND tvrpays_return_code = 4
;

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00084798';
	tran_number NUMBER := 7;
	tran_destino NUMBER := 43;
	-- vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
	comp_pago TY_TRALIX_COMPPAGO;
BEGIN
	comp_pago := TY_TRALIX_COMPPAGO(matricula, tran_number, tran_destino, 1, 1, '01', 'PPD');
	dbms_output.put_line(comp_pago.imprimir_linea);
END;


SELECT DISTINCT s.spriden_pidm, s.spriden_id, 
--	t1.tbraccd_tran_number
	t2.tbrappl_pay_tran_number, t2.tbrappl_chg_tran_number
FROM tzrpofi tz 
	JOIN tbraccd t1 ON (t1.tbraccd_pidm = tz.tzrpofi_pidm
		AND t1.tbraccd_tran_number = tz.TZRPOFI_DOCNUM_POS)
	JOIN tbrappl t2 ON (t1.tbraccd_pidm = t2.tbrappl_pidm
		AND t1.tbraccd_tran_number = t2.tbrappl_chg_tran_number)
	JOIN spriden s ON (t1.tbraccd_pidm = s.spriden_pidm)
WHERE t1.tbraccd_detail_code = 'FANT'
	AND s.spriden_change_ind IS NULL
;

SELECT tbrappl_amount, tbrappl_chg_tran_number, tbrappl_pay_tran_number
FROM tbrappl
WHERE tbrappl_pidm = 104871
	AND tbrappl_chg_tran_number = 43
;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = 104871
	AND tbraccd_tran_number IN (7, 8, 9, 43)
;

SELECT *
FROM TZRPOFI
WHERE tzrpofi_pidm = 104673
	AND tzrpofi_docnum_pos = 104
;


SELECT NVL(SUM(tbrappl_amount), 0) as saldoPagado,
                COUNT(*) as numParcialidades
            FROM tbrappl
            WHERE tbrappl_pidm = 104673
                AND tbrappl_chg_tran_number = 18
                AND tbrappl_pay_tran_number < 20
;

DECLARE
	linea TY_TRALIX_LINEA_99;
BEGIN
	linea := TY_TRALIX_LINEA_99(10);
	dbms_output.put_line(linea.format_moneda(0));
END;

SELECT *
FROM tvvtsta
WHERE tvvtsta_desc LIKE '%RAZÓN%'
;

SELECT sysdate - 6/24
FROM dual
;

SELECT *
FROM spraddr
WHERE spraddr_pidm = gb_common.f_get_pidm('A00084933')
;

SELECT *
FROM goradid
WHERE goradid_pidm = gb_common.f_get_pidm('A00084933')
;

SELECT sorxref_banner_value
FROM sorxref
WHERE sorxref_xlbl_code = 'IMPUESTO'
;