SELECT t.tbraccd_tran_number, t.tbraccd_detail_code,
    t.tbraccd_amount
FROM tbraccd t
WHERE t.tbraccd_pidm = gb_common.f_get_pidm('A00084824')
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

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00019509';
	tran_number NUMBER := 1;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_factura_ant_tralix(matricula, tran_number, '28', 'PUE');
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
FROM tbrappl
WHERE tbrappl_pidm = gb_common.f_get_pidm('A00019509')
;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00019509')
	AND tbraccd_tran_number IN (1,2)
;

SELECT *
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00019509')
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