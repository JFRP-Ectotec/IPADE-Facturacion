-- DROP TYPE TY_TRALIX_LINEA_COMPPAGOS;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_COMPPAGOS UNDER TY_TRALIX_LINEA
(
    idPagos VARCHAR2(50 CHAR),
    versionLinea VARCHAR2(3 CHAR),
    FechaPago DATE,
    FormaPagoP VARCHAR2(10 CHAR),
    MonedaP VARCHAR2(10 CHAR),
    TipoCambioP NUMBER,
    Monto NUMBER,
    NumOperacion VARCHAR2(100 CHAR),
    RfcEmisorCtaOrd VARCHAR2(13 CHAR),
    NomBancoOrdExt VARCHAR2(300 CHAR),
    CtaOrdenante VARCHAR2(50 CHAR),
    RfcEmisorCtaBen VARCHAR2(13 CHAR),
    CtaBeneficiario VARCHAR2(50 CHAR),
    TipoCadPago VARCHAR2(10 CHAR),
    CertPago VARCHAR2(255 CHAR),
    CadPago VARCHAR2(255 CHAR),
    SelloPago VARCHAR2(255 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPPAGOS(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER,
        idPagos VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE REGISTRAR_DEBUG(pic_procedimiento VARCHAR2, pic_texto VARCHAR2),
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPPAGOS AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPPAGOS(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER,
        idPagos VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('compPagos');

        SELF.estatus_debug := 'I';
        SELF.raiz_debug := 'TY_TRALIX_LINEA_COMPPAGOS';

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.versionLinea := '2.0';

        SELF.idPagos := idPagos;
        SELF.FechaPago := SYSDATE;
        SELF.FormaPagoP := formaPago;
        SELF.MonedaP := 'MXN';
        SELF.TipoCambioP := 1;

        FOR k IN (
            SELECT TBRACCM_CURR_CODE
            FROM tbraccm
            WHERE tbraccm_pidm = pidm
                AND TBRACCM_ORIG_TRAN_NUMBER = tranNumberCP
        ) LOOP
            SELF.MonedaP := k.tbraccm_curr_code;
        END LOOP;

        IF (SELF.MonedaP NOT IN ('MXN', 'XXX')) THEN
            FOR j IN 
            (
                SELECT GURCURR_CONV_RATE_INV
                FROM gurcurr
                WHERE gurcurr_curr_code = SELF.MonedaP
                ORDER BY gurcurr_activity_date DESC
            ) LOOP
                SELF.TipoCambioP := j.GURCURR_CONV_RATE_INV;
                EXIT;
            END LOOP;
        END IF;

        FOR i IN (
            -- SELECT t1.tbrappl_amount
            -- FROM tbrappl t1
            -- WHERE t1.tbrappl_pidm = pidm
            --     AND t1.tbrappl_pay_tran_number = tranNumberCP
            --     AND t1.tbrappl_chg_tran_number = tranOriginal
            SELECT t1.tbraccd_amount
            FROM tbraccd t1
            WHERE t1.tbraccd_pidm = pidm
                AND t1.tbraccd_tran_number = tranNumberCP
                -- AND t1.tbraccd_tran_number_paid = tranOriginal
        ) LOOP
            SELF.Monto := i.tbraccd_amount;
        END LOOP;

        RETURN;
    END TY_TRALIX_LINEA_COMPPAGOS;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.sanitizar(SELF.idPagos) || SELF.sep ||
            SELF.sanitizar(SELF.versionLinea) || SELF.sep ||
            SELF.format_fecha(SELF.FechaPago) || SELF.sep ||
            SELF.sanitizar(SELF.FormaPagoP) || SELF.sep ||
            SELF.sanitizar(SELF.MonedaP) || SELF.sep ||
            TO_CHAR(SELF.TipoCambioP) || SELF.sep ||
            SELF.format_moneda(SELF.Monto) || SELF.sep ||
            SELF.sanitizar(SELF.NumOperacion) || SELF.sep ||
            SELF.sanitizar(SELF.RfcEmisorCtaOrd) || SELF.sep ||
            SELF.sanitizar(SELF.NomBancoOrdExt) || SELF.sep ||
            SELF.sanitizar(SELF.CtaOrdenante) || SELF.sep ||
            SELF.sanitizar(SELF.RfcEmisorCtaBen) || SELF.sep ||
            SELF.sanitizar(SELF.CtaBeneficiario) || SELF.sep ||
            SELF.sanitizar(SELF.TipoCadPago) || SELF.sep ||
            SELF.sanitizar(SELF.CertPago) || SELF.sep ||
            SELF.sanitizar(SELF.CadPago) || SELF.sep ||
            SELF.sanitizar(SELF.SelloPago)
        ;
    END imprimir_linea;

    -- MEMBER PROCEDURE validar IS
    -- BEGIN
    --     SELF.INIT_ERRORES;
    --     IF (NVL(SELF.id_archivo, '|') = '|') THEN
    --         SELF.AGREGAR_ERROR('Se debe especificar un identificador de archivo');
    --     END IF;
    -- END validar;
END;

----

-- DROP TYPE TY_TRALIX_LINEA_COMPTOT;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_COMPTOT UNDER TY_TRALIX_LINEA
(
    totRetencionesIVA NUMBER,
    totRetencionesISR NUMBER,
    totRetencionesIEPS NUMBER,
    totTrasladosBaseIVA16 NUMBER,
    totTrasladosImpIVA16 NUMBER,
    totTrasladosBaseIVA8 NUMBER,
    totTrasladosImpIVA8 NUMBER,
    totTrasladosBaseIVA0 NUMBER,
    totTrasladosImpIVA0 NUMBER,
    totTrasladosBaseIVAEx NUMBER,
    montoTotalPagos NUMBER,
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPTOT(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPTOT AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPTOT(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
        totImpuestos NUMBER;
        monto tbraccd.tbraccd_amount%TYPE;
        recibo tbraccd.tbraccd_receipt_number%TYPE;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('compTotales');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.totRetencionesIVA := NULL;
        SELF.totRetencionesISR := NULL;
        SELF.totRetencionesIEPS := NULL;
        SELF.totTrasladosBaseIVA8 := NULL;
        SELF.totTrasladosImpIVA8 := NULL;
        SELF.totTrasladosBaseIVA0 := NULL;
        SELF.totTrasladosImpIVA0 := NULL;
        SELF.totTrasladosBaseIVAEx := NULL;

        /* Obtener monto de la transacción Banner */
        FOR i IN (
            SELECT tbraccd_amount, tbraccd_receipt_number
            INTO monto, recibo
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number = tranNumberCP
        ) LOOP
            monto := i.tbraccd_amount;
            recibo := i.tbraccd_receipt_number;
        END LOOP;
        

        /* Ver si hay impuestos */
        SELECT NVL(SUM(tbraccd_amount), 0)
        INTO totImpuestos
        FROM tbraccd t
        WHERE tbraccd_pidm = pidm
            AND tbraccd_tran_number != tranNumberCP
            AND tbraccd_receipt_number = recibo
            AND tbraccd_detail_code LIKE '%IVA%'
        ;

        SELF.montoTotalPagos := monto;
        IF (NVL(totImpuestos, 0) > 0) THEN
            -- SELF.totTrasladosBaseIVA16 := monto / 1.16;
            SELF.totTrasladosBaseIVA16 := totImpuestos;
            SELF.totTrasladosImpIVA16 := monto - SELF.totTrasladosBaseIVA16;
        END IF;

        IF (NVL(SELF.totTrasladosBaseIVA16, 0) <= 0) THEN
            SELF.totTrasladosBaseIVAEx := monto;
        END IF;

        -- SELF.registrar_debug('TY_TRALIX_LINEA_COMPTOT', 'totalPagos: '||SELF.montoTotalPagos);
        -- SELF.estatus_debug := 'I';

        RETURN;
    END TY_TRALIX_LINEA_COMPTOT;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.format_moneda(SELF.totRetencionesIVA) || SELF.sep ||
            SELF.format_moneda(SELF.totRetencionesISR) || SELF.sep ||
            SELF.format_moneda(SELF.totRetencionesIEPS) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosBaseIVA16) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosImpIVA16) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosBaseIVA8) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosImpIVA8) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosBaseIVA0) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosImpIVA0) || SELF.sep ||
            SELF.format_moneda(SELF.totTrasladosBaseIVAEx) || SELF.sep ||
            SELF.format_moneda(SELF.montoTotalPagos)
        ;
    END imprimir_linea;

    -- MEMBER PROCEDURE validar IS
    -- BEGIN
    --     SELF.INIT_ERRORES;
    --     IF (NVL(SELF.id_archivo, '|') = '|') THEN
    --         SELF.AGREGAR_ERROR('Se debe especificar un identificador de archivo');
    --     END IF;
    -- END validar;
END;

---------

-- DROP TYPE TY_TRALIX_LINEA_COMPDOCTREL;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_COMPDOCTREL UNDER TY_TRALIX_LINEA
(
    idPagos VARCHAR2(50 CHAR),
    uuidPagoOriginal VARCHAR2(36 CHAR),
    serie VARCHAR2(25 CHAR),
    folio VARCHAR2(40 CHAR),
    monedaDR VARCHAR2(10 CHAR),
    equivalenciaDR NUMBER,
    numParcialidad NUMBER,
    impSaldoAnt NUMBER,
    impPagado NUMBER,
    impSaldoInsoluto NUMBER,
    objetoImpDR VARCHAR2(10 CHAR),
    idImpuestoDR VARCHAR2(50 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPDOCTREL(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER,
        idPagos VARCHAR2,
        monedaCP VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPDOCTREL AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPDOCTREL(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER,
        idPagos VARCHAR2,
        monedaCP VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
        saldoPagado NUMBER;
        numParcialidades NUMBER;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('comPagosDoctoRel');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.idPagos := idPagos;
        SELF.idImpuestoDR := idPagos;
        SELF.objetoImpDR := '02';

        /* Determinar moneda del DoctoRel */
        SELF.monedaDR := 'MXN';
        FOR k IN (
            SELECT TBRACCM_CURR_CODE
            FROM tbraccm
            WHERE tbraccm_pidm = pidm
                AND TBRACCM_ORIG_TRAN_NUMBER = tranOriginal
        ) LOOP
            SELF.MonedaDR := k.tbraccm_curr_code;
        END LOOP;

        SELF.equivalenciaDR := 1;
        FOR m IN (
            SELECT NVL(TZRPOFI_PO_OVRD_AMT_1, 1) as equivalencia
            FROM tzrpofi
            WHERE tzrpofi_pidm = pidm
                AND tzrpofi_docnum_pos = tranOriginal
            ORDER BY tzrpofi_activity_date DESC
        ) LOOP
            SELF.equivalenciaDR := m.equivalencia;
        END LOOP;

        /* Determinar equivalencia si son monedas distintas */
        IF (SELF.monedaDR != monedaCP) THEN
            FOR j IN (
                SELECT gurcurr_conv_rate, gurcurr_conv_rate_inv
                FROM gurcurr
                WHERE gurcurr_curr_code = monedaCP 
                ORDER BY gurcurr_activity_date DESC
            ) LOOP
                IF (SELF.monedaDR = 'MXN') THEN
                    SELF.equivalenciaDR := j.gurcurr_conv_rate;
                ELSE
                    SELF.equivalenciaDR := j.gurcurr_conv_rate_inv;
                END IF;
                EXIT;
            END LOOP;
        END IF;

        FOR i IN (
            -- SELECT tbrappl_amount
            -- FROM tbrappl
            -- WHERE tbrappl_pidm = pidm
            --     AND tbrappl_pay_tran_number = tranNumberCP
            --     AND tbrappl_chg_tran_number = tranOriginal
            SELECT tbraccd_amount
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number = tranNumberCP
        ) LOOP
            SELF.impPagado := i.tbraccd_amount * SELF.equivalenciaDR;
        END LOOP;

        dbms_output.put_line('impPagado:'||SELF.impPagado);

        FOR j IN (
            SELECT tbraccd_balance, tbraccd_amount, tbraccd_receipt_number
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number = tranOriginal
        ) LOOP
            -- SELF.impSaldoAnt := j.tbraccd_balance;
            SELF.impSaldoAnt := j.tbraccd_amount;
            -- SELF.impSaldoAnt := SELF.impSaldoAnt + SELF.impPagado; -- Esta suma se hace porque en Banner ya se aplicaron las sumas antes de enviar.

            -- IF (SELF.impSaldoAnt = 0) THEN
            --     SELF.impSaldoAnt := j.tbraccd_amount;
            -- END IF;

            dbms_output.put_line('impSaldoAnt 2:'||SELF.impSaldoAnt);

            /* Ver si hay complementos */
            FOR m IN (
                SELECT NVL(SUM(tc.tbraccd_amount), 0) as parciales
                FROM tvrtsta ta JOIN tzrpofi tz
                    ON (ta.tvrtsta_pidm = tz.tzrpofi_pidm
                        AND ta.tvrtsta_comments = tz.tzrpofi_iac_cde)
                    JOIN tbraccd tc ON (tc.tbraccd_pidm = tz.tzrpofi_pidm
                        AND tc.tbraccd_tran_number = tz.tzrpofi_docnum_pos)
                WHERE ta.tvrtsta_pidm = pidm
                    AND ta.tvrtsta_tran_number = tranOriginal
                    AND REGEXP_LIKE (ta.tvrtsta_tsta_code, 'UI\d')
            ) LOOP
                IF (m.parciales > 0) THEN
                    SELF.impSaldoAnt := SELF.impSaldoAnt - m.parciales;
                END IF;
            END LOOP;

            /* Ver si hay impuestos */
            FOR k IN (
                SELECT NVL(SUM(tbraccd_amount), 0) as impuestos
                FROM tbraccd
                WHERE tbraccd_pidm = pidm
                    AND tbraccd_tran_number != tranOriginal
                    AND tbraccd_receipt_number = j.tbraccd_receipt_number
                    AND tbraccd_detail_code LIKE '%IVA%'
            ) LOOP
                dbms_output.put_line('impuestos:'||k.impuestos);
                IF (k.impuestos > 0) THEN
                    SELF.impSaldoAnt := SELF.impSaldoAnt + k.impuestos;
                    -- SELF.impSaldoAnt := j.tbraccd_balance + k.impuestos;
                END IF;
            END LOOP;
        END LOOP;

        dbms_output.put_line('impSaldoAnt:'||SELF.impSaldoAnt);

        SELECT COUNT(*) + 1
        INTO SELF.numParcialidad
        FROM tvrtsta
        WHERE tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tranOriginal
            AND REGEXP_LIKE (tvrtsta_tsta_code, 'UI\d')
        ;

        -- SELF.numParcialidad := 1;
        -- FOR m IN (
        --     SELECT NVL(SUM(tbraccd_amount), 0) as saldoPagado,
        --         COUNT(*) as numParcialidades
        --     FROM tbraccd
        --     WHERE tbraccd_pidm = pidm
        --         AND tbraccd_tran_number < tranNumberCP
        --         AND tbraccd_tran_number_paid = tranOriginal
        -- ) LOOP
        --     SELF.impSaldoAnt := SELF.impSaldoAnt - m.saldoPagado;
        --     SELF.numParcialidad := m.numParcialidades + 1;
        -- END LOOP;

        SELF.impSaldoInsoluto := NVL(SELF.impSaldoAnt, 0) - NVL(SELF.impPagado, 0);

        FOR k IN (
            SELECT TZRPOFI_IAC_CDE, TZRPOFI_SDOC_CODE,
                TZRPOFI_DOC_NUMBER
            FROM tzrpofi
            WHERE tzrpofi_pidm = pidm
                AND TZRPOFI_DOCNUM_POS = tranOriginal
            ORDER BY tzrpofi_activity_date DESC
        ) LOOP
            SELF.uuidPagoOriginal := k.tzrpofi_iac_cde;
            SELF.serie := k.tzrpofi_sdoc_code;
            SELF.folio := k.tzrpofi_doc_number;
            EXIT;
        END LOOP;

        RETURN;
    END TY_TRALIX_LINEA_COMPDOCTREL;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.sanitizar(SELF.idPagos) || SELF.sep ||
            SELF.sanitizar(SELF.uuidPagoOriginal) || SELF.sep ||
            SELF.sanitizar(SELF.serie) || SELF.sep ||
            SELF.sanitizar(SELF.folio) || SELF.sep ||
            SELF.sanitizar(SELF.monedaDR) || SELF.sep ||
            SELF.equivalenciaDR || SELF.sep ||
            SELF.numParcialidad || SELF.sep ||
            SELF.format_moneda(SELF.impSaldoAnt) || SELF.sep ||
            SELF.format_moneda(SELF.impPagado) || SELF.sep ||
            SELF.format_moneda(SELF.impSaldoInsoluto) || SELF.sep ||
            SELF.sanitizar(SELF.objetoImpDR) || SELF.sep ||
            SELF.sanitizar(SELF.idImpuestoDR) 
        ;
    END imprimir_linea;

    -- MEMBER PROCEDURE validar IS
    -- BEGIN
    --     SELF.INIT_ERRORES;
    --     IF (NVL(SELF.id_archivo, '|') = '|') THEN
    --         SELF.AGREGAR_ERROR('Se debe especificar un identificador de archivo');
    --     END IF;
    -- END validar;
END;

--------

-- DROP TYPE TY_TRALIX_LINEA_IMP_CP;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_IMP_CP UNDER TY_TRALIX_LINEA
(
    idPagos VARCHAR2(50 CHAR),
    baseDR NUMBER,
    impuestoDR VARCHAR2(10 CHAR),
    tipoFactorDR VARCHAR2(10 CHAR),
    tasaCuotaDR NUMBER,
    importeDR NUMBER,
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_IMP_CP(
        tipoFactura VARCHAR2, -- DR (original) o P (complemento)
        pidm NUMBER,
        idPagos VARCHAR2,
        compTotales TY_TRALIX_LINEA_COMPTOT
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_IMP_CP AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_IMP_CP(
        tipoFactura VARCHAR2,
        pidm NUMBER,
        idPagos VARCHAR2,
        compTotales TY_TRALIX_LINEA_COMPTOT
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('comPagosImpTraslados' || tipoFactura);

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.idPagos := idPagos;
        -- SELF.baseDR := monto;
        SELF.impuestoDR := '002';
        -- SELF.importeDR := SELF.baseDR * SELF.tasaCuotaDR;

        IF (NVL(compTotales.totTrasladosBaseIVAEx, -1) < 0) THEN
            SELF.tipoFactorDR := 'Tasa';
            SELF.tasaCuotaDR := 0.16;
            SELF.baseDR := compTotales.totTrasladosBaseIVA16;
            SELF.importeDR := compTotales.totTrasladosImpIVA16;
        ELSE
            SELF.tipoFactorDR := 'Exento';
            SELF.tasaCuotaDR := NULL;
            SELF.baseDR := compTotales.totTrasladosBaseIVAEx;
            SELF.importeDR := NULL;
        END IF;

        RETURN;
    END TY_TRALIX_LINEA_IMP_CP;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.sanitizar(SELF.idPagos) || SELF.sep ||
            SELF.format_moneda(SELF.baseDR) || SELF.sep ||
            SELF.sanitizar(SELF.impuestoDR) || SELF.sep ||
            SELF.sanitizar(SELF.tipoFactorDR) || SELF.sep ||
            TRIM(TO_CHAR(SELF.tasaCuotaDR, '0.009999')) || SELF.sep ||
            SELF.format_moneda(SELF.importeDR)
        ;
    END imprimir_linea;

    -- MEMBER PROCEDURE validar IS
    -- BEGIN
    --     SELF.INIT_ERRORES;
    --     IF (NVL(SELF.id_archivo, '|') = '|') THEN
    --         SELF.AGREGAR_ERROR('Se debe especificar un identificador de archivo');
    --     END IF;
    -- END validar;
END;

-- DROP TYPE TY_TRALIX_ARR_IMP_CP;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_IMP_CP AS TABLE OF TY_TRALIX_LINEA_IMP_CP;

-------

-- DROP TYPE TY_TRALIX_COMPPAGO;

CREATE OR REPLACE TYPE TY_TRALIX_COMPPAGO AS OBJECT
(
    inicio_archivo TY_TRALIX_LINEA_00,
    info_gral_comprobante TY_TRALIX_LINEA_01,
    receptor TY_TRALIX_LINEA_03,
    conceptos TY_TRALIX_ARR_05,
    compPagos TY_TRALIX_LINEA_COMPPAGOS,
    compTotales TY_TRALIX_LINEA_COMPTOT,
    doctoRel TY_TRALIX_LINEA_COMPDOCTREL,
    impuestos_DR TY_TRALIX_ARR_IMP_CP,
    impuestos_P TY_TRALIX_ARR_IMP_CP,
    envio_automatico TY_TRALIX_LINEA_09,
    finCfdi TY_TRALIX_LINEA_99,
    errores TY_TRALIX_ARR_ERROR,
    estatus_debug  VARCHAR2(1 CHAR), --Estatus de debug en GURDBUG D debug, O Output, A Ambos, I Inactivo
	raiz_debug     VARCHAR2(100 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_COMPPAGO(
        matricula VARCHAR2,
        tranNumber NUMBER,
        tranOriginal NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        formaPago VARCHAR2,
        metodoPago VARCHAR2,
        fechaEmision DATE
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE ajustar_pubgral,
    MEMBER PROCEDURE REGISTRAR_DEBUG(pic_procedimiento VARCHAR2, pic_texto VARCHAR2),
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_COMPPAGO AS
    CONSTRUCTOR FUNCTION TY_TRALIX_COMPPAGO(
        matricula VARCHAR2,
        tranNumber NUMBER,
        tranOriginal NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        formaPago VARCHAR2,
        metodoPago VARCHAR2,
        fechaEmision DATE
    ) RETURN SELF AS RESULT IS
        idPagos VARCHAR2(50 CHAR);
        vln_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;
        numLineas NUMBER := 0;
        concepto TY_TRALIX_LINEA_05;
        numGrupo VARCHAR2(1 CHAR);
    BEGIN
        vln_pidm := gb_common.f_get_pidm(matricula);
        SELF.raiz_debug := 'TY_TRALIX_COMPPAGO';

        SELECT COUNT(*)
        INTO numLineas
        FROM tvrtsta
        WHERE tvrtsta_pidm = vln_pidm
            AND tvrtsta_tran_number = tranOriginal
            AND (
                (tvrtsta_tsta_code LIKE 'T0%' AND tvrtsta_dloc_code = 'FA')
                OR (tvrtsta_tsta_code LIKE 'F0%' AND tvrtsta_dloc_code = 'PPD'))
        ;

        IF (numLineas < 2) THEN
            SELF.errores := TY_TRALIX_ARR_ERROR();
            SELF.errores.EXTEND;
            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('La transacción a la que se desea generar complemento no es PPD ni es Factura Anticipada, o no está timbrada en Tralix.');
        
            RETURN;
        END IF;

        numLineas := 0;

        /* TODO: tomar el número de factura asociado al Docto Relacionado */
        idPagos := matricula || '_' || TRIM(TO_CHAR(tranNumber, '000000'));

        SELF.inicio_archivo := ty_tralix_linea_00(idPagos || '.txt', 'PPD');
        numLineas := numLineas + 1;

        FOR j IN (
            SELECT tvrtsta_comments
            FROM tvrtsta
            WHERE tvrtsta_pidm = gb_common.f_get_pidm(matricula)
                AND tvrtsta_tran_number = tranNumber
                AND tvrtsta_tsta_code LIKE 'F0%'
            ORDER BY tvrtsta_tsta_code DESC
        ) LOOP
            idPagos := j.tvrtsta_comments;
            EXIT;
        END LOOP;

        SELF.estatus_debug := 'A';
        SELF.envio_automatico := ty_tralix_linea_09(matricula);
        SELF.registrar_debug('TY_TRALIX_COMPPAGO', SELF.envio_automatico.imprimir_linea);

        IF (NVL(SELF.envio_automatico.eMail, '*') != '*') THEN
            numLineas := numLineas + 1;
            -- SELF.registrar_debug('TY_TRALIX_COMPPAGO', 'numLineas:'||numLineas);
        END IF;
        
        SELF.info_gral_comprobante := ty_tralix_linea_01(vln_pidm, tranNumber, 
            numEntidad, difEmpresa, metodoPago, formaPago, fechaEmision, 'XXX');
        SELF.info_gral_comprobante.metodoPago := '';
        SELF.info_gral_comprobante.formaPago := '';
        SELF.info_gral_comprobante.tipoComprobante := 'P';
        SELF.info_gral_comprobante.subTotalNum := 0;
        SELF.info_gral_comprobante.moneda := 'XXX';
        numLineas := numLineas + 1;

       
        SELF.REGISTRAR_DEBUG('TY_TRALIX_COMPPAGO', SELF.info_gral_comprobante.imprimir_linea);
        -- SELF.estatus_debug := 'I';

        SELF.receptor := ty_tralix_linea_03(vln_pidm, numEntidad);

        -- IF (SELF.receptor.esPubGral = 'TRUE') THEN
        --     SELF.receptor.idParticipante := 'PUBGRAL' || numEntidad;
        -- END IF;
        SELF.receptor.usoCFDI := 'CP01';

        SELF.envio_automatico.idIntReceptor := SELF.receptor.identificador;
        numLineas := numLineas + 1;

        -- SELF.estatus_debug := 'A';
        SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'formaPago: '||formaPago);
        --     ' tranNumber:'||tranNumberCP||' tranNumberOrig:'||tranOriginal);
        -- SELF.estatus_debug := 'I';

        SELF.compPagos := TY_TRALIX_LINEA_COMPPAGOS(vln_pidm, tranNumber, tranOriginal, idPagos, formaPago);
        numLineas := numLineas + 1;

        /* En caso de que sea extranjero con RFC genérico mandar banco de ordenanza */
        SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'rfc: '||SELF.receptor.rfc||' formaPago:'||formaPago);
        IF (SELF.receptor.rfc = 'XEXX010101000' AND formaPago IN ('03', '04', '28', '29')) THEN
            SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'pidm: '||vln_pidm);

            FOR k IN (
                SELECT substr(goradid_adid_code, 1, 1) as NumGrupo
                FROM goradid
                WHERE goradid_pidm = vln_pidm
                    AND goradid_additional_id LIKE '*%'
            ) LOOP
                numGrupo := k.numGrupo;
                SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'numGrupo: '||numGrupo);
                
                FOR j IN (
                    SELECT goradid_additional_id
                    FROM goradid
                    WHERE goradid_pidm = vln_pidm
                        AND goradid_adid_code = numGrupo||'NBO'
                ) LOOP
                    SELF.compPagos.NomBancoOrdExt := j.goradid_additional_id;
                    SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'banco: '||j.goradid_additional_id);
                END LOOP;
            END LOOP;
        END IF;

        SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'bancoExt: '||SELF.compPagos.NomBancoOrdExt);

        SELF.compTotales := TY_TRALIX_LINEA_COMPTOT(vln_pidm, tranNumber, tranOriginal);
        numLineas := numLineas + 1;

        SELF.doctoRel := TY_TRALIX_LINEA_COMPDOCTREL(vln_pidm, tranNumber, tranOriginal, idPagos, SELF.compPagos.MonedaP);
        SELF.registrar_debug('TY_TRALIX_LINEA_COMPPAGO', 'doctoRel: '||SELF.doctoRel.imprimir_linea);
        SELF.estatus_debug := 'I';
        numLineas := numLineas + 1;

        SELF.conceptos := TY_TRALIX_ARR_05();
        -- SELF.conceptos.EXTEND;
        FOR j IN (
            SELECT tbraccd_amount, tbraccd_receipt_number,
                tbraccd_detail_code
            FROM tbraccd
            WHERE tbraccd_pidm = vln_pidm
                AND tbraccd_tran_number = tranNumber
        ) LOOP
            /* Buscar impuestos */
            -- SELECT NVL(SUM(tbraccd_amount), 0),
            --     MAX(tbraccd_detail_code)
            -- INTO vln_sumaImpuestos,
            --     vlc_detalleImp
            -- FROM tbraccd
            -- WHERE tbraccd_pidm = pidm
            --     AND tbraccd_tran_number != tranNumber
            --     AND tbraccd_receipt_number = j.tbraccd_receipt_number
            --     AND tbraccd_srce_code = 'Z';

            concepto := TY_TRALIX_LINEA_05(vln_pidm, tranNumber, 'XXX');
            concepto.clave_servicio := '84111506';
            concepto.descripcion := 'Pago';
            concepto.valorUnitario := 0;
            concepto.importe := 0;
            concepto.ObjetoImp := '01';
            concepto.claveUnidad := 'ACT';  -- Revisar si es el deber ser. TEMPORAL
            -- Considerar modifcar concepto.importe
            
            SELF.conceptos.EXTEND;
            SELF.conceptos(SELF.conceptos.COUNT) := concepto;
        END LOOP;

        SELF.impuestos_DR := TY_TRALIX_ARR_IMP_CP();
        SELF.impuestos_DR.EXTEND;
        SELF.impuestos_DR(SELF.impuestos_DR.COUNT) := TY_TRALIX_LINEA_IMP_CP('DR', vln_pidm, idPagos, SELF.compTotales);

        SELF.impuestos_P := TY_TRALIX_ARR_IMP_CP();
        SELF.impuestos_P.EXTEND;
        SELF.impuestos_P(SELF.impuestos_P.COUNT) := TY_TRALIX_LINEA_IMP_CP('P', vln_pidm, idPagos, SELF.compTotales);

        SELF.errores := TY_TRALIX_ARR_ERROR();

        numLineas := numLineas + SELF.conceptos.COUNT
            + SELF.impuestos_DR.COUNT + SELF.impuestos_P.COUNT;

        SELF.info_gral_comprobante.set_cargos(0, NULL);
        SELF.info_gral_comprobante.tipoCambio := '';

        numLineas := numLineas + 1;
        SELF.finCfdi := ty_tralix_linea_99(numLineas);

        RETURN;
    END TY_TRALIX_COMPPAGO;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
        vlc_respuesta VARCHAR2(4000 CHAR);
    BEGIN
        vlc_respuesta := SELF.inicio_archivo.imprimir_linea || '|' ||
            SELF.info_gral_comprobante.imprimir_linea || '|' ||
            SELF.receptor.imprimir_linea
        ;

        IF (SELF.conceptos.COUNT > 0) THEN
            FOR i IN SELF.conceptos.FIRST .. SELF.conceptos.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.conceptos(i).imprimir_linea;
            END LOOP; 
        END IF;

        vlc_respuesta := vlc_respuesta || '|' ||
            SELF.compPagos.imprimir_linea || '|' ||
            SELF.compTotales.imprimir_linea || '|' ||
            SELF.doctoRel.imprimir_linea
        ;
        
        IF (SELF.impuestos_DR.COUNT > 0) THEN
            FOR j IN SELF.impuestos_DR.FIRST .. SELF.impuestos_DR.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.impuestos_DR(j).imprimir_linea;
            END LOOP; 
        END IF;

        IF (SELF.impuestos_P.COUNT > 0) THEN
            FOR k IN SELF.impuestos_P.FIRST .. SELF.impuestos_P.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.impuestos_P(k).imprimir_linea;
            END LOOP; 
        END IF;

        IF (NVL(SELF.envio_automatico.eMail, '*') != '*') THEN
            vlc_respuesta := vlc_respuesta || '|' ||
                SELF.envio_automatico.imprimir_linea;
        END IF;

        vlc_respuesta := vlc_respuesta || '|' || SELF.finCfdi.imprimir_linea;

        RETURN vlc_respuesta;
    END imprimir_linea;

    MEMBER PROCEDURE ajustar_pubgral IS
    BEGIN
        IF ((SELF.receptor.esPubGral = 'TRUE') AND (SELF.conceptos.COUNT > 0)) THEN
            FOR i IN SELF.conceptos.FIRST .. SELF.conceptos.LAST
            LOOP
                -- SELF.conceptos(i).clave_Servicio := '01010101';
                SELF.conceptos(i).claveUnidad := 'ACT';
                -- SELF.conceptos(i).descripcion := 'PÚBLICO EN GENERAL';
            END LOOP;
        END IF;
    END ajustar_pubgral;

    MEMBER PROCEDURE REGISTRAR_DEBUG(pic_procedimiento VARCHAR2, pic_texto VARCHAR2) IS
    BEGIN
        IF estatus_debug IN ('A','D') THEN
			P_BAN_DEBUG(raiz_debug||pic_procedimiento,pic_texto);
		END IF;
		
		IF estatus_debug IN ('A','O') THEN
			DBMS_OUTPUT.PUT_LINE(pic_procedimiento||' -> '||pic_texto);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
    END REGISTRAR_DEBUG;

    MEMBER PROCEDURE validar IS
    BEGIN
        IF (SELF.errores.COUNT > 0) THEN
            RETURN;
        END IF;
        SELF.errores := TY_TRALIX_ARR_ERROR();
        SELF.inicio_archivo.validar;
        IF (SELF.inicio_archivo.errores.COUNT > 0) THEN
            FOR i IN SELF.inicio_archivo.errores.FIRST .. SELF.inicio_archivo.errores.LAST 
            LOOP
                SELF.errores.EXTEND;
                SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.inicio_archivo.errores(i).mensaje);
            END LOOP;
        END IF;

        SELF.info_gral_comprobante.validar;
        IF (SELF.info_gral_comprobante.errores.COUNT > 0) THEN
            FOR j IN SELF.info_gral_comprobante.errores.FIRST .. SELF.info_gral_comprobante.errores.LAST 
            LOOP
                SELF.errores.EXTEND;
                SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.info_gral_comprobante.errores(j).mensaje);
            END LOOP;
        END IF;

        SELF.receptor.validar;
        IF (SELF.receptor.errores.COUNT > 0) THEN
            FOR k IN SELF.receptor.errores.FIRST .. SELF.receptor.errores.LAST 
            LOOP
                SELF.errores.EXTEND;
                SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.receptor.errores(k).mensaje);
            END LOOP;
        END IF;

        IF (SELF.conceptos.COUNT > 0) THEN
            FOR m IN SELF.conceptos.FIRST .. SELF.conceptos.LAST
            LOOP
                SELF.conceptos(m).validar;
                IF (SELF.conceptos(m).errores.COUNT > 0) THEN
                    FOR n IN SELF.conceptos(m).errores.FIRST .. SELF.conceptos(m).errores.LAST
                    LOOP
                        SELF.errores.EXTEND;
                        SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.conceptos(m).errores(n).mensaje);
                    END LOOP;
                END IF;
            END LOOP;
        ELSE
            SELF.errores.EXTEND;
            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('La transacción no existe en TBRAPPL o TBRACCD');
        END IF;

        IF (SELF.compPagos.Monto < 0) THEN
            SELF.errores.EXTEND;
            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('El monto a registrar del pago no puede ser negativo.');
        END IF;

        IF (NVL(SELF.doctoRel.uuidPagoOriginal, '|') = '|') THEN
            SELF.errores.EXTEND;
            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('La factura anticipada no está timbrada en Tralix.');
        END IF;

        -- IF ((SELF.impuestosTras.COUNT + SELF.impuestosRets.COUNT) > 0) THEN
        -- --     SELF.errores.EXTEND;
        -- --     SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('La transacción no tiene impuestos en TVRFWTX');
        -- -- ELSE
        --     IF (SELF.impuestosTras.COUNT > 0) THEN
        --         FOR p IN SELF.impuestosTras.FIRST .. SELF.impuestosTras.LAST
        --         LOOP
        --             SELF.impuestosTras(p).validar;
        --             IF (SELF.impuestosTras(p).errores.COUNT > 0) THEN
        --                 FOR q IN SELF.impuestosTras(p).errores.FIRST .. SELF.impuestosTras(p).errores.LAST
        --                 LOOP
        --                     SELF.errores.EXTEND;
        --                     SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.impuestosTras(p).errores(1).mensaje);
        --                 END LOOP;
        --             END IF;
        --         END LOOP;
        --     END IF;

        --     IF (SELF.impuestosRets.COUNT > 0) THEN
        --         FOR p IN SELF.impuestosRets.FIRST .. SELF.impuestosRets.LAST
        --         LOOP
        --             SELF.impuestosRets(p).validar;
        --             IF (SELF.impuestosRets(p).errores.COUNT > 0) THEN
        --                 FOR q IN SELF.impuestosRets(p).errores.FIRST .. SELF.impuestosRets(p).errores.LAST
        --                 LOOP
        --                     SELF.errores.EXTEND;
        --                     SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.impuestosRets(p).errores(1).mensaje);
        --                 END LOOP;
        --             END IF;
        --         END LOOP;
        --     END IF;
        -- END IF;
    END validar;
END;

