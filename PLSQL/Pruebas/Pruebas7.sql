DECLARE
    vlc_respuesta VARCHAR2(4000 CHAR);
    vlc_tipoPago VARCHAR2(30 CHAR);
BEGIN
    vlc_respuesta := tztralx.tipo_proceso_tralix(gb_common.f_get_pidm('A00084868'), 24, vlc_tipoPago);
    dbms_output.put_line('1)'||vlc_respuesta|| ' - |'||vlc_tipoPago);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('2)'||sqlerrm);
END;


SELECT t1.tbraccd_tran_number, t1.tbraccd_receipt_number
                    FROM tbraccd t1
                    WHERE t1.tbraccd_pidm = gb_common.f_get_pidm('A00084868')
                        AND t1.tbraccd_tran_number != 24
                        AND EXISTS
                        (
                            SELECT 1
                            FROM tbraccd t2
                            WHERE t2.tbraccd_pidm = gb_common.f_get_pidm('A00084868')
                                AND t2.tbraccd_receipt_number = t1.tbraccd_receipt_number
                                AND t2.tbraccd_tran_number = 24
                        )
;

SELECT *
        FROM tvrtsta t1
        WHERE t1.tvrtsta_pidm = gb_common.f_get_pidm('A00084868')
            AND t1.tvrtsta_tran_number = 22
            --AND t1.tvrtsta_dloc_code = 'PPD'
            AND t1.tvrtsta_tsta_code =
            (SELECT MAX(t2.tvrtsta_tsta_code)
            FROM tvrtsta t2
            WHERE t2.tvrtsta_pidm = t1.tvrtsta_pidm
                AND t2.tvrtsta_tran_number = t1.tvrtsta_tran_number
                AND t2.tvrtsta_tsta_code LIKE 'F0%' 
            )
        ;


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
FROM TBRAPPL
WHERE tbrappl_pidm = gb_common.f_get_pidm('A00085025')
    -- AND tbraccd_tran_number = 35
;

'fcarrillo@ipade.mx'

SELECT *
FROM gurdbug
ORDER BY gurdbug_activity_date DESC
;

SELECT c.stvcamp_dicd_code,
                    substr(x1.sorxref_edi_qlfr, 3, 1) as empresa
                FROM sovlcur vr 
                    JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
                    JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
                    LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
                WHERE sp.spriden_id = 'A00085025'
                    AND sp.spriden_change_ind IS NULL
                    AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
                    and x1.sorxref_xlbl_code = 'IPADEEM'
                    AND vr.sovlcur_seqno < 4 
;

DECLARE
    datosCompPago TY_TRALIX_COMPPAGO;
    matricula spriden.spriden_id%TYPE := 'A00085025';
    tran_number NUMBER := 9;
    vln_tran_number_orig NUMBER := 8;
    vlc_num_entidad VARCHAR2(1 CHAR) := '2';
    vlc_tipo_pago_banner VARCHAR2(10 CHAR) := '01';
    tipo_pago_facturar  VARCHAR2(10 CHAR) := 'PUE';
BEGIN
    datosCompPago := ty_tralix_comppago(matricula, tran_number, vln_tran_number_orig,
        vlc_num_entidad, 1, vlc_tipo_pago_banner, tipo_pago_facturar);
    dbms_output.put_line(datosCompPago.imprimir_linea);
END;

SELECT spraddr_atyp_code, spraddr_street_line4
FROM spraddr
WHERE spraddr_pidm = gb_common.f_get_pidm('A00085025')
;