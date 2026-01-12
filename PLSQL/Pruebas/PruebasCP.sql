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
    objeto_prueba := TY_TRALIX_COMPPAGO('A00084798', 40, 37, 1, 1, '28', 'PUE');
    dbms_output.put_line(objeto_prueba.imprimir_linea);
END;

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