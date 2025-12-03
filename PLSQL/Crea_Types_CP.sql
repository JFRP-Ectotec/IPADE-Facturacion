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
        RETURN SELF.tipo_registro || SELF.sep ||
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
        RETURN SELF.tipo_registro || SELF.sep ||
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
        RETURN SELF.tipo_registro || SELF.sep ||
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
        RETURN SELF.tipo_registro || SELF.sep ||
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
