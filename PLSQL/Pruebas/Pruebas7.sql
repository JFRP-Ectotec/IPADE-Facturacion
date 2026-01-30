DECLARE
    vlc_respuesta VARCHAR2(4000 CHAR);
    vlc_tipoPago VARCHAR2(30 CHAR);
BEGIN
    vlc_respuesta := tztralx.tipo_proceso_tralix(gb_common.f_get_pidm('A00085020'), 35, vlc_tipoPago);
    dbms_output.put_line('1)'||vlc_respuesta);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('2)'||sqlerrm);
END;

SELECT t1.tbraccd_tran_number, t1.tbraccd_receipt_number
FROM tbraccd t1
WHERE t1.tbraccd_pidm = gb_common.f_get_pidm('A00085020')
    AND t1.tbraccd_tran_number != 35
    AND EXISTS
    (
        SELECT 1
        FROM tbraccd t2
        WHERE t2.tbraccd_pidm = t1.tbraccd_pidm
            AND t2.tbraccd_receipt_number = t1.tbraccd_receipt_number
            AND t2.tbraccd_tran_number = 35
    );

SELECT tvrtsta_tsta_code, tvrtsta_dloc_code
FROM TVRTSTA
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085020')
    AND tvrtsta_tran_number = 34
    AND (tvrtsta_tsta_code LIKE 'T0%' OR tvrtsta_tsta_code LIKE 'F0%')
;

SELECT INITCAP('aajaj dIU Ioh') FROM dual;

SELECT *
FROM SPRIDEN
WHERE spriden_id = 'A00085020'
;

SELECT *
FROM TBRACCD
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00085016')
    -- AND tbraccd_tran_number = 35
;

'fcarrillo@ipade.mx'

SELECT *
FROM gurdbug
ORDER BY gurdbug_activity_date DESC
;