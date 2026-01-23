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
    objeto_prueba := TY_TRALIX_COMPPAGO('A00084990', 17, 15, 1, 1, '28', 'PUE');
    dbms_output.put_line(objeto_prueba.imprimir_linea);
END;

SELECT *
FROM tbraccd
WHERE tbraccd_pidm = 'A00084989'
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
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00084990')
;

PBA - 7798

A00085005 - 24



DECLARE
	datos_banner CLOB;
	matricula VARCHAR2(20 CHAR) := 'A00084990';
	tran_number NUMBER := 16;
	vlt_respuesta TY_TRALIX_ENVIOFAC_RESPONSE;
	num_linea NUMBER := 1;
BEGIN
	vlt_respuesta := TZTRALX.fn_factura_cp_tralix(matricula, tran_number, '04');
	--vlt_respuesta := ipadedev.tztralx.fn_factura_tralix(gb_common.f_get_id(104744), tran_number, '28', 'PUE');
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

DELETE
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00084989')
    AND tzrpofi_docnum_pos = 7
;

DELETE 
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00084989')
    AND tvrtsta_tran_number = 7
;

COMMIT;

SELECT tvrtsta_seq_no, tvrtsta_tsta_code, tvrtsta_dloc_code,
    tvrtsta_comments, TO_CHAR(tvrtsta_activity_date, 'DD-MON-YYYY  HH24:MI:SS')
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00084989')
    AND tvrtsta_tran_number = 7
;

SELECT tzrpofi_iac_cde, TO_CHAR(tzrpofi_activity_date, 'DD-MON-YYYY  HH24:MI:SS')
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00084989')
    AND tzrpofi_docnum_pos = 7
;

SELECT SYSDATE FROM DUAL;

SELECT *
FROM tbraccd t1 
 JOIN tvrtsta t3 ON (t1.tbraccd_pidm = t3.tvrtsta_pidm
    AND t1.tbraccd_tran_number_paid = t3.tvrtsta_tran_number)
WHERE t1.tbraccd_pidm = gb_common.f_get_pidm('A00084989')
    AND t1.tbraccd_tran_number = 7
    AND (
        (tvrtsta_tsta_code LIKE 'T0%' AND tvrtsta_dloc_code = 'FA')
        OR (tvrtsta_tsta_code LIKE 'F0%' AND tvrtsta_dloc_code = 'PPD'))
;

COMMIT;

DELETE FROM gurdbug
WHERE gurdbug_parm LIKE '%TZTRALX%'
;

COMMIT;

SELECT *
FROM gurdbug
WHERE gurdbug_value LIKE '%matricula:A00084989%'
ORDER BY gurdbug_activity_date DESC
;

DECLARE
    vlc_prueba VARCHAR2(5 CHAR);
BEGIN
    dbms_output.put_line(tztralx.tipo_proceso_tralix(105062, 7));
END;

UPDATE TVRPAYS
SET
    TVRPAYS_STATUS='T', 
    TVRPAYS_ACTIVITY_DATE=SYSDATE, 
    --TVRPAYS_DATA_ORIGIN='Tralix',
    TVRPAYS_RETURN_CODE_DESC='{"estatus": "ERROR" ,"errores":["La factura anticipada no está timbrada en Tralix." ]}',
    TVRPAYS_SEQNO=TVRPAYS_SEQNO + 1,
    TVRPAYS_SRV_CODE='01',
    TVRPAYS_RETURN_CODE=TO_CHAR(16)
WHERE tvrpays_pidm = 104744
    AND tvrpays_bank_tran_id = 'NO_TRAN'
;

ROLLBACK;

SELECT COUNT(*)
FROM tvrpays
WHERE tvrpays_pidm = 104744
 --   AND tvrpays_bank_tran_id = 'NO_TRAN'
;

MERGE INTO TAISMGR.TVRPAYS tgt
USING (
    SELECT 104744 as TVRPAYS_PIDM,
        NVL(NULL, 'NO_TRAN') as TVRPAYS_BANK_TRAN_ID,
        '{"estatus": "ERROR" ,"errores":["La factura anticipada no está timbrada en Tralix." ]}' as TVRPAYS_RETURN_CODE_DESC,
        NVL(NULL, 0) as TVRPAYS_AMOUNT,
        '01' as TVRPAYS_SRV_CODE,
        TO_CHAR(16) AS TVRPAYS_RETURN_CODE
    FROM dual
) src
    ON (tgt.TVRPAYS_PIDM=src.TVRPAYS_PIDM 
        AND tgt.TVRPAYS_BANK_TRAN_ID=src.TVRPAYS_BANK_TRAN_ID)
WHEN MATCHED
    THEN UPDATE SET
        tgt.TVRPAYS_STATUS='T', 
        tgt.TVRPAYS_ACTIVITY_DATE=SYSDATE, 
        tgt.TVRPAYS_DATA_ORIGIN='Tralix',
        tgt.TVRPAYS_RETURN_CODE_DESC=src.TVRPAYS_RETURN_CODE_DESC,
        tgt.TVRPAYS_SEQNO=tgt.TVRPAYS_SEQNO + 1,
        tgt.TVRPAYS_SRV_CODE=src.TVRPAYS_SRV_CODE,
        tgt.TVRPAYS_RETURN_CODE=src.TVRPAYS_RETURN_CODE
WHEN NOT MATCHED
    THEN INSERT (TVRPAYS_PIDM, 
        TVRPAYS_AMOUNT, 
        TVRPAYS_BANK_TRAN_ID, 
        TVRPAYS_TRAN_DATE, 
        TVRPAYS_STATUS, 
        TVRPAYS_USER_ID, 
        TVRPAYS_ACTIVITY_DATE, 
        TVRPAYS_DATA_ORIGIN, 
        TVRPAYS_CREATE_DATE, 
        TVRPAYS_CREATE_USER, 
        TVRPAYS_RETURN_CODE,
        TVRPAYS_RETURN_CODE_DESC,
        TVRPAYS_SEQNO,
        TVRPAYS_SRV_CODE)
    VALUES (src.TVRPAYS_PIDM, 
        src.TVRPAYS_AMOUNT, 
        src.TVRPAYS_BANK_TRAN_ID, 
        SYSDATE, 
        'T', 
        USER, 
        SYSDATE, 
        'Tralix', 
        SYSDATE, 
        USER, 
        src.TVRPAYS_RETURN_CODE,
        src.TVRPAYS_RETURN_CODE_DESC, 
        1,
        src.TVRPAYS_SRV_CODE)
    ;

SELECT *
FROM spriden
where spriden_pidm = 105062
;

SELECT *
FROM tzrpofi
WHERE tzrpofi_pidm = 105062
    AND tzrpofi_docnum_pos = 7
;