WITH PARAMETROS AS
       (SELECT gb_common.f_get_pidm('A00084990')        AS PIDM,
               'MXN' AS DIVISA,
               'RFC'        AS STATUS_UIP
          FROM DUAL),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --INICIO PROCESO DE EXTRACCIÓN DE IMPUESTOS CON ID PROGRAMA------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --AQUI VAMOS A OBTENER EL O LOS PROGRAMAS DEL ALUMNO
      PROGRAMAS_DEL_ALUMNO AS
       (SELECT SORLCUR_PIDM, SORLCUR_PROGRAM, SORLCUR_PRIORITY_NO
          FROM SORLCUR A, PARAMETROS PRM
         WHERE A.SORLCUR_PIDM = PRM.PIDM
           AND A.SORLCUR_CURRENT_CDE = 'Y'
           AND A.SORLCUR_CACT_CODE = 'ACTIVE'
           AND A.SORLCUR_LMOD_CODE = 'LEARNER'
        
        UNION
        
        SELECT SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1, B.SORLCUR_PRIORITY_NO
          FROM SGBSTDN A, SORLCUR B, PARAMETROS PRM
         WHERE A.SGBSTDN_PIDM = PRM.PIDM
           AND A.SGBSTDN_TERM_CODE_EFF =
               (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                  FROM SGBSTDN B
                 WHERE B.SGBSTDN_PIDM = A.SGBSTDN_PIDM)
              
           AND A.SGBSTDN_PROGRAM_1 = B.SORLCUR_PROGRAM
              
           AND B.SORLCUR_PIDM = A.SGBSTDN_PIDM
           AND B.SORLCUR_CURRENT_CDE = 'Y'
           AND B.SORLCUR_CACT_CODE = 'ACTIVE'
           AND B.SORLCUR_LMOD_CODE = 'LEARNER'),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --EL CRUCE DEL PROGRAMA DEL ALUMNO CON LAS REGLAS DE CRUCE DEL RÉGIMEN FISCAL 
      --(RÉGIMEN FISCAL O TIPO DE IMPUESTO)
      CODE_TAX_DEL_PROGRAMA AS
       (SELECT A.SORXREF_BANNER_VALUE, B.*
          FROM SORXREF A, PROGRAMAS_DEL_ALUMNO B
         WHERE A.SORXREF_EDI_QLFR = B.SORLCUR_PROGRAM
           AND A.SORXREF_XLBL_CODE = 'IMPUESTO'),
      --*****************************************************************************
      --*****************************************************************************
      --*****************************************************************************
      --*****************************************************************************
      --*****************************************************************************
      --*****************************************************************************
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --SIMPLEMENTE CRUZAMOS LOS IMPUESTOS CON EL O LOS PROGRAMAS EXISTENTES
      IMPUESTOS_DEL_PROGRAMA AS
       (SELECT A.TVRTXPR_CODE,
               A.TVRTXPR_DATE_FROM,
               A.TVRTXPR_DATE_TO,
               B.SORLCUR_PROGRAM,
               B.SORLCUR_PRIORITY_NO
          FROM TVRTXPR A, CODE_TAX_DEL_PROGRAMA B
         WHERE A.TVRTXPR_CODE = B.SORXREF_BANNER_VALUE
           AND A.TVRTXPR_TAX_ESTIMATION_MODE = 'F'),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS LA FECHA MÁS RECIENTE DE CADA GRUPO DE IMPUESTOS QUE SALGAN DEL O
      --LOS PROGRAMAS EXISTENTES
      TAX_AGRUPADO_Y_MAX_DATE_FROM AS
       (SELECT A.TVRTXPR_CODE, MAX(A.TVRTXPR_DATE_FROM) AS TVRTXPR_DATE_FROM
          FROM IMPUESTOS_DEL_PROGRAMA A
         GROUP BY A.TVRTXPR_CODE),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS LOS IMPUESTOS O CÓDIGOS DE IMPUESTOS QUE SE TIENEN  DEL O LOS
      --PROGRAMAS PERO SÓLO EL REGISTRO MÁS RECIENTE DE CADA GRUPO QUE PUEDA EXISTIR
      IMPUESTO_MAS_RECIENTE AS
       (SELECT A.TVRTXPR_CODE,
               A.TVRTXPR_DATE_FROM,
               A.TVRTXPR_DATE_TO,
               A.SORLCUR_PROGRAM,
               A.SORLCUR_PRIORITY_NO
          FROM IMPUESTOS_DEL_PROGRAMA A, TAX_AGRUPADO_Y_MAX_DATE_FROM B
         WHERE A.TVRTXPR_CODE = B.TVRTXPR_CODE
           AND A.TVRTXPR_DATE_FROM = B.TVRTXPR_DATE_FROM),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --LA SIGUINETE CONSULTA ES LA REGLA PARA PODER OBTENER EL REGISTRO DONDE: LA
      --FECHA DEL CAMPO 'TVRTXPR_DATE_TO' SEA NULA PERO SI NO SALE NINGÚN REGISTRO POR
      --QUE EL CAMPO 'TVRTXPR_DATE_TO' TIENE UNA FECHA ENTONCES SE APLICA OTRA REGLA
      --Y ES QUE LA FECHA ACTUAL ESTÉ ENTRE EL VALOR DEL CAMPO 'TVRTXPR_DATE_FROM' AND
      --'TVRTXPR_DATE_TO' 
      TAX_DATE_IS_NULL_OR_BETWEEN AS
       (SELECT *
          FROM IMPUESTO_MAS_RECIENTE
         WHERE TVRTXPR_DATE_TO IS NULL
            OR (SYSDATE BETWEEN TVRTXPR_DATE_FROM AND TVRTXPR_DATE_TO)),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --AQUÍ SÓLO VAMOS A RECUPERAR LOS REGISTROS CON EL CÓDIGO DE IMPUESTO DE ACUERO
      --AL PARÁMETRO DE ENTRADA PARA LA TABLA 'TVRTPDC'
      DETALLE_DEL_IMPUESTO AS
       (SELECT /*+ INDEX(A)*/
         A.TVRTPDC_TXPR_CODE,
         A.TVRTPDC_DETC_CODE,
         A.TVRTPDC_DATE_FROM,
         A.TVRTPDC_PERCENT,
         B.SORLCUR_PRIORITY_NO
          FROM TVRTPDC                     A,
               CODE_TAX_DEL_PROGRAMA       B,
               TAX_DATE_IS_NULL_OR_BETWEEN C
         WHERE A.TVRTPDC_TXPR_CODE = B.SORXREF_BANNER_VALUE
           AND A.TVRTPDC_DATE_FROM = C.TVRTXPR_DATE_FROM
           AND B.SORLCUR_PRIORITY_NO = C.SORLCUR_PRIORITY_NO
           AND A.TVRTPDC_BASE_AMOUNT = 'B'),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --AQUI VAMOS A CRUZAR LA SUBCONSULTA 'TAX_DATE_IS_NULL_OR_BETWEEN' (QUE
      --REPRESENTA LA TABLA 'TVRTXPR') JUNTO CON LA SUBCONSULTA 'DETALLE_DEL_IMPUESTO'
      --(QUE REPRESENTA LA TABLA 'TVRTPDC') PARA OBTENER EL PORCENTAJE DE IMPUESTO
      --QUE SE NECESITA
      PORCENTAJE_DE_IMPUESTO AS
       (SELECT A.SORLCUR_PROGRAM,
               A.SORLCUR_PRIORITY_NO,
               B.TVRTPDC_TXPR_CODE,
               B.TVRTPDC_DETC_CODE,
               B.TVRTPDC_PERCENT
          FROM TAX_DATE_IS_NULL_OR_BETWEEN A, DETALLE_DEL_IMPUESTO B
         WHERE A.TVRTXPR_CODE = B.TVRTPDC_TXPR_CODE
           AND A.TVRTXPR_DATE_FROM = B.TVRTPDC_DATE_FROM
           AND A.SORLCUR_PRIORITY_NO = B.SORLCUR_PRIORITY_NO),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --EL CRUCE DE LAS REGLAS DEL RÉGIMEN FISCAL CON EL PORCENTAJE DEL CÓDIGO DEL
      --IMPUESTO
      PORCENTAJE_A_APLICAR AS
       (SELECT A.TVRTPDC_TXPR_CODE,
               A.TVRTPDC_PERCENT,
               A.SORLCUR_PROGRAM,
               A.SORLCUR_PRIORITY_NO
          FROM PORCENTAJE_DE_IMPUESTO A, CODE_TAX_DEL_PROGRAMA B
         WHERE A.TVRTPDC_TXPR_CODE = B.SORXREF_BANNER_VALUE
           AND A.SORLCUR_PRIORITY_NO = B.SORLCUR_PRIORITY_NO),
      --SELECT * FROM PORCENTAJE_A_APLICAR
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --INICIO PROCESO DE EXTRACCIÓN DE TRANSACCIONES CON ID PROGRAMA--------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS TODAS LAS TRANSACCIONES DEL ALUMNO (TODAS)
      TBRACCD_T AS
       (SELECT A.*
          FROM TBRACCD A, PARAMETROS PRM
         WHERE A.TBRACCD_PIDM = PRM.PIDM),
      ------INICIO-------------------------PASO FALTANTE PARA LAS REFERENCIAS CURZADAS***************************************************
      TBRAPPL_T AS
       (SELECT *
          FROM TBRAPPL A, PARAMETROS PRM
         WHERE A.TBRAPPL_PIDM = PRM.PIDM),
      TRANSCACIONES_FICTICIAS AS
       (SELECT TBRACCD_CROSSREF_NUMBER, TBRACCD_TRAN_NUMBER
          FROM TBRACCD_T A
         WHERE A.TBRACCD_DETAIL_CODE = 'PPLN'),
      TRANS_FICTI_Y_LAS_OTRAS_TRANS AS
       (SELECT A.TBRACCD_TRAN_NUMBER     AS TRAN_NUMBER_OTRAS,
               B.TBRACCD_TRAN_NUMBER     AS TRAN_NUMBER_FICTICIAS,
               B.TBRACCD_CROSSREF_NUMBER
          FROM TBRACCD_T A, TRANSCACIONES_FICTICIAS B
         WHERE A.TBRACCD_CROSSREF_NUMBER = B.TBRACCD_CROSSREF_NUMBER
           AND A.TBRACCD_TRAN_NUMBER <> B.TBRACCD_TRAN_NUMBER
           AND A.TBRACCD_DETAIL_CODE = 'PLAN'),
      OTRAS_TRAN_CON_TRAN_FICTICIAS AS
       (SELECT A.*, B.TBRAPPL_CHG_TRAN_NUMBER
          FROM TRANS_FICTI_Y_LAS_OTRAS_TRANS A, TBRAPPL_T B
         WHERE A.TRAN_NUMBER_FICTICIAS = B.TBRAPPL_PAY_TRAN_NUMBER),
      TRANSACCIONES_CON_ID_PLAN AS
       (SELECT B.TBRACCD_STSP_KEY_SEQUENCE, A.*
          FROM OTRAS_TRAN_CON_TRAN_FICTICIAS A, TBRACCD_T B
         WHERE A.TBRAPPL_CHG_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER),
      TRAN_CON_IMPUESTO_Y_PROGRAMA AS
       (SELECT B.*, A.TRAN_NUMBER_OTRAS
          FROM TRANSACCIONES_CON_ID_PLAN A, PORCENTAJE_DE_IMPUESTO B
         WHERE A.TBRACCD_STSP_KEY_SEQUENCE = B.SORLCUR_PRIORITY_NO),
      ------FINAL-------------------------PASO FALTANTE PARA LAS REFERENCIAS CURZADAS***************************************************
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS SÓLO LOS REGISROS CON CATEGORÍA 'INS'
      --DE LA TABLA DE DEFINICIÓN DE CARGOS/PAGOS
      TBBDETC_T AS
       (SELECT TBBDETC_DCAT_CODE, TBBDETC_DETAIL_CODE, TBBDETC_TYPE_IND
          FROM TBBDETC
        --WHERE TBBDETC_DCAT_CODE = 'INS'
        ),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS LAS TRANSACCIONES ORIGINALES (LAS TRANSACCIONES DE "TIPO" 'PPLN')
      --NORMALMENTE SÓLO VIENE UN REGISTRO.. PERO PUEDEN VENIR MUCHOS MÁS
      TRANSACCIONES_ORIGINALES AS
       (SELECT /*+ INDEX(A)*/
         B.TBRACCD_CROSSREF_NUMBER,
         C.TBRAPPL_CHG_TRAN_NUMBER,
         C.TBRAPPL_REAPPL_IND,
         A.TBBDETC_DCAT_CODE
          FROM TBBDETC_T A, TBRACCD_T B, TBRAPPL C
         WHERE A.TBBDETC_DETAIL_CODE = B.TBRACCD_DETAIL_CODE
           AND B.TBRACCD_PIDM = C.TBRAPPL_PIDM
           AND C.TBRAPPL_REAPPL_IND IS NULL
        --AND A.TBBDETC_TYPE_IND = 'P'
        ), --PAGO
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS TODAS LAS TRANSACCIONES DE TIPO CARGO, DEACUERDO A LA TRANSACCIÓN
      --ORIGINAL Y CUYO NÚMERO DE REFERENCIA CRUZADO TIENEN LOS DEMÁS CARGOS
      --LOS DEMÁS CARGOS PUEDEN SER DE "TIPO" 'PLAN'
      TRANSACCIONES_ORIGINALES_CROSS AS
       (SELECT A.TBRACCD_CROSSREF_NUMBER,
               A.TBBDETC_DCAT_CODE,
               B.TBRACCD_STSP_KEY_SEQUENCE
          FROM TRANSACCIONES_ORIGINALES A, TBRACCD_T B
         WHERE A.TBRAPPL_CHG_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --A LAS TRANSACCIONES ANTERIORES SE LES INCORPORA EN OTRA COLUMNA EL ID DEL
      --PROGRAMA O PLAN DE ESTUDIOS
      TRASNSACCIONES_CON_ID_PLANES AS
       (SELECT B.TBRACCD_TRAN_NUMBER,
               C.TBRACCD_STSP_KEY_SEQUENCE,
               C.TBBDETC_DCAT_CODE
          FROM TBBDETC_T A, TBRACCD_T B, TRANSACCIONES_ORIGINALES_CROSS C
         WHERE A.TBBDETC_DETAIL_CODE = B.TBRACCD_DETAIL_CODE
           AND B.TBRACCD_CROSSREF_NUMBER = C.TBRACCD_CROSSREF_NUMBER
        --AND A.TBBDETC_TYPE_IND = 'C' --CARGO
        --AND B.TBRACCD_BALANCE > 0
        ),
      --SELECT * FROM TRASNSACCIONES_CON_ID_PLANES
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --INICIO PROCESO DE CRUCE DE TRANSACCIONES, IMPUESTOS Y PROGRAMAS------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      TRANS_TAX_AND_PROGRAMS_CROSS AS
       (SELECT B.TBRACCD_TRAN_NUMBER,
               A.TVRTPDC_PERCENT,
               A.SORLCUR_PROGRAM,
               B.TBRACCD_STSP_KEY_SEQUENCE,
               B.TBBDETC_DCAT_CODE
          FROM PORCENTAJE_A_APLICAR A, TRASNSACCIONES_CON_ID_PLANES B
         WHERE A.SORLCUR_PRIORITY_NO = B.TBRACCD_STSP_KEY_SEQUENCE),
      --SELECT * FROM TRANS_TAX_AND_PROGRAMS_CROSS
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --INICIO PROCESO DE ESTADO DE CUENTA-----------------------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS LA INFORMACIÓN DEL ESTATUS DE LAS TRANSACCIONES DEL ALUMNO
      TVRTSTA_T AS
       (SELECT B.*
          FROM TVRTSTA B, PARAMETROS PRM
         WHERE B.TVRTSTA_PIDM = PRM.PIDM),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --AGRUPAMOS LAS TRANSACCIONES ANTERIORES POR SI EXISTEN MULTIPLICIDAD
      --Y SELECCIONAMOS LA SECUENCIA MÁS GRANDE (EN EL REQUERIMIENTO SE PIDE LA FECHA)
      --PERO LAS FECHAS PUEDEN SER LAS MISMAS EN CUANTO A DIA, MES, HORA, MINUTO Y
      --SEGUNDO; POR ELLO SE TOMA LA SECUENCIA
      TVRTSTA_AGRUPADOS AS
       (SELECT TVRTSTA_PIDM,
               TVRTSTA_TRAN_NUMBER,
               MAX(TVRTSTA_SEQ_NO) AS TVRTSTA_SEQ_NO
          FROM TVRTSTA_T A
         WHERE REGEXP_LIKE(TVRTSTA_TSTA_CODE, '^F0[0-9]')
            OR REGEXP_LIKE(TVRTSTA_TSTA_CODE, '^CA[0-9]')
         GROUP BY TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --SE CALCULA EL NÚMERO DE FACTURA
      TVRTSTA_CON_NUMERO_FACTURA AS
       (SELECT TVRTSTA_PIDM,
               TVRTSTA_TRAN_NUMBER,
               TVRTSTA_SEQ_NO,
               TVRTSTA_TSTA_CODE,
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
          FROM TVRTSTA_T A),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --SE CRUZAN LOS REGISTROS QUE TIENEN EL PROCESO DE LA CREACIÓN DEL NÚMERO DE
      --FACTURA CON LAS TRANSACCIONES AGRUPADAS.
      ULTIMA_FACTURA AS
       (SELECT A.TVRTSTA_PIDM,
               A.TVRTSTA_TRAN_NUMBER,
               A.TVRTSTA_COMMENTS,
               A.TVRTSTA_TSTA_CODE
          FROM TVRTSTA_CON_NUMERO_FACTURA A, TVRTSTA_AGRUPADOS B
         WHERE A.TVRTSTA_PIDM = B.TVRTSTA_PIDM
           AND A.TVRTSTA_TRAN_NUMBER = B.TVRTSTA_TRAN_NUMBER
           AND A.TVRTSTA_SEQ_NO = B.TVRTSTA_SEQ_NO),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTENEMOS LA INFORMACIÓN DE LA DIVISA DE CADA TYRANSACCIÓN DE UN ALUMNO
      --POARA POSTERIROMENTE UTILIZAR ESTA SUB-CONSULTA EN LA CONSULTA PRINCIPAL
      TBRACCM_T AS
       (SELECT *
          FROM TBRACCM A, PARAMETROS PRM
         WHERE A.TBRACCM_PIDM = PRM.PIDM),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --CONSULTA FIJA PARA LOS VALORES DE LAS TRANSACCIOENS CON 'CLIP'; VALORES QUE
      --SE COMPARARÁN CON EL CAMPO 'TBRACCD_DETC_CODE'
      CODIGOS_CLIP AS
       (SELECT 'S1M4' AS TBRACCD_DETAIL_CODE
          FROM DUAL
        UNION
        SELECT 'I1M4'
          FROM DUAL
        UNION
        SELECT 'SDM4'
          FROM DUAL
        UNION
        SELECT 'IDM4'
          FROM DUAL),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --LOS VALORES QUE SE UTITLIZARÁN PARA COMPARAR EL VALOR DEL CAMPO 
      --'TVRPAYS_STATUS' Y COLOCAR LOS ESTATUS EN ESPAÑOL
      CODIGOS_DE_ESTATUS_EN_ESPANIOL AS
       (SELECT 'S' AS TVRPAYS_STATUS, 'Enviado' AS TVRPAYS_DESC
          FROM DUAL
        UNION
        SELECT 'P', 'Pendiente'
          FROM DUAL
        UNION
        SELECT 'A', 'Aprobación'
          FROM DUAL
        UNION
        SELECT 'F', 'Fallido'
          FROM DUAL
        UNION
        SELECT 'R', 'Rechazado'
          FROM DUAL
        UNION
        SELECT 'E', 'Expirado'
          FROM DUAL
        UNION
        SELECT 'N', 'Error de conexión'
          FROM DUAL),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --OBTGENEMOS LAS TRANSACCIONES QUE SE PRESENTARÁN EN EL APLICATIVO
      --AQUÍ ES DONDE SE COLOCA EL PROCESO PARA OBTENER EL PORCENTAJE DE IMPUESTO
      --DE CADA TRANSACCIÓN
      ESTADOS_DE_CUENTA AS
       (SELECT TBRACCD_TRAN_NUMBER AS NUMERO_TRANSACCION,
               TBRACCD_STSP_KEY_SEQUENCE,
               TBRACCD_CROSSREF_NUMBER,
               
               TBRACCD_TERM_CODE AS PERIODO,
               TBRACCD_DETAIL_CODE AS CODIGO,
               TBRACCD_DESC AS DESCRIPCION,
               ((SELECT GURCURR_CURR_CODE
                   FROM TABLE(TZKSFEC.F_GET_ULTIMO_REGISTRO_DIVISA((SELECT TBRACCM_CURR_CODE
                                                                     FROM TBRACCM    D,
                                                                          PARAMETROS PRM
                                                                    WHERE TBRACCM_PIDM =
                                                                          PRM.PIDM
                                                                      AND TBRACCM_ORIG_TRAN_NUMBER =
                                                                          B.TBRACCD_TRAN_NUMBER
                                                                      AND TBRACCM_DETAIL_CODE =
                                                                          B.TBRACCD_DETAIL_CODE
                                                                    ORDER BY TBRACCM_ACTIVITY_DATE DESC FETCH FIRST 1 ROW ONLY))))) AS DIVISA,
               
               (CASE
                 WHEN C.TBBDETC_TYPE_IND = 'C' THEN
                  TBRACCD_AMOUNT
               END) AS CARGO,
               
               (CASE
                 WHEN C.TBBDETC_TYPE_IND = 'P' THEN
                  TBRACCD_AMOUNT
               END) AS PAGO,
               
               ROUND(TBRACCD_BALANCE *
                     ((SELECT GURCURR_CONV_RATE_INV
                         FROM TABLE(TZKSFEC.F_GET_ULTIMO_REGISTRO_DIVISA((SELECT TBRACCM_CURR_CODE
                                                                           FROM TBRACCM    D,
                                                                                PARAMETROS PRM
                                                                          WHERE TBRACCM_PIDM =
                                                                                PRM.PIDM
                                                                            AND TBRACCM_ORIG_TRAN_NUMBER =
                                                                                B.TBRACCD_TRAN_NUMBER
                                                                            AND TBRACCM_DETAIL_CODE =
                                                                                B.TBRACCD_DETAIL_CODE
                                                                          ORDER BY TBRACCM_ACTIVITY_DATE DESC FETCH FIRST 1 ROW ONLY))))),
                     2) AS BALANCE,
               
               TBRACCD_EFFECTIVE_DATE AS FECHA_VENCIMIENTO,
               
               (SELECT C.TVRTSTA_TSTA_CODE
                  FROM ULTIMA_FACTURA C
                 WHERE C.TVRTSTA_PIDM = B.TBRACCD_PIDM
                   AND C.TVRTSTA_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER) AS ESTATUS,
               
               (SELECT C.TVRTSTA_COMMENTS
                  FROM ULTIMA_FACTURA C
                 WHERE C.TVRTSTA_PIDM = B.TBRACCD_PIDM
                   AND C.TVRTSTA_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER) AS NUMERO_DE_FACTURA,
               
               (SELECT LISTAGG(C.TZRPOFI_IAC_CDE, ',') WITHIN GROUP(ORDER BY C.TZRPOFI_PIDM, C.TZRPOFI_SDOC_CODE /*|| '-'*/ || TZRPOFI_DOC_NUMBER, C.TZRPOFI_DOC_NUMBER) AS RAZON_SOCIAL
                  FROM TZRPOFI C, ULTIMA_FACTURA D
                 WHERE C.TZRPOFI_PIDM = D.TVRTSTA_PIDM
                   AND C.TZRPOFI_DOCNUM_POS = D.TVRTSTA_TRAN_NUMBER
                      -- AND C.TZRPOFI_SDOC_CODE || '-' || TZRPOFI_DOC_NUMBER =
                   AND C.TZRPOFI_SDOC_CODE || TZRPOFI_DOC_NUMBER = /* Ajuste por cambio en como se guarda en TVRTSTA */
                       D.TVRTSTA_COMMENTS
                      
                   AND C.TZRPOFI_PIDM = B.TBRACCD_PIDM
                   AND C.TZRPOFI_DOCNUM_POS = B.TBRACCD_TRAN_NUMBER) AS DESCARGA_FACTURA, --por el momento Joel comentó que van a revisar esta parte con cliente pero por el momento dejo cómo lo comentan en el documento
               
               NVL((SELECT LISTAGG(C.TZRPOFI_EXP_PDF_LBL_1, ',') WITHIN GROUP(ORDER BY C.TZRPOFI_PIDM, C.TZRPOFI_SDOC_CODE || '-' || TZRPOFI_DOC_NUMBER, C.TZRPOFI_DOC_NUMBER) AS RAZON_SOCIAL
                  FROM TZRPOFI C, ULTIMA_FACTURA D
                 WHERE C.TZRPOFI_PIDM = D.TVRTSTA_PIDM
                   AND C.TZRPOFI_DOCNUM_POS = D.TVRTSTA_TRAN_NUMBER
                   AND C.TZRPOFI_SDOC_CODE || '-' || TZRPOFI_DOC_NUMBER =
                       D.TVRTSTA_COMMENTS
                      
                   AND C.TZRPOFI_PIDM = B.TBRACCD_PIDM
                   AND C.TZRPOFI_DOCNUM_POS = B.TBRACCD_TRAN_NUMBER), 
                   (
                    SELECT LISTAGG(TZRPOFI_EXP_PDF_LBL_1, ',') WITHIN GROUP(ORDER BY tzrpofi_pidm, tzrpofi_docnum_pos)
                    FROM tzrpofi
                    WHERE tzrpofi_pidm = B.TBRACCD_PIDM
                        AND tzrpofi_docnum_pos = B.TBRACCD_TRAN_NUMBER
                   )
                   ) AS ID_EMPRESA, --EALG
               
               TBRACCD_RECEIPT_NUMBER,
               
               (SELECT LISTAGG(GORADID_ADDITIONAL_ID, ',') WITHIN GROUP(ORDER BY C.GORADID_PIDM, C.GORADID_ADDITIONAL_ID, C.GORADID_ADID_CODE)
                  FROM GORADID C, PARAMETROS PRM
                 WHERE GORADID_PIDM = B.TBRACCD_PIDM
                   AND GORADID_ADID_CODE = PRM.STATUS_UIP) AS GORADID_ADDITIONAL_ID,
               
               TBRACCD_DOCUMENT_NUMBER,
               
               CASE
                 WHEN TBRACCD_DETAIL_CODE IN
                      (SELECT TBRACCD_DETAIL_CODE FROM CODIGOS_CLIP) THEN
                  TBRACCD_DOCUMENT_NUMBER
                 ELSE
                  TBRACCD_CARD_AUTH_NUMBER_VR
               END TBRACCD_CARD_AUTH_NUMBER_VR,
               
               (SELECT NVL(MAX(NVL(TVRPAYS_DESC, 'Estatus desconocido')),
                           'Sin estatus')
                  FROM (SELECT TVRPAYS_STATUS
                          FROM TVRPAYS C
                         WHERE C.TVRPAYS_PIDM = B.TBRACCD_PIDM
                              --AND C.TVRPAYS_AMOUNT = B.TBRACCD_AMOUNT
                              --AND C.TVRPAYS_RECEIPT_NUM = B.TBRACCD_RECEIPT_NUMBER
                           AND C.TVRPAYS_BANK_TRAN_ID =
                               TO_CHAR(B.TBRACCD_TRAN_NUMBER) --ESTA CONDICIÓN QUEDA PENDIENTE E INCLUSIVE, POR LO QUE REVISAMOS EN LA REUNIÓN DE SEGUIMIENTO DEL 10 DE SEPTIEMBRE, AÚN REVISARÁ JOEL SI HAY MÁS TABLAS INVOLUCRADAS
                        ) E,
                       CODIGOS_DE_ESTATUS_EN_ESPANIOL D
                 WHERE E.TVRPAYS_STATUS =
                       UPPER(SUBSTR(D.TVRPAYS_STATUS, 1, 1))) AS TVRPAYS_STATUS,
               
               TO_CHAR(TBRACCD_AMOUNT, '999,999,999.00') AS TOTAL,
               
               NVL((SELECT LISTAGG(A.SORLCUR_PROGRAM, ',') WITHIN GROUP(ORDER BY B.TBRACCD_TRAN_NUMBER)
                     FROM PROGRAMAS_DEL_ALUMNO      A,
                          TRANSACCIONES_CON_ID_PLAN D
                    WHERE SORLCUR_PRIORITY_NO = D.TBRACCD_STSP_KEY_SEQUENCE
                      AND D.TRAN_NUMBER_OTRAS = B.TBRACCD_TRAN_NUMBER),

                   NVL(
                    (SELECT DISTINCT SORLCUR_PROGRAM
                      FROM SORLCUR A, PARAMETROS PRM
                     WHERE A.SORLCUR_PIDM = B.TBRACCD_PIDM
                       AND A.SORLCUR_KEY_SEQNO = B.TBRACCD_STSP_KEY_SEQUENCE
                       AND A.SORLCUR_PIDM = PRM.PIDM), 
                       
                       (
                        SELECT DISTINCT SORLCUR_PROGRAM
                        FROM SORLCUR A, PARAMETROS PRM, TBRAPPL_T C, TBRACCD_T D
                        WHERE A.SORLCUR_PIDM = B.TBRACCD_PIDM
                            AND C.TBRAPPL_PAY_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER
                            AND C.TBRAPPL_CHG_TRAN_NUMBER = D.TBRACCD_TRAN_NUMBER
                            AND A.SORLCUR_KEY_SEQNO = D.TBRACCD_STSP_KEY_SEQUENCE
                            AND A.SORLCUR_PIDM = PRM.PIDM
                       )
                       )) AS PROGRAMA,
               
               NVL((SELECT LISTAGG(E.SMRPRLE_PROGRAM_DESC, ',') WITHIN GROUP(ORDER BY B.TBRACCD_TRAN_NUMBER)
                     FROM PROGRAMAS_DEL_ALUMNO      A,
                          TRANSACCIONES_CON_ID_PLAN D,
                          SMRPRLE                   E
                    WHERE SORLCUR_PRIORITY_NO = D.TBRACCD_STSP_KEY_SEQUENCE
                      AND D.TRAN_NUMBER_OTRAS = B.TBRACCD_TRAN_NUMBER
                      AND A.SORLCUR_PROGRAM = E.SMRPRLE_PROGRAM),
                   
                  NVL( (SELECT DISTINCT SMRPRLE_PROGRAM_DESC
                      FROM SMRPRLE F, SORLCUR A, PARAMETROS PRM
                     WHERE F.SMRPRLE_PROGRAM = A.SORLCUR_PROGRAM
                       AND A.SORLCUR_PIDM = B.TBRACCD_PIDM
                       AND A.SORLCUR_KEY_SEQNO = B.TBRACCD_STSP_KEY_SEQUENCE
                       AND A.SORLCUR_PIDM = PRM.PIDM),
                       (
                        SELECT DISTINCT e.smrprle_program_desc
                        FROM SORLCUR A, PARAMETROS PRM, TBRAPPL_T C, TBRACCD_T D, smrprle e
                        WHERE A.SORLCUR_PIDM = B.TBRACCD_PIDM
                            AND C.TBRAPPL_PAY_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER
                            AND C.TBRAPPL_CHG_TRAN_NUMBER = D.TBRACCD_TRAN_NUMBER
                            AND A.SORLCUR_KEY_SEQNO = D.TBRACCD_STSP_KEY_SEQUENCE
                            AND A.SORLCUR_PIDM = PRM.PIDM
                            AND a.sorlcur_program = e.smrprle_program
                       )
                       )) AS DESC_PROGRAMA,
               
               TBBDETC_DCAT_CODE,
               
               TBBDETC_DCAT_CODE AS CODIGO_CATEGORIA
        
          FROM TBRACCD_T B, TBBDETC_T C
         WHERE B.TBRACCD_DETAIL_CODE = C.TBBDETC_DETAIL_CODE
           AND B.TBRACCD_AMOUNT > 0),
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      --------------------------------------------------------------------------------
      ESTADO_DE_CUENTA AS
       (SELECT A.*,
               PRM.DIVISA AS DIVISA_1,
               
               NVL(TZKSFEC.F_GET_EMPRESA_DEL_PROGRAMA(PROGRAMA,
                                                  TBBDETC_DCAT_CODE),
                TZKSFEC.F_GET_EMPRESA_FACTURA(PRM.PIDM, A.NUMERO_TRANSACCION)) AS EMPRESA,
               
               (SELECT LISTAGG(B.TVRTPDC_DETC_CODE, ',') WITHIN GROUP(ORDER BY A.NUMERO_TRANSACCION)
                  FROM TRAN_CON_IMPUESTO_Y_PROGRAMA B
                 WHERE B.TRAN_NUMBER_OTRAS = A.NUMERO_TRANSACCION) AS TIPO_IMPUESTO
        
          FROM ESTADOS_DE_CUENTA A, PARAMETROS PRM
         WHERE A.DIVISA = PRM.DIVISA
         ORDER BY NUMERO_TRANSACCION DESC, FECHA_VENCIMIENTO DESC)
      SELECT * FROM ESTADO_DE_CUENTA
      ;
  

SELECT *
FROM tbrappl
WHERE tbrappl_pidm = gb_common.f_get_pidm('A00084990') 
    AND tbrappl_pay_tran_number = 24
;

SELECT tbraccd_pidm, tbraccd_tran_number, tbraccd_stsp_key_sequence
FROM tbraccd
WHERE tbraccd_pidm = gb_common.f_get_pidm('A00084990')
  AND tbraccd_tran_number = 19
;

SELECT DISTINCT SORLCUR_PROGRAM
                        FROM SORLCUR A, PARAMETROS PRM, TBRAPPL_T C, TBRACCD_T D
                        WHERE A.SORLCUR_PIDM = B.TBRACCD_PIDM
                            AND C.TBRAPPL_PAY_TRAN_NUMBER = B.TBRACCD_TRAN_NUMBER
                            AND C.TBRAPPL_CHG_TRAN_NUMBER = D.TBRACCD_TRAN_NUMBER
                            AND A.SORLCUR_KEY_SEQNO = D.TBRACCD_STSP_KEY_SEQUENCE
                            AND A.SORLCUR_PIDM = PRM.PIDM