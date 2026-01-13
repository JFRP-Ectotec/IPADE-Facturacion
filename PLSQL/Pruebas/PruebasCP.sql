SELECT t1.tbrappl_pidm, t1.tbrappl_pay_tran_number,
    t1.tbrappl_chg_tran_number, t3.tzrpofi_iac_cde
FROM tbrappl t1 
    JOIN tbraccd t2 ON (
        t1.tbrappl_pidm = t2.tbraccd_pidm
        AND t1.tbrappl_chg_tran_number = t2.tbraccd_tran_number)
    JOIN tzrpofi t3 ON (
        t2.tbraccd_pidm = t3.tzrpofi_pidm
        AND t2.tbraccd_tran_number = t3.TZRPOFI_DOCNUM_POS)
    JOIN tzrpofi t4 ON (
        t1.tbrappl_pidm = t4.tzrpofi_pidm
        AND t1.tbrappl_pay_tran_number = t4.tzrpofi_docnum_pos)
WHERE t3.tzrpofi_iac_cde IS NOT NULL
    AND t4.tzrpofi_iac_cde IS NOT NULL
;

SELECT NVL(SUM(tbrappl_amount), 0) as saldoPagado,
                COUNT(*) as numParcialidades
            FROM tbrappl
            WHERE tbrappl_pidm = 104871
                AND tbrappl_chg_tran_number = 37
                AND tbrappl_pay_tran_number < 40
;

SELECT *
FROM tbrappl
WHERE tbrappl_pidm = 104871
    AND tbrappl_chg_tran_number = 37
;

SELECT *
FROM tzrpofi
WHERE tzrpofi_pidm = 104871
    AND tzrpofi_docnum_pos = 37
;

SELECT spriden_id FROM SPRIDEN
WHERE spriden_pidm = 104871;

DECLARE
    objeto_prueba TY_TRALIX_COMPPAGO;
BEGIN
    objeto_prueba := TY_TRALIX_COMPPAGO('A00084989', 7, 6, 1, 1, '28', 'PUE');
    dbms_output.put_line(objeto_prueba.imprimir_linea);
END;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = 105062
    AND tbraccd_tran_number = 7
    AND tbraccd_tran_number_paid = 6
;

SELECT NVL(SUM(tbrappl_amount), 0) as saldoPagado,
    COUNT(*) as numParcialidades
FROM tbrappl
WHERE tbrappl_pidm = 105062
    AND tbrappl_chg_tran_number = 6
    AND tbrappl_pay_tran_number < 7
;

SELECT *
FROM GOREMAL
WHERE goremal_pidm = 108471
;

SELECT t1.*
FROM tbraccd t1 JOIN tbbdetc t2
    ON (t1.tbraccd_detail_code = t2.tbbdetc_detail_code)
    -- JOIN tzrpofi t3 on (t1.tbraccd_pidm = t3.tzrpofi_pidm
    --     AND t1.tbraccd_tran_number = t3.tzrpofi_docnum_pos)
WHERE t2.tbbdetc_desc LIKE '%SPE_DEP%'
    AND t2.tbbdetc_type_ind = 'P'
    AND t2.tbbdetc_dcat_code = 'CSH'
;

DECLARE
    pidm NUMBER := 104744;
    tran_number NUMBER := 114;
BEGIN
    IF (tztralx.existe_factura(pidm, tran_number)) THEN
        dbms_output.put_line('Ya hay factura');
    ELSE
        dbms_output.put_line('No hay factura');
    END IF;
END;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00084989')
;

DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00084989';
	tran_number NUMBER := 7;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_factura_cp_tralix(matricula, tran_number, '28');
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
