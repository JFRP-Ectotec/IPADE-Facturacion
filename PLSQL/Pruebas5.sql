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