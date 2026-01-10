SELECT *
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00084933')
    AND tvrtsta_tran_number = 81
;

SELECT ts.*
FROM tvrtsta ts
WHERE ts.tvrtsta_pidm = 104871
    AND ts.tvrtsta_tran_number = 35
;

DELETE FROM tvrtsta
WHERE tvrtsta_pidm = 104871
    AND tvrtsta_tran_number = 35
;

UPDATE tvrtsta
SET tvrtsta_date_tsta = TO_DATE('4-JAN-2026', 'DD-MON-YYYY'),
    tvrtsta_activity_date = TO_DATE('4-JAN-2026', 'DD-MON-YYYY')
WHERE tvrtsta_pidm = 104871
    AND tvrtsta_tran_number = 35
    AND tvrtsta_seq_no > 7
;

COMMIT;

DECLARE
    registros TY_TRALIX_TSTA_ARR;
    registro TY_TRALIX_TSTA_OBJ;
    pidm NUMBER := 104871;
    tranNumber NUMBER := 35;
    contador NUMBER := 0;
    secuencial NUMBER := 0;
    paso VARCHAR2(500 CHAR);
BEGIN
    registros := TY_TRALIX_TSTA_ARR();

    registro := TY_TRALIX_TSTA_OBJ('F01', '', 'PBA-157');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('SOC', '', 'IPADE1');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('FV1', '', '45988');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('UI1', '', 'ABC159A3-087C-4150-A456-75528EA9E7F3');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('FP1', '', 'PPD');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('UF1', '', 'S01');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('RF1', '', 'XAXX010101000');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('F02', '', 'PBA-6552');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('SOC', '', 'IPADE1');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('FV2', '', '45988');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('UI2', '', '');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('FP2', '', 'FAC');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('UF2', '', 'S01');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    registro := TY_TRALIX_TSTA_OBJ('RF2', '', 'XAXX010101000');
    registros.EXTEND();
    registros(registros.COUNT) := registro;

    SELECT NVL(MAX(tvrtsta_seq_no), 0)
    INTO secuencial
    FROM tvrtsta
    WHERE tvrtsta_pidm = pidm
        AND tvrtsta_tran_number = tranNumber;

    SELECT MAX(t.codigo)
    INTO paso
    FROM table(registros) t;

    dbms_output.put_line(paso);

    INSERT INTO TAISMGR.TVRTSTA (
        TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER, TVRTSTA_SEQ_NO, TVRTSTA_TSTA_CODE, TVRTSTA_DATE_TSTA, 
        TVRTSTA_DLOC_CODE, TVRTSTA_COMMENTS, 
        TVRTSTA_ACTIVITY_DATE, TVRTSTA_USER_ID, TVRTSTA_DATA_ORIGIN
    ) SELECT pidm, tranNumber, secuencial + rownum, t.codigo, SYSDATE,
        t.dLocCode, t.valor,
        SYSDATE, USER, 'Tralix'
    FROM table(registros) t
    ;

    COMMIT;
END;

SELECT *
FROM tvvtsta
WHERE tvvtsta_code LIKE 'UI%'
;

SELECT * 
FROM tzrpofi
WHERE tzrpofi_iac_cde = '8596270E-C3F3-4CE7-81F7-CCB4A4ED7C86'
;


SELECT LISTAGG(tbbdetc_detail_code, ',')
FROM tbbdetc
WHERE tbbdetc_dcat_code IN ('VIA','SR1', 'SR2')
;

SELECT *
FROM tbbdetc
WHERE tbbdetc_detail_code = 'EXAM'
;

SELECT s.spriden_id, t.*
FROM spriden s JOIN tbraccd t 
    ON (s.spriden_pidm = t.tbraccd_pidm)
WHERE t.tbraccd_detail_code IN
(
    SELECT tbbdetc_detail_code
    FROM tbbdetc
    WHERE tbbdetc_dcat_code IN ('VIA','SR1', 'SR2')
)
ORDER BY t.tbraccd_activity_date DESC
;
