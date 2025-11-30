DROP TYPE TY_TRALIX_REGTSTA;

CREATE OR REPLACE TYPE TY_TRALIX_REGTSTA AS OBJECT
(
    factura VARCHAR2(50 CHAR),
    sociedad VARCHAR2(50 CHAR),
    regFiscal VARCHAR2(50 CHAR),
    uuid VARCHAR2(50 CHAR),
    fechaVenc DATE,
    usoCfdi VARCHAR2(50 CHAR),
    formaPago VARCHAR2(5 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_REGTSTA(
        factura VARCHAR2,
        sociedad VARCHAR2,
        regFiscal VARCHAR2,
        uuid VARCHAR2,
        fechaVenc DATE,
        usoCfdi VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_REGTSTA AS
    CONSTRUCTOR FUNCTION TY_TRALIX_REGTSTA(
        factura VARCHAR2,
        sociedad VARCHAR2,
        regFiscal VARCHAR2,
        uuid VARCHAR2,
        fechaVenc DATE,
        usoCfdi VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        SELF.factura := factura;
        SELF.sociedad := sociedad;
        SELF.regFiscal := regFiscal;
        SELF.fechaVenc := fechaVenc;
        SELF.uuid := uuid;
        SELF.usoCfdi := usoCfdi;
        SELF.formaPago := formaPago;

        RETURN;
    END TY_TRALIX_REGTSTA;
END;
