DROP TYPE TY_TRALIX_REGTSTA;

CREATE OR REPLACE TYPE TY_TRALIX_REGTSTA AS OBJECT
(
    factura VARCHAR2(50 CHAR),
    sociedad VARCHAR2(50 CHAR),
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
        uuid VARCHAR2,
        fechaVenc DATE,
        usoCfdi VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        SELF.factura := factura;
        SELF.sociedad := sociedad;
        SELF.fechaVenc := fechaVenc;
        SELF.uuid := uuid;
        SELF.usoCfdi := usoCfdi;
        SELF.formaPago := formaPago;

        RETURN;
    END TY_TRALIX_REGTSTA;
END;

DROP TYPE TY_TRALIX_TSTA_OBJ;

CREATE OR REPLACE TYPE TY_TRALIX_TSTA_OBJ as object
(
    codigo VARCHAR2(3 CHAR),
    dLocCode VARCHAR2(3 CHAR),
    valor VARCHAR2(100 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_TSTA_OBJ(
        codigo VARCHAR2,
        dLocCode VARCHAR2,
        valor VARCHAR2
    ) RETURN SELF AS RESULT
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_TSTA_OBJ AS
    CONSTRUCTOR FUNCTION TY_TRALIX_TSTA_OBJ(
        codigo VARCHAR2,
        dLocCode VARCHAR2,
        valor VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        SELF.codigo := codigo;
        SELF.dLocCode := dLocCode;
        SELF.valor := valor;
        
        RETURN;
    END TY_TRALIX_TSTA_OBJ;
END;

DROP TYPE TY_TRALIX_TSTA_ARR;

CREATE OR REPLACE TYPE TY_TRALIX_TSTA_ARR AS TABLE OF TY_TRALIX_TSTA_OBJ;