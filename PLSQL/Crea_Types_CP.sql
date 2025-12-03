DROP TYPE TY_TRALIX_LINEA_COMPPAGOS;

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
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPPAGOS AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPPAGOS(
        pidm NUMBER,
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('compPagos');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.versionLinea := '2.0';

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

DROP TYPE TY_TRALIX_LINEA_COMPTOT;

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
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPTOT AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPTOT(
        pidm NUMBER,
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('compTotales');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

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

DROP TYPE TY_TRALIX_LINEA_COMPDOCTREL;

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
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_COMPDOCTREL AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_COMPDOCTREL(
        pidm NUMBER,
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('comPagosDoctoRel');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

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

DROP TYPE TY_TRALIX_LINEA_IMP_CP;

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
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_IMP_CP AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_IMP_CP(
        tipoFactura VARCHAR2,
        pidm NUMBER,
        tranNumberCP NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('comPagosImpTraslados' || tipoFactura);

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        RETURN;
    END TY_TRALIX_LINEA_IMP_CP;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.idPagos || SELF.sep ||
            SELF.format_moneda(SELF.baseDR) || SELF.sep ||
            SELF.impuestoDR || SELF.sep ||
            SELF.tipoFactorDR || SELF.sep ||
            TO_CHAR(SELF.tasaCuotaDR, '0.009999') || SELF.sep ||
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

DROP TYPE TY_TRALIX_ARR_IMP_CP;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_IMP_CP AS TABLE OF TY_TRALIX_LINEA_IMP_CP;

-------

DROP TYPE TY_TRALIX_COMPPAGO;

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
    CONSTRUCTOR FUNCTION TY_TRALIX_COMPPAGO(
        matricula VARCHAR2,
        tranNumber NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        formaPago VARCHAR2,
        metodoPago VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 /*,
    MEMBER PROCEDURE validar */
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_COMPPAGO AS
    CONSTRUCTOR FUNCTION TY_TRALIX_COMPPAGO(
        matricula VARCHAR2,
        tranNumber NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        formaPago VARCHAR2,
        metodoPago VARCHAR2
    ) RETURN SELF AS RESULT IS
        idPagos VARCHAR2(50 CHAR);
        vln_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;
        numLineas NUMBER := 0;
    BEGIN
        idPagos := matricula || '_' || TRIM(TO_CHAR(tranNumber, '000000'));
        vln_pidm := gb_common.f_get_pidm(matricula);
        SELF.inicio_archivo := ty_tralix_linea_00(idPagos || '.txt');
        numLineas := numLineas + 1;

        SELF.envio_automatico := ty_tralix_linea_09(matricula);
        -- numLineas := numLineas + 1;

        SELF.info_gral_comprobante := ty_tralix_linea_01(vln_pidm, tranNumber, 
            numEntidad, difEmpresa, metodoPago, formaPago);
        SELF.info_gral_comprobante.metodoPago := '';
        numLineas := numLineas + 1;
        SELF.receptor := ty_tralix_linea_03(vln_pidm, numEntidad);

        IF (SELF.receptor.esPubGral = 'TRUE') THEN
            SELF.receptor.idParticipante := 'PUBGRAL' || numEntidad;
        END IF;

        SELF.envio_automatico.idIntReceptor := SELF.receptor.identificador;
        numLineas := numLineas + 1;

        SELF.compPagos := TY_TRALIX_LINEA_COMPPAGOS(vln_pidm, tranNumber);
        numLineas := numLineas + 1;

        SELF.compTotales := TY_TRALIX_LINEA_COMPTOT(vln_pidm, tranNumber);
        numLineas := numLineas + 1;

        SELF.doctoRel := TY_TRALIX_LINEA_COMPDOCTREL(vln_pidm, tranNumber);
        numLineas := numLineas + 1;

        SELF.conceptos := TY_TRALIX_ARR_05();
        SELF.impuestos_DR := TY_TRALIX_ARR_IMP_CP();
        SELF.impuestos_P := TY_TRALIX_ARR_IMP_CP();
        SELF.errores := TY_TRALIX_ARR_ERROR();

        numLineas := numLineas + SELF.conceptos.COUNT
            + SELF.impuestos_DR.COUNT + SELF.impuestos_P.COUNT;

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

        vlc_respuesta := vlc_respuesta || '|' ||
            SELF.compPagos.imprimir_linea || '|' ||
            SELF.compTotales.imprimir_linea || '|' ||
            SELF.doctoRel.imprimir_linea
        ;

        IF (SELF.conceptos.COUNT > 0) THEN
            FOR i IN SELF.conceptos.FIRST .. SELF.conceptos.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.conceptos(i).imprimir_linea;
            END LOOP; 
        END IF;

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

    -- MEMBER PROCEDURE validar IS
    -- BEGIN
    --     SELF.INIT_ERRORES;
    --     IF (NVL(SELF.id_archivo, '|') = '|') THEN
    --         SELF.AGREGAR_ERROR('Se debe especificar un identificador de archivo');
    --     END IF;
    -- END validar;
END;