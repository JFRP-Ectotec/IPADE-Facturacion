SELECT *
FROM gurdbug
-- WHERE gurdbug_parm LIKE '%TZTRALX%'
--     OR gurdbug_parm LIKE '%LINEA%'
ORDER BY gurdbug_activity_date DESC
;

SELECT TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') FROM dual;

SELECT *
FROM tzrpofi
WHERE tzrpofi_pidm = gb_common.f_get_pidm('A00084990')
ORDER BY tzrpofi_activity_date DESC
;

SELECT * FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085002')
AND tvrtsta_tran_number = 19
;

SELECT *
FROM tvrpays
WHERE tvrpays_pidm = gb_common.f_get_pidm('A00085002')
;

SELECT B.*
          FROM TVRTSTA B, PARAMETROS PRM
         WHERE B.TVRTSTA_PIDM = PRM.PIDM
            AND b.tvrtsta_pidm = gb_common.f_get_pidm('A00084975')

SELECT TVRTSTA_PIDM,
    TVRTSTA_TRAN_NUMBER,
    TVRTSTA_SEQ_NO,
    CASE
        WHEN REGEXP_LIKE(TVRTSTA_TSTA_CODE, '^F0[0-9]') THEN
        TVRTSTA_COMMENTS
        ELSE
        CASE
        WHEN REGEXP_LIKE(TVRTSTA_TSTA_CODE, '^CA[0-9]') THEN
            'CANCELADA'
        ELSE
            'No Facturado'
        END
    END AS TVRTSTA_COMMENTS
FROM TVRTSTA A
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00084755')
    AND tvrtsta_tran_number = 87
;

SELECT *
FROM tvrtsta
WHERE tvrtsta_pidm = gb_common.f_get_pidm('A00085002')
    AND tvrtsta_tran_number = 
;

SELECT SORLCUR_PIDM, SORLCUR_PROGRAM, SORLCUR_PRIORITY_NO
FROm sorlcur
WHERE sorlcur_pidm = gb_common.f_get_pidm('A00085002')
;

(SELECT SORLCUR_PIDM, SORLCUR_PROGRAM, SORLCUR_PRIORITY_NO
FROM SORLCUR A
WHERE A.SORLCUR_PIDM = gb_common.f_get_pidm('A00085002')
    AND A.SORLCUR_CURRENT_CDE = 'Y'
    AND A.SORLCUR_CACT_CODE = 'ACTIVE'
    AND A.SORLCUR_LMOD_CODE = 'LEARNER'
UNION
SELECT SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1, B.SORLCUR_PRIORITY_NO
    FROM SGBSTDN A, SORLCUR B
    WHERE A.SGBSTDN_PIDM = gb_common.f_get_pidm('A00085002')
    AND A.SGBSTDN_TERM_CODE_EFF =
        (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
            FROM SGBSTDN B
            WHERE B.SGBSTDN_PIDM = A.SGBSTDN_PIDM)
    AND A.SGBSTDN_PROGRAM_1 = B.SORLCUR_PROGRAM
    AND B.SORLCUR_PIDM = A.SGBSTDN_PIDM
    AND B.SORLCUR_CURRENT_CDE = 'Y'
    AND B.SORLCUR_CACT_CODE = 'ACTIVE'
    AND B.SORLCUR_LMOD_CODE = 'LEARNER')
;

DECLARE
    l_cursor  SYS_REFCURSOR;
BEGIN
    l_cursor := TZKSFEC.F_GET_ESTADOS_DE_CUENTA_1(
        gb_common.f_get_pidm('A00085005'), 'MXN'
    );
    DBMS_SQL.return_result(l_cursor);
END;

SELECT E.SMRPRLE_PROGRAM_DESC, D.*
FROM (
    SELECT a2.SORLCUR_PIDM, a2.SORLCUR_PROGRAM, a2.SORLCUR_PRIORITY_NO
    FROM SORLCUR A2
    WHERE A2.SORLCUR_PIDM = gb_common.f_get_pidm('A00085002')
        AND A2.SORLCUR_CURRENT_CDE = 'Y'
        AND A2.SORLCUR_CACT_CODE = 'ACTIVE'
        AND A2.SORLCUR_LMOD_CODE = 'LEARNER') A,
        (
            SELECT B3.TBRACCD_STSP_KEY_SEQUENCE, A3.*
            FROM 
            (
                SELECT A4.*, B4.TBRAPPL_CHG_TRAN_NUMBER
                FROM 
                    (SELECT A5.TBRACCD_TRAN_NUMBER     AS TRAN_NUMBER_OTRAS,
                        B5.TBRACCD_TRAN_NUMBER     AS TRAN_NUMBER_FICTICIAS,
                        B5.TBRACCD_CROSSREF_NUMBER
                    FROM TBRACCD A5, 
                        (SELECT TBRACCD_CROSSREF_NUMBER, TBRACCD_TRAN_NUMBER
                        FROM TBRACCD
                        WHERE TBRACCD_DETAIL_CODE = 'PPLN'
                            AND tbraccd_pidm = gb_common.f_get_pidm('A00085002') 
                        ) B5
                    WHERE A5.TBRACCD_CROSSREF_NUMBER = B5.TBRACCD_CROSSREF_NUMBER
                        AND A5.TBRACCD_TRAN_NUMBER <> B5.TBRACCD_TRAN_NUMBER
                        AND A5.TBRACCD_DETAIL_CODE = 'PLAN'
                        AND A5.TBRACCD_PIDM = gb_common.f_get_pidm('A00085002'))
                 A4, TBRAPPL B4
                WHERE A4.TRAN_NUMBER_FICTICIAS = B4.TBRAPPL_PAY_TRAN_NUMBER
                    -- AND B4.TBRAPPL_PAY_TRAN_NUMBER = 16
                    AND B4.TBRAPPL_PIDM = gb_common.f_get_pidm('A00085002')
            ) A3, TBRACCD B3
            WHERE A3.TBRAPPL_CHG_TRAN_NUMBER = B3.TBRACCD_TRAN_NUMBER
                -- AND B3.TBRACCD_TRAN_NUMBER = 16
                AND B3.TBRACCD_PIDM = gb_common.f_get_pidm('A00085002')
        ) D,
    SMRPRLE                   E
WHERE SORLCUR_PRIORITY_NO = D.TBRACCD_STSP_KEY_SEQUENCE
    -- AND D.TRAN_NUMBER_OTRAS = 16
    AND A.SORLCUR_PROGRAM = E.SMRPRLE_PROGRAM
;

SELECT *
FROM sovlcur
WHERE sovlcur_pidm = gb_common.f_get_pidm('A00085002')
;

SELECT TO_CHAR(5000, '999,999,999,999')
FROM DUAL;