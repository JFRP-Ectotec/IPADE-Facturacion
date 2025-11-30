SELECT *
FROM spriden 
WHERE spriden_id = 'A00010105'
;

SELECT sp.*, st.stvstat_desc, sy.stvcnty_desc, sn.stvnatn_nation
FROM spraddr sp
    LEFT JOIN stvstat st ON (sp.spraddr_stat_code = st.stvstat_code)
    LEFT JOIN stvcnty sy ON (sp.spraddr_cnty_code = sy.stvcnty_code)
    LEFT JOIN stvnatn sn ON (sp.spraddr_natn_code = sn.stvnatn_code)
WHERE spraddr_pidm = 30114
;

SELECT *
FROM GORADID
WHERE goradid_pidm = c
;

SELECT vr.* /*,
    substr(x1.sorxref_edi_qlfr, 3, 1) as empresa */
FROM sovlcur vr 
    JOIN spriden sp ON (vr.sovlcur_pidm = sp.spriden_pidm)
    JOIN stvcamp c ON (vr.sovlcur_camp_code = c.stvcamp_code)
--    LEFT JOIN sorxref x1 ON (vr.sovlcur_program = x1.sorxref_banner_value)
WHERE sp.spriden_id = 'A00010133'
    AND sp.spriden_change_ind IS NULL
    AND vr.sovlcur_lmod_code = sb_curriculum_str.f_learner
--    and x1.sorxref_xlbl_code = 'IPADEEM'
;

SELECT DISTINCT t.tbrappl_pidm, t.tbrappl_pay_tran_number, 
    t.tbrappl_chg_tran_number,
    t.tbrappl_amount,
    t2.TVRFWTX_FW_AMOUNT,
    t2.TVRFWTX_ORIG_AMOUNT,
    t2.TVRFWTX_FW_DETAIL_CODE
FROM tbrappl t
    JOIN TVRFWTX t2 ON (t.tbrappl_pidm = t2.tvrfwtx_pidm
        AND t.tbrappl_pay_tran_number = t2.TVRFWTX_ORIG_TRAN_NUMBER)
    JOIN sovlcur vr ON (t.tbrappl_pidm = vr.sovlcur_pidm)
;

SELECT DISTINCT t.tbrappl_pay_tran_number,
    t.tbrappl_amount,
    t2.TVRFWTX_FW_AMOUNT,
    t2.TVRFWTX_ORIG_AMOUNT,
    t2.TVRFWTX_FW_DETAIL_CODE
FROM tbrappl t
    JOIN TVRFWTX t2 ON (t.tbrappl_pidm = t2.tvrfwtx_pidm
        AND t.tbrappl_pay_tran_number = t2.TVRFWTX_ORIG_TRAN_NUMBER)
WHERE t.tbrappl_pidm = 30143
    AND t.tbrappl_chg_tran_number = 7
;

SELECT t.tbraccd_amount,
              t.tbraccd_detail_code,
              td.tbbdetc_desc
            FROM tbraccd t
                JOIN tbbdetc td ON (t.tbraccd_detail_code = td.tbbdetc_detail_code)
            WHERE t.tbraccd_pidm = 30143
                AND t.tbraccd_tran_number = 3
;

SELECT * FROM tvrfwtx
WHERE tvrfwtx_pidm = 30143
;

SELECT DISTINCT t.tbrappl_chg_tran_number, 
    t.tbrappl_amount,
    t2.TVRFWTX_FW_AMOUNT,
    t2.TVRFWTX_ORIG_AMOUNT,
    t2.TVRFWTX_FW_DETAIL_CODE
FROM tbrappl t
    JOIN TVRFWTX t2 ON (t.tbrappl_pidm = t2.tvrfwtx_pidm
        AND t.tbrappl_pay_tran_number = t2.TVRFWTX_ORIG_TRAN_NUMBER)
WHERE t.tbrappl_pidm = 30143
    AND t.tbrappl_pay_tran_number = 3
ORDER BY t.tbrappl_chg_tran_number;

SELECT t.tbraccd_amount,
    t.tbraccd_detail_code,
    td.tbbdetc_desc
FROM tbraccd t
    JOIN tbbdetc td ON (t.tbraccd_detail_code = td.tbbdetc_detail_code)
WHERE t.tbraccd_pidm = 30143
    AND t.tbraccd_tran_number = 3;

SELECT *
FROM spriden 
WHERE spriden_pidm = 30143
;

DECLARE
   l_response VARCHAR2(2000 CHAR);
   campoUUID VARCHAR2(100 CHAR) := '"uuid":';
   l_indice NUMBER := 0;
   l_ind_fin NUMBER := 0;
BEGIN
    l_response := '"uuid":"E36A1678-EAFF-4207-A37C-570658AC7368","fecha":"2025-09-17 12:34:53.0","serie":"","folio":"","rfc":"","iva":"","monto":""';
    l_indice := INSTR(l_response, campoUUID);
    l_ind_fin := INSTR(l_response, ',', l_indice);

    DBMS_OUTPUT.PUT_LINE(l_indice || ' - ' || l_ind_fin);
    DBMS_OUTPUT.PUT_LINE(SUBSTR(l_response, l_indice + LENGTH(campoUUID) + 1, l_ind_fin - (l_indice + LENGTH(campoUUID) + 2)));
END;


DECLARE
    l_response CLOB;
BEGIN
    l_response := TZTRALX.crea_objeto_sust_tralix('FOL1', 'FOL2', '02', 1);
    DBMS_OUTPUT.PUT_LINE(l_response);
END;

SELECT gb_common.f_get_pidm('LENNON') FROM dual;

SELECT DISTINCT t.tbrappl_pay_tran_number, 
    t.tbrappl_amount,
    t2.TVRFWTX_FW_AMOUNT,
    t2.TVRFWTX_ORIG_AMOUNT,
    t2.TVRFWTX_FW_DETAIL_CODE
FROM tbrappl t
    LEFT JOIN TVRFWTX t2 ON (t.tbrappl_pidm = t2.tvrfwtx_pidm
        AND t.tbrappl_pay_tran_number = t2.TVRFWTX_ORIG_TRAN_NUMBER)
WHERE t.tbrappl_pidm = 30711
    AND t.tbrappl_chg_tran_number = 12
    AND t.tbrappl_amount != t2.TVRFWTX_FW_AMOUNT
;

SELECT *
FROM tbrappl
WHERE tbrappl_pidm = 30711
;

SELECT *
FROM tvrfwtx 
WHERE tvrfwtx_pidm = 30711
;

SELECT t.*
FROM tbrappl t JOIN spriden s ON (t.tbrappl_pidm = s.spriden_pidm)
WHERE s.spriden_id = 'A00023057'
    AND s.spriden_change_ind IS NULL
;

SELECT DISTINCT t.tbrappl_pay_tran_number, 
    t.tbrappl_amount,
    t.tbrappl_chg_tran_number /*,
    t2.TVRFWTX_FW_AMOUNT,
    t2.TVRFWTX_ORIG_AMOUNT,
    t2.TVRFWTX_FW_DETAIL_CODE*/
FROM tbrappl t
    /*LEFT JOIN TVRFWTX t2 ON (t.tbrappl_pidm = t2.tvrfwtx_pidm
        AND t.tbrappl_pay_tran_number = t2.TVRFWTX_ORIG_TRAN_NUMBER)*/
WHERE t.tbrappl_pidm = 104663
    -- AND t.tbrappl_chg_tran_number = 13
--    AND t.tbrappl_amount != t2.TVRFWTX_FW_AMOUNT
;

SELECT s.spriden_id, s.spriden_pidm,
    t.tbraccd_tran_number, t.tbraccd_detail_code, t.tbraccd_amount
FROM tbraccd t
    JOIN tbbdetc d ON (t.tbraccd_detail_code = d.tbbdetc_detail_code)
    JOIN spriden s ON (t.tbraccd_pidm = s.spriden_pidm)
WHERE d.tbbdetc_dcat_code = 'CSH'
  AND s.spriden_change_ind IS NULL
;