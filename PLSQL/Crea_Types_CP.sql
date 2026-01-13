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
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE REGISTRAR_DEBUG(pic_procedimiento VARCHAR2, pic_texto VARCHAR2) /*,
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
                AND t1.tbraccd_tran_number_paid = tranOriginal
        ) LOOP
            SELF.Monto := i.tbraccd_amount;
        END LOOP;

        RETURN;
    END TY_TRALIX_LINEA_COMPPAGOS;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.idPagos || SELF.sep ||
            SELF.versionLinea || SELF.sep ||
            SELF.format_fecha(SELF.FechaPago) || SELF.sep ||
            SELF.FormaPagoP || SELF.sep ||
            SELF.MonedaP || SELF.sep ||
            SELF.TipoCambioP || SELF.sep ||
            SELF.format_moneda(SELF.Monto) || SELF.sep ||
            SELF.NumOperacion || SELF.sep ||
            SELF.RfcEmisorCtaOrd || SELF.sep ||
            SELF.NomBancoOrdExt || SELF.sep ||
            SELF.CtaOrdenante || SELF.sep ||
            SELF.RfcEmisorCtaBen || SELF.sep ||
            SELF.CtaBeneficiario || SELF.sep ||
            SELF.TipoCadPago || SELF.sep ||
            SELF.CertPago || SELF.sep ||
            SELF.CadPago || SELF.sep ||
            SELF.SelloPago
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
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('compTotales');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.totRetencionesIVA := 0;
        SELF.totRetencionesISR := 0;
        SELF.totRetencionesIEPS := 0;
        SELF.totTrasladosBaseIVA8 := 0;
        SELF.totTrasladosImpIVA8 := 0;
        SELF.totTrasladosBaseIVA0 := 0;
        SELF.totTrasladosImpIVA0 := 0;
        SELF.totTrasladosBaseIVAEx := 0;

        FOR i IN (
            SELECT tbrappl_amount
            FROM tbrappl
            WHERE tbrappl_pidm = pidm
                AND tbrappl_pay_tran_number = tranNumberCP
                AND tbrappl_chg_tran_number = tranOriginal
        ) LOOP
            SELF.totTrasladosBaseIVA16 := i.tbrappl_amount;
            SELF.totTrasladosImpIVA16 := i.tbrappl_amount * 0.16;
        END LOOP;

        -- SELF.estatus_debug := 'A';
        -- SELF.registrar_debug('TY_TRALIX_LINEA_COMPTOT', 'pidm: '||pidm||
        --     ' tranNumber:'||tranNumberCP||' tranNumberOrig:'||tranOriginal);
        

        IF (NVL(SELF.totTrasladosBaseIVA16, 0) <= 0) THEN
            FOR j IN (
                SELECT tbraccd_amount
                FROM tbraccd
                WHERE tbraccd_pidm = pidm
                    AND tbraccd_tran_number = tranNumberCP
                    AND tbraccd_tran_number_paid = tranOriginal
            ) LOOP

                SELF.totTrasladosBaseIVA16 := j.tbraccd_amount;
                SELF.totTrasladosImpIVA16 := j.tbraccd_amount * 0.16;

                -- SELF.registrar_debug('TY_TRALIX_LINEA_COMPTOT', 'totTraslados: '||SELF.totTrasladosBaseIVA16);
            END LOOP;
        END IF;

        SELF.montoTotalPagos := NVL(SELF.totTrasladosBaseIVA16, 0)
            + NVL(SELF.totTrasladosBaseIVA8, 0)
            + NVL(SELF.totTrasladosBaseIVA0, 0)
            + NVL(SELF.totTrasladosBaseIVAEx, 0)
        ;

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
        idPagos VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPDOCTREL AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPDOCTREL(
        pidm NUMBER,
        tranNumberCP NUMBER,
        tranOriginal NUMBER,
        idPagos VARCHAR2
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
        SELF.objetoImpDR := '002';

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
            SELF.impPagado := i.tbraccd_amount;
        END LOOP;

        FOR j IN (
            SELECT tbraccd_amount
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number = tranOriginal
        ) LOOP
            SELF.impSaldoAnt := j.tbraccd_amount;
        END LOOP;

        SELF.numParcialidad := 1;
        FOR m IN (
            SELECT NVL(SUM(tbrappl_amount), 0) as saldoPagado,
                COUNT(*) as numParcialidades
            FROM tbrappl
            WHERE tbrappl_pidm = pidm
                AND tbrappl_chg_tran_number = tranOriginal
                AND tbrappl_pay_tran_number < tranNumberCP
        ) LOOP
            SELF.impSaldoAnt := SELF.impSaldoAnt - m.saldoPagado;
            SELF.numParcialidad := m.numParcialidades + 1;
        END LOOP;

        SELF.impSaldoInsoluto := SELF.impSaldoAnt - SELF.impPagado;

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

        SELF.monedaDR := 'MXN';  /* TEMPORAL */

        RETURN;
    END TY_TRALIX_LINEA_COMPDOCTREL;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.idPagos || SELF.sep ||
            SELF.uuidPagoOriginal || SELF.sep ||
            SELF.serie || SELF.sep ||
            SELF.folio || SELF.sep ||
            SELF.monedaDR || SELF.sep ||
            SELF.equivalenciaDR || SELF.sep ||
            SELF.numParcialidad || SELF.sep ||
            SELF.format_moneda(SELF.impSaldoAnt) || SELF.sep ||
            SELF.format_moneda(SELF.impPagado) || SELF.sep ||
            SELF.format_moneda(SELF.impSaldoInsoluto) || SELF.sep ||
            SELF.objetoImpDR || SELF.sep ||
            SELF.idImpuestoDR 
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
        monto NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_IMP_CP AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_IMP_CP(
        tipoFactura VARCHAR2,
        pidm NUMBER,
        idPagos VARCHAR2,
        monto NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('comPagosImpTraslados' || tipoFactura);

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.idPagos := idPagos;
        SELF.baseDR := monto;
        SELF.impuestoDR := '002';
        SELF.tipoFactorDR := 'Tasa';
        SELF.tasaCuotaDR := 0.16;
        SELF.importeDR := SELF.baseDR * SELF.tasaCuotaDR;

        RETURN;
    END TY_TRALIX_LINEA_IMP_CP;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.idPagos || SELF.sep ||
            SELF.format_moneda(SELF.baseDR) || SELF.sep ||
            SELF.impuestoDR || SELF.sep ||
            SELF.tipoFactorDR || SELF.sep ||
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
        metodoPago VARCHAR2
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
        metodoPago VARCHAR2
    ) RETURN SELF AS RESULT IS
        idPagos VARCHAR2(50 CHAR);
        vln_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;
        numLineas NUMBER := 0;
        concepto TY_TRALIX_LINEA_05;
    BEGIN
        idPagos := matricula || '_' || TRIM(TO_CHAR(tranNumber, '000000'));
        vln_pidm := gb_common.f_get_pidm(matricula);
        SELF.inicio_archivo := ty_tralix_linea_00(idPagos || '.txt', 'PPD');
        numLineas := numLineas + 1;

        SELF.envio_automatico := ty_tralix_linea_09(matricula);

        IF (NVL(SELF.envio_automatico.eMail, '*') != '*') THEN
            numLineas := numLineas + 1;
            -- SELF.registrar_debug('TY_TRALIX_COMPPAGO', 'numLineas:'||numLineas);
        END IF;
        
        SELF.info_gral_comprobante := ty_tralix_linea_01(vln_pidm, tranNumber, 
            numEntidad, difEmpresa, metodoPago, formaPago);
        SELF.info_gral_comprobante.metodoPago := '';
        SELF.info_gral_comprobante.formaPago := '';
        SELF.info_gral_comprobante.tipoComprobante := 'P';
        SELF.info_gral_comprobante.subTotalNum := 0;
        numLineas := numLineas + 1;
        SELF.receptor := ty_tralix_linea_03(vln_pidm, numEntidad);

        IF (SELF.receptor.esPubGral = 'TRUE') THEN
            SELF.receptor.idParticipante := 'PUBGRAL' || numEntidad;
        END IF;

        SELF.envio_automatico.idIntReceptor := SELF.receptor.identificador;
        numLineas := numLineas + 1;

        SELF.compPagos := TY_TRALIX_LINEA_COMPPAGOS(vln_pidm, tranNumber, tranOriginal, idPagos, formaPago);
        numLineas := numLineas + 1;

        SELF.compTotales := TY_TRALIX_LINEA_COMPTOT(vln_pidm, tranNumber, tranOriginal);
        numLineas := numLineas + 1;

        SELF.doctoRel := TY_TRALIX_LINEA_COMPDOCTREL(vln_pidm, tranNumber, tranOriginal, idPagos);
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

            concepto := TY_TRALIX_LINEA_05(vln_pidm, tranNumber);
            concepto.valorUnitario := 0;
            concepto.importe := 0;
            concepto.claveUnidad := 'ACT';  -- Revisar si es el deber ser. TEMPORAL
            -- Considerar modifcar concepto.importe
            
            SELF.conceptos.EXTEND;
            SELF.conceptos(SELF.conceptos.COUNT) := concepto;
        END LOOP;

        SELF.impuestos_DR := TY_TRALIX_ARR_IMP_CP();
        SELF.impuestos_DR.EXTEND;
        SELF.impuestos_DR(SELF.impuestos_DR.COUNT) := TY_TRALIX_LINEA_IMP_CP('DR', vln_pidm, idPagos, SELF.doctorel.impSaldoAnt);

        SELF.impuestos_P := TY_TRALIX_ARR_IMP_CP();
        SELF.impuestos_P.EXTEND;
        SELF.impuestos_P(SELF.impuestos_P.COUNT) := TY_TRALIX_LINEA_IMP_CP('P', vln_pidm, idPagos, SELF.compTotales.montoTotalPagos);

        SELF.errores := TY_TRALIX_ARR_ERROR();

        numLineas := numLineas + SELF.conceptos.COUNT
            + SELF.impuestos_DR.COUNT + SELF.impuestos_P.COUNT;

        SELF.info_gral_comprobante.set_cargos(0, NULL);

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
                SELF.conceptos(i).clave_Servicio := '01010101';
                SELF.conceptos(i).claveUnidad := 'ACT';
                SELF.conceptos(i).descripcion := 'PÚBLICO EN GENERAL';
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