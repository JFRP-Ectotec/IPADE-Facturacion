DROP TYPE TY_TRALIX_ROW_ERROR;

CREATE OR REPLACE TYPE TY_TRALIX_ROW_ERROR AS OBJECT
(
    mensaje VARCHAR2(4000 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_ROW_ERROR(
        mensaje VARCHAR2
    ) RETURN SELF AS RESULT
) NOT FINAL INSTANTIABLE
;

CREATE OR REPLACE TYPE BODY TY_TRALIX_ROW_ERROR AS
    CONSTRUCTOR FUNCTION TY_TRALIX_ROW_ERROR(
        mensaje VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        SELF.mensaje := mensaje;
        RETURN;
    END TY_TRALIX_ROW_ERROR;
END;

DROP TYPE TY_TRALIX_ARR_ERROR;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_ERROR AS TABLE OF TY_TRALIX_ROW_ERROR;

DROP TYPE TY_TRALIX_LINEA;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA AS OBJECT
(
    tipo_registro VARCHAR2(30 CHAR),
    sep VARCHAR2(1 CHAR),
    errores TY_TRALIX_ARR_ERROR,
    estatus_debug  VARCHAR2(1 CHAR), --Estatus de debug en GURDBUG D debug, O Output, A Ambos, I Inactivo
	raiz_debug     VARCHAR2(100 CHAR),
    MEMBER PROCEDURE INIT(tipo_registro VARCHAR2),
    MEMBER FUNCTION FORMAT_FECHA(pid_fecha DATE) RETURN VARCHAR2,
    MEMBER FUNCTION FORMAT_MONEDA(pin_cantidad NUMBER) RETURN VARCHAR2,
    MEMBER PROCEDURE INIT_ERRORES,
    MEMBER PROCEDURE AGREGAR_ERROR(pic_mensaje VARCHAR2),
    MEMBER PROCEDURE REGISTRAR_DEBUG(pic_procedimiento VARCHAR2, pic_texto VARCHAR2)
) NOT FINAL INSTANTIABLE;

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA AS
    MEMBER PROCEDURE INIT(tipo_registro VARCHAR2) IS
    BEGIN
        SELF.tipo_registro := tipo_registro;
        SELF.sep := '|';
        SELF.errores := TY_TRALIX_ARR_ERROR();
        SELF.estatus_debug := 'I';
    END INIT;

    MEMBER FUNCTION FORMAT_FECHA(pid_fecha DATE) 
    RETURN VARCHAR2 IS
        vlc_fecha VARCHAR2(30 CHAR);
    BEGIN
        IF pid_fecha IS NULL THEN
            RETURN '';
        ELSE
            vlc_fecha := TO_CHAR(pid_fecha, 'YYYY-MM-DD')||'T'||
                TO_CHAR(pid_fecha, 'HH24:MI:SS');
            RETURN vlc_fecha;
        END IF;
    END FORMAT_FECHA;

    MEMBER FUNCTION FORMAT_MONEDA(pin_cantidad NUMBER) 
    RETURN VARCHAR2 IS
    BEGIN
        IF (pin_cantidad = 0) THEN
            RETURN '0';
        ELSIF (NVL(pin_cantidad, 0) = 0) THEN
            RETURN '';
        ELSE
            RETURN TRIM(TO_CHAR(pin_cantidad, '9999999990.00'));
        END IF;
    END FORMAT_MONEDA;

    MEMBER PROCEDURE INIT_ERRORES IS
    BEGIN
        SELF.errores := TY_TRALIX_ARR_ERROR();
    END INIT_ERRORES;

    MEMBER PROCEDURE AGREGAR_ERROR(pic_mensaje VARCHAR2) IS
    BEGIN
        SELF.errores.EXTEND;
        SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(pic_mensaje);
    END AGREGAR_ERROR;

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
END;

-----------

-- DROP TYPE TY_TRALIX_LINEA_00;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_00 UNDER TY_TRALIX_LINEA
(
    id_archivo VARCHAR2(50 CHAR),
    etiqueta_pantalla VARCHAR2(3 CHAR),
    fact_version VARCHAR2(5 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_00(
        id_archivo VARCHAR2,
        etiqueta_pantalla VARCHAR2 DEFAULT 'FAC'
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_00 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_00(
        id_archivo VARCHAR2,
        etiqueta_pantalla VARCHAR2 DEFAULT 'FAC'
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('00');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.id_archivo := id_archivo;
        SELF.etiqueta_pantalla := etiqueta_pantalla;
        SELF.fact_version := '4.0';
        RETURN;
    END TY_TRALIX_LINEA_00;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN SELF.tipo_registro || SELF.sep ||
            SELF.id_archivo || SELF.sep ||
            SELF.etiqueta_pantalla || SELF.sep ||
            SELF.fact_version
        ;
    END imprimir_linea;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        IF (NVL(SELF.id_archivo, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Se debe especificar un identificador de archivo');
        END IF;
    END validar;
END;

---------------

-- DROP TYPE TY_TRALIX_LINEA_01;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_01 UNDER TY_TRALIX_LINEA
(
    cfdi VARCHAR2(100 CHAR),
    serie VARCHAR2(25 CHAR),
    folio VARCHAR2(40 CHAR),
    fecha DATE,
    subTotalNum NUMBER(10, 2),
    totalNum NUMBER(10, 2),
    taxesTrasladados NUMBER(10, 2),
    taxesRetenidos NUMBER(10, 2),
    descuento NUMBER(10, 2),
    motivoDescuento VARCHAR2(256 CHAR),
    totalLetra VARCHAR2(256 CHAR),
    moneda VARCHAR2(10 CHAR),
    tipoCambio NUMBER(10, 2),
    referencia VARCHAR2(256 CHAR),
    nota1 VARCHAR2(512 CHAR),
    nota2 VARCHAR2(512 CHAR),
    nota3 VARCHAR2(512 CHAR),
    tipoComprobante VARCHAR2(30 CHAR),
    metodoPago VARCHAR2(30 CHAR),
    lugarExpedicion VARCHAR2(30 CHAR),
    confirmacion VARCHAR2(5 CHAR),
    formaPago VARCHAR2(50 CHAR),
    condicionesPago VARCHAR2(1000 CHAR),
    exportacion VARCHAR2(30 CHAR),
    facAtrAdquirente VARCHAR2(10 CHAR),

    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_01(
        pidm NUMBER,
        tranNumber NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        metodoPago VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER PROCEDURE set_cargos(cargos NUMBER, imp_ret NUMBER),
    MEMBER PROCEDURE set_folio(serie VARCHAR2, folio VARCHAR2),
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_01 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_01(
        pidm NUMBER,
        tranNumber NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        metodoPago VARCHAR2,
        formaPago VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
        contNota NUMBER := 1;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('01');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;
        SELF.moneda := 'MXN';      -- Consultar catalogo c_Moneda
        SELF.metodoPago := metodoPago;  -- Consultar catalogo c_MetodoPago
        SELF.exportacion := '01';  -- Consultar catalogo c_Exportacion
        SELF.tipoComprobante := 'I';
        self.formaPago := formaPago;

        FOR q IN (
            SELECT sr.spraddr_zip
            FROM spraddr sr
                JOIN spriden sp ON (sr.spraddr_pidm = sp.spriden_pidm)
            WHERE sp.spriden_id = 'IPADE'||numEntidad
                AND sp.spriden_change_ind IS NULL
                AND sr.spraddr_atyp_code = 'F'||difEmpresa
        ) LOOP
            SELF.lugarExpedicion := q.spraddr_zip;
        END LOOP;

        FOR i IN (
            SELECT t.tbraccd_amount, t.tbraccd_effective_date
            FROM tbraccd t
            WHERE t.tbraccd_pidm = pidm
                AND t.tbraccd_tran_number = tranNumber
        ) LOOP
            SELF.totalNum := i.tbraccd_amount;
            SELF.totalLetra := GZKNUMB.monto_escrito(SELF.totalNum);
            -- SELF.fecha := i.tbraccd_effective_date - 6/24;
            SELF.fecha := SYSDATE - 1;   -- TEMPORAL: Tomar TBRACCD_EFFECTIVE_DATE de la transacción.
        END LOOP;

        FOR j IN (
            SELECT tbracdt_text
            FROM tbracdt
            WHERE tbracdt_pidm = pidm
                AND tbracdt_tran_number = tranNumber
            ORDER BY tbracdt_seq_number
        ) LOOP
            IF contNota = 1 THEN
                SELF.nota1 := TRIM(j.tbracdt_text);
            ELSIF contNota = 2 THEN
                SELF.nota2 := TRIM(j.tbracdt_text);
            ELSIF contNota = 3 THEN
                SELF.nota3 := TRIM(j.tbracdt_text);
            END IF;
            contNota := contNota + 1;
        END LOOP;
        RETURN;
    END TY_TRALIX_LINEA_01;

    MEMBER PROCEDURE set_cargos(cargos NUMBER, imp_ret NUMBER) IS
    BEGIN
        self.taxesTrasladados := imp_ret;
        self.descuento := NULL;
        self.taxesRetenidos := NULL;
        self.subTotalNum := cargos;
        self.totalNum := cargos - NVL(self.descuento, 0) + NVL(self.taxesTrasladados, 0) 
            + NVL(self.taxesRetenidos, 0);
        SELF.tipoCambio := 1;
    END set_cargos;

    MEMBER PROCEDURE set_folio(serie VARCHAR2, folio VARCHAR2) IS
    BEGIN
        self.cfdi := serie||folio;
        self.serie := serie;
        self.folio := folio;
    END set_folio;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.cfdi || SELF.sep ||
            SELF.serie || SELF.sep ||
            SELF.folio || SELF.sep ||
            SELF.format_fecha(SELF.fecha) || SELF.sep ||
            SELF.format_moneda(SELF.subTotalNum) || SELF.sep ||
            SELF.format_moneda(SELF.totalNum) || SELF.sep ||
            SELF.format_moneda(SELF.taxesTrasladados) || SELF.sep ||
            SELF.format_moneda(SELF.taxesRetenidos) || SELF.sep ||
            SELF.format_moneda(SELF.descuento) || SELF.sep ||
            SELF.motivoDescuento || SELF.sep ||
            SELF.totalLetra || SELF.sep ||
            SELF.moneda || SELF.sep ||
            SELF.tipoCambio || SELF.sep ||
            SELF.referencia || SELF.sep ||
            SELF.nota1 || SELF.sep ||
            SELF.nota2 || SELF.sep ||
            SELF.nota3 || SELF.sep ||
            SELF.tipoComprobante || SELF.sep ||
            SELF.metodoPago || SELF.sep ||
            SELF.lugarExpedicion || SELF.sep ||
            SELF.confirmacion || SELF.sep ||
            SELF.formaPago || SELF.sep ||
            SELF.condicionesPago || SELF.sep ||
            SELF.exportacion || SELF.sep ||
            SELF.facAtrAdquirente
        ;
    END imprimir_linea;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        -- IF (NVL(SELF.cfdi, '|') = '|') THEN
        --     SELF.AGREGAR_ERROR('Se debe especificar serie y folio concatenado como CFDI.');
        -- END IF;

        IF (NVL(SELF.subTotalNum, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe haber un valor en subTotal mayor a 0.');
        END IF;

        IF (NVL(SELF.totalNum, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe haber un valor en Total mayor a 0.');
        END IF;

        IF (NVL(SELF.lugarExpedicion, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe haber un valor de lugar de expedición.');
        END IF;
    END validar;
END;

-----------------
-- DROP TYPE TY_TRALIX_LINEA_02;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_02 UNDER TY_TRALIX_LINEA
(
    idRelacionado VARCHAR2(100 CHAR),
    tipoRelacion VARCHAR2(10 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_02(
        idRelacionado VARCHAR2,
        tipoRelacion VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION tiene_valor RETURN BOOLEAN,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_02 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_02(
        idRelacionado VARCHAR2,
        tipoRelacion VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('02');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;
        -- SELF.fecha := SYSDATE - 1;   -- TEMPORAL: Tomar TBRACCD_EFFECTIVE_DATE de la transacción.
        SELF.idRelacionado := idRelacionado;      -- Consultar catalogo c_Moneda
        SELF.tipoRelacion := tipoRelacion;  -- Consultar catalogo c_MetodoPago
        RETURN;
    END TY_TRALIX_LINEA_02;

    MEMBER FUNCTION tiene_valor RETURN BOOLEAN IS
    BEGIN
        RETURN (NVL(SELF.idRelacionado, '|') != '|');
    END tiene_valor;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.idRelacionado || SELF.sep ||
            SELF.tipoRelacion
        ;
    END imprimir_linea;
END;

------------------

-- DROP TYPE TY_TRALIX_LINEA_02A;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_02A UNDER TY_TRALIX_LINEA
(
    idRelacionado VARCHAR2(100 CHAR),
    uuid VARCHAR2(10 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_02A(
        idRelacionado VARCHAR2,
        uuid VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION tiene_valor RETURN BOOLEAN,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_02A AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_02A(
        idRelacionado VARCHAR2,
        uuid VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('02A');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;
        -- SELF.fecha := SYSDATE - 1;   -- TEMPORAL: Tomar TBRACCD_EFFECTIVE_DATE de la transacción.
        SELF.idRelacionado := idRelacionado;      -- Consultar catalogo c_Moneda
        SELF.uuid := uuid;  -- Consultar catalogo c_MetodoPago
        RETURN;
    END TY_TRALIX_LINEA_02A;

    MEMBER FUNCTION tiene_valor RETURN BOOLEAN IS
    BEGIN
        RETURN (NVL(SELF.idRelacionado, '|') != '|');
    END tiene_valor;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.idRelacionado || SELF.sep ||
            SELF.uuid
        ;
    END imprimir_linea;
END;

----------------
-- DROP TYPE TY_TRALIX_LINEA_03;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_03 UNDER TY_TRALIX_LINEA
(
    identificador VARCHAR2(256 CHAR),
    rfc VARCHAR2(15 CHAR),
    nombre VARCHAR2(254 CHAR),
    pais VARCHAR2(100 CHAR),
    calle  VARCHAR2(256 CHAR),
    numExterior VARCHAR2(256 CHAR),
    numInterior VARCHAR2(256 CHAR),
    colonia VARCHAR2(256 CHAR),
    localidad VARCHAR2(256 CHAR),
    referencia VARCHAR2(256 CHAR),
    municipio VARCHAR2(256 CHAR),
    estado VARCHAR2(256 CHAR),
    domFiscal VARCHAR2(5 CHAR),  -- Código Postal
    resFiscal VARCHAR2(256 CHAR),
    numRegIdTrib VARCHAR2(40 CHAR),
    usoCFDI VARCHAR2(40 CHAR),
    regimenFiscal VARCHAR2(40 CHAR),
    nombreParticipante VARCHAR2(200 CHAR),
    idParticipante VARCHAR2(30 CHAR),
    programa VARCHAR2(50 CHAR),
    numEntidad VARCHAR2(1 CHAR),

    esPubGral VARCHAR2(10 CHAR),
    numGrupo VARCHAR2(1 CHAR),
    tipoDir VARCHAR2(10 CHAR),

    /* TODO: Agregar parametro que indique se va a construir como PubGral */
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_03(
        pidm NUMBER,
        num_entidad VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER PROCEDURE datos_pubgral,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER FUNCTION esParaPubGral RETURN BOOLEAN,
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_03 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_03(
        pidm NUMBER,
        num_entidad VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
        contador NUMBER := 0;
        numGrupo VARCHAR2(1 CHAR);
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('03');

        SELF.numEntidad := num_entidad;
        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;
        -- SELF.nombre := f_format_name(pidm, 'FMIL');
        -- SELF.nombre := 'INSTITUTO PANAMERICANO DE ALTA DIRECCION DE EMPRESA';
        -- SELF.regimenFiscal := '612';   -- Tomado del catalogo c_RegimenFiscal, este valor default es el de personas fisicas
        SELF.usoCFDI := 'D10';    -- Tomado del catalgo c_usoCFDI

        SELF.nombreParticipante := f_format_name(pidm, 'FMIL');

        FOR k IN (
            SELECT spriden_entity_ind, spriden_id
            FROM spriden
            WHERE spriden_pidm = pidm
                AND spriden_change_ind IS NULL
        ) LOOP
            -- IF (k.spriden_entity_ind = 'C') THEN
            --     SELF.regimenFiscal := '601';  -- Tomado del catalogo c_RegimenFiscal, este valor default es el de personas morales
            -- END IF;
            SELF.idParticipante := k.spriden_id;
        END LOOP;

        FOR m IN (
            SELECT p.smrprle_program, p.smrprle_program_desc
            FROM sovlcur s
                JOIN smrprle p ON (s.sovlcur_program = p.smrprle_program)
            WHERE s.sovlcur_pidm = pidm
                AND s.sovlcur_active_ind = 'Y'
        ) LOOP
            SELF.programa := m.smrprle_program;
        END LOOP;

        /* Determinar RFC */
        FOR j IN (
            SELECT *
            FROM goradid 
            WHERE goradid_pidm = pidm
                AND goradid_adid_code LIKE '%RFC'
                AND goradid_additional_id LIKE '*%'
        ) LOOP
            SELF.rfc := REPLACE(j.goradid_additional_id, '*', '');
            numGrupo := SUBSTR(j.goradid_adid_code, 1, 1);
            SELF.numGrupo := numGrupo;
            EXIT;
        END LOOP;

        /* Buscando valores para regimenFiscal y usoCFDI */
        -- IF (SELF.rfc != '') THEN
            FOR r IN (
                SELECT goradid_additional_id
                FROM goradid
                WHERE goradid_pidm = pidm
                    AND goradid_adid_code = numGrupo || 'RFI'
                ORDER BY goradid_adid_code DESC
            ) LOOP
                SELF.regimenFiscal := r.goradid_additional_id;
            END LOOP;
        -- ELSE
        --     SELF.regimenFiscal := '616';
        -- END IF;

        FOR t IN (
            SELECT goradid_additional_id
            FROM goradid
            WHERE goradid_pidm = pidm
                AND goradid_adid_code = numGrupo || 'CFD'
            ORDER BY goradid_adid_code DESC
        ) LOOP
            SELF.usoCFDI := t.goradid_additional_id;
        END LOOP;

        FOR u IN (
            SELECT LISTAGG(goradid_additional_id, '')
                WITHIN GROUP (ORDER BY goradid_adid_code) as razon_social
            FROM goradid
            WHERE goradid_pidm = pidm
                AND goradid_adid_code LIKE numGrupo || 'RS%'
        ) LOOP
            SELF.nombre := u.razon_social;
        END LOOP;

        IF (NVL(SELF.nombre, '|') = '|') THEN
            SELF.nombre := SELF.nombreParticipante;
        END IF;

        -- Primero ver si se debe poner a PUBGRAL
        SELECT COUNT(*)
        INTO contador
        FROM tbbacct
        WHERE tbbacct_pidm = pidm
            AND tbbacct_bill_code = 'NO'
        ;

        -- Ver si efectivamente hay valores de RFC y UsoCFDI
        IF (contador = 0 AND
            ((NVL(TRIM(SELF.usoCFDI), '|') = '|') 
            OR (NVL(SELF.regimenFiscal, '|') = '|')
            OR (NVL(SELF.rfc, '|') = '|'))) THEN
            contador := 1;
        END IF;

        IF (contador > 0) THEN
            SELF.datos_pubgral;
            RETURN;
        END IF;

        FOR i IN (
            SELECT sp.*, st.stvstat_desc, sy.stvcnty_desc, sn.stvnatn_nation
            FROM spraddr sp
                LEFT JOIN stvstat st ON (sp.spraddr_stat_code = st.stvstat_code)
                LEFT JOIN stvcnty sy ON (sp.spraddr_cnty_code = sy.stvcnty_code)
                LEFT JOIN stvnatn sn ON (sp.spraddr_natn_code = sn.stvnatn_code)
            WHERE sp.spraddr_pidm = pidm
                AND spraddr_atyp_code = 'F' || SELF.numGrupo
                -- AND sp.spraddr_atyp_code LIKE 'F%'
            ORDER BY sp.spraddr_atyp_code DESC, sp.spraddr_activity_date DESC
        ) LOOP
            SELF.pais := i.stvnatn_nation;
            SELF.calle := i.spraddr_street_line1;
            SELF.numExterior := i.spraddr_street_line2;
            SELF.numInterior := i.spraddr_house_number;
            SELF.colonia := i.spraddr_street_line3;
            SELF.localidad := i.spraddr_city;
            SELF.referencia := i.spraddr_street_line4;
            SELF.estado := i.stvstat_desc;
            SELF.municipio := i.stvcnty_desc;
            SELF.domFiscal := i.spraddr_zip;
            SELF.tipoDir := i.spraddr_atyp_code || '|' || i.SPRADDR_SEQNO;
            EXIT;
        END LOOP;

        IF (NVL(SELF.calle, '|') = '|') THEN
            -- SELF.calle := 'CAIRO';
            -- SELF.numExterior := '2';
            -- SELF.numInterior := i.spraddr_house_number;
            -- SELF.colonia := i.spraddr_street_line3;
            -- SELF.localidad := i.spraddr_city;
            -- SELF.referencia := i.spraddr_street_line4;
            -- SELF.estado := i.stvstat_desc;
            -- SELF.municipio := 'CIUDAD DE MÉXICO';
            SELF.domFiscal := '02080';
        END IF;

        SELF.identificador := SELF.rfc;

        SELF.esPubGral := 'FALSE';

        RETURN;
    END TY_TRALIX_LINEA_03;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.identificador || SELF.sep ||
            SELF.rfc || SELF.sep ||
            SELF.nombre || SELF.sep ||
            SELF.pais || SELF.sep ||
            SELF.calle || SELF.sep ||
            SELF.numExterior || SELF.sep ||
            SELF.numInterior || SELF.sep ||
            SELF.colonia || SELF.sep ||
            SELF.localidad || SELF.sep ||
            SELF.referencia || SELF.sep ||
            SELF.municipio || SELF.sep ||
            SELF.estado || SELF.sep ||
            SELF.domFiscal || SELF.sep ||
            SELF.resFiscal || SELF.sep ||
            SELF.numRegIdTrib || SELF.sep ||
            SELF.usoCFDI || SELF.sep ||
            SELF.regimenFiscal || SELF.sep ||
            SELF.nombreParticipante || SELF.sep ||
            SELF.idParticipante || SELF.sep ||
            SELF.programa
        ;
    END imprimir_linea;

    MEMBER PROCEDURE datos_pubgral IS
    BEGIN
        SELF.pais := '';
        SELF.calle := '';
        SELF.numExterior := '';
        SELF.numInterior := '';
        SELF.colonia := '';
        SELF.localidad := '';
        SELF.referencia := '';
        SELF.estado := '';
        SELF.municipio := '';
        SELF.domFiscal := '';
        SELF.rfc := '';
        SELF.identificador := '';

        FOR j IN (
            SELECT g.goradid_additional_id
            FROM goradid g
                JOIN spriden s ON (g.goradid_pidm = s.spriden_pidm)
            WHERE g.goradid_adid_code = 'RFC'
                AND s.spriden_id = 'PUBGRAL' || SELF.numEntidad
                AND s.spriden_change_ind IS NULL
        ) loop
            SELF.rfc := j.goradid_additional_id;
            SELF.identificador := SELF.rfc;
        END LOOP;

        FOR r IN (
            SELECT g.goradid_additional_id
            FROM goradid g
                JOIN spriden s ON (g.goradid_pidm = s.spriden_pidm)
            WHERE s.spriden_id = 'PUBGRAL' || SELF.numEntidad
                AND g.goradid_adid_code LIKE '%RFI'
                AND s.spriden_change_ind IS NULL
            ORDER BY g.goradid_adid_code DESC
        ) LOOP
            SELF.regimenFiscal := r.goradid_additional_id;
        END LOOP;

        FOR t IN (
            SELECT g.goradid_additional_id
            FROM goradid g
                JOIN spriden s ON (g.goradid_pidm = s.spriden_pidm)
            WHERE s.spriden_id = 'PUBGRAL' || SELF.numEntidad
                AND s.spriden_change_ind IS NULL
                AND g.goradid_adid_code LIKE '%CFD'
            ORDER BY g.goradid_adid_code DESC
        ) LOOP
            SELF.usoCFDI := t.goradid_additional_id;
        END LOOP;

        /* TEMPORAL: Hardcodeados por el momento */
        SELF.pais := 'México';
        SELF.calle := 'AV AZCAPOTZALCO';
        SELF.numExterior := '145';
        SELF.numInterior := '0';
        SELF.colonia := 'CLAVERIA';
        SELF.localidad := 'Ciudad De Mexico';
        SELF.municipio := 'Azcapotzalco';
        SELF.estado := 'Distrito Federal';
        SELF.domFiscal := '02080';

        SELF.esPubGral := 'TRUE';

        SELF.nombreParticipante := 'PÚBLICO EN GENERAL';
        SELF.programa := '';
    END datos_pubgral;

    MEMBER FUNCTION esParaPubGral RETURN BOOLEAN IS
    BEGIN
        RETURN SELF.esPubGral = 'TRUE';
    END esParaPubGral;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        -- IF (NVL(SELF.identificador, '|') = '|') THEN
        --     SELF.AGREGAR_ERROR('Se debe especificar identificador del receptor.');
        -- END IF;

        -- IF (NVL(SELF.rfc, '|') = '|') THEN
        --     SELF.AGREGAR_ERROR('El receptor de la factura debe tener un RFC.');
        -- END IF;

        IF (NVL(SELF.nombre, '|') = '|') THEN
            SELF.AGREGAR_ERROR('El receptor debe tener nombre.');
        END IF;

        IF (NVL(SELF.usoCFDI, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe haber valor de usoCFDI.');
        END IF;

        IF (NVL(SELF.regimenFiscal, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe haber valor de regimen Fiscal.');
        END IF;
    END validar;
END;

----------------

-- DROP TYPE TY_TRALIX_LINEA_05;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_05 UNDER TY_TRALIX_LINEA
(
    clave_servicio VARCHAR2(30 CHAR),
    noIdentificacion VARCHAR2(100 CHAR),
    cantidad NUMBER,
    descripcion VARCHAR2(1000 CHAR),
    valorUnitario NUMBER(10, 2),
    importe NUMBER(10, 2),
    unidadMedida VARCHAR2(20 CHAR),
    claveUnidad VARCHAR(30 CHAR),
    descuento NUMBER(10, 2),
    idConcepto VARCHAR2(256 CHAR),
    objetoImp VARCHAR2(30 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_05(
        pidm NUMBER,
        tranNumber NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER PROCEDURE set_objetoImp(cObjetoImp VARCHAR2),
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE validar,
    MEMBER FUNCTION desplegar_programa(pidm NUMBER, tranNUmber NUMBER) RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_05 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_05(
        pidm NUMBER,
        tranNumber NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
        cantidadTotal TBRACCD.TBRACCD_AMOUNT%TYPE;
        totImpuestos  TBRACCD.TBRACCD_AMOUNT%TYPE;
        descTemporal  VARCHAR2(300 CHAR);
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('05');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;
        SELF.claveUnidad := 'E48';    -- Consultar catalogo c_ClaveUnidad
        SELF.valorUnitario := 0;
        SELF.objetoImp := '02';
        SELF.idConcepto := 'Linea_1';

        SELF.clave_servicio := '86132000';
        FOR k IN (
            SELECT p.smrprle_levl_code, p.smrprle_program_desc
            FROM sovlcur s
                JOIN smrprle p ON (s.sovlcur_program = p.smrprle_program)
            WHERE s.sovlcur_pidm = pidm
                AND s.sovlcur_active_ind = 'Y'
        ) LOOP
            -- SELF.clave_servicio := '86132000';
            IF k.smrprle_levl_code = 'PO' THEN
                SELF.clave_servicio := '86121702';
            END IF;

            SELF.descripcion := 'Capacitación '||k.smrprle_program_desc;
        END LOOP;

       

        IF NVL(SELF.descripcion, '|') = '|' THEN
            SELF.descripcion := 'Capacitación';
        ELSE
             /* Localizar que transacción pagó, y si es determinado tipo le cambia SELF.descripcion */  
            descTemporal := desplegar_programa(pidm, tranNumber);
            IF descTemporal != '|' THEN
                SELF.descripcion := descTemporal;
            END IF;
        END IF;

        FOR i IN (
            SELECT t.tbraccd_amount,
              t.tbraccd_detail_code,
              td.tbbdetc_desc,
              t.tbraccd_receipt_number
            FROM tbraccd t
                JOIN tbbdetc td ON (t.tbraccd_detail_code = td.tbbdetc_detail_code)
            WHERE t.tbraccd_pidm = pidm
                AND t.tbraccd_tran_number = tranNumber
        ) LOOP
            -- SELF.valorUnitario := i.tbraccd_amount;
            -- SELF.importe := i.tbraccd_amount;

            SELECT NVL(SUM(tbraccd_amount), 0)
            INTO totImpuestos
            FROM tbraccd t JOIN spriden s
                ON (t.tbraccd_pidm = s.spriden_pidm)
            WHERE tbraccd_tran_number != tranNumber
                AND tbraccd_receipt_number = i.tbraccd_receipt_number
                AND tbraccd_srce_code = 'Z';

            SELF.valorUnitario := i.tbraccd_amount - totImpuestos;
            SELF.importe := SELF.valorUnitario;
        END LOOP;

        RETURN;
    END TY_TRALIX_LINEA_05;

    MEMBER PROCEDURE set_objetoImp(cObjetoImp VARCHAR2) IS
    BEGIN
        SELF.objetoImp := cObjetoImp;
    END set_objetoImp;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.clave_servicio || SELF.sep ||
            SELF.noIdentificacion || SELF.sep ||
            TO_CHAR(NVL(SELF.cantidad, 1)) || SELF.sep ||
            SELF.descripcion || SELF.sep ||
            SELF.format_moneda(SELF.valorUnitario) || SELF.sep ||
            SELF.format_moneda(SELF.importe) || SELF.sep ||
            SELF.unidadMedida || SELF.sep ||
            SELF.claveUnidad || SELF.sep ||
            SELF.format_moneda(SELF.descuento) || SELF.sep ||
            SELF.idConcepto || SELF.sep ||
            SELF.objetoImp
        ;
    END imprimir_linea;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        IF (NVL(SELF.clave_servicio, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Se debe especificar clave de servicio.');
        END IF;

        IF (NVL(SELF.descripcion, '|') = '|') THEN
            SELF.AGREGAR_ERROR('El cargo debe tener descripción.');
        END IF;

        IF (NVL(SELF.valorUnitario, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe haber valor unitario.');
        END IF;

        IF (NVL(SELF.importe, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe haber importe.');
        END IF;

        IF (NVL(SELF.claveUnidad, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe haber una clave de unidad.');
        END IF;

        IF (NVL(SELF.idConcepto, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe haber un id de concepto.');
        END IF;

        IF (NVL(SELF.objetoImp, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe haber un objeto de importación.');
        END IF;
    END validar;

    MEMBER FUNCTION desplegar_programa(pidm NUMBER, tranNUmber NUMBER) RETURN VARCHAR2 IS
        vlc_respuesta tbbdetc.tbbdetc_desc%TYPE := '|';
        vlc_codigo_tranOrig tbraccd.tbraccd_detail_code%TYPE;
    BEGIN
        FOR i IN (
            SELECT t1.TBRAPPL_CHG_TRAN_NUMBER,
                t2.tbraccd_detail_code,
                t3.tbbdetc_desc
            FROM tbrappl t1 JOIN tbraccd t2 ON (
                t1.tbrappl_pidm = t2.tbraccd_pidm
                AND t1.tbrappl_chg_tran_number = t2.tbraccd_tran_number)
                JOIN tbbdetc t3 ON (t2.tbraccd_detail_code = t3.tbbdetc_detail_code)
            WHERE t1.tbrappl_pidm = pidm
                AND t1.tbrappl_pay_tran_number = tranNUmber
        ) LOOP
            vlc_codigo_tranOrig := i.tbraccd_detail_code;
            vlc_respuesta := i.tbbdetc_desc;
        END LOOP;

        IF (vlc_codigo_tranOrig != 'ALIM') THEN
            vlc_respuesta := '|';
        END IF;
        
        RETURN vlc_respuesta;
    END desplegar_programa;
END;

-- DROP TYPE TY_TRALIX_ARR_05;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_05 AS TABLE OF TY_TRALIX_LINEA_05;

-------------

-- DROP TYPE TY_TRALIX_LINEA_05C;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_05C UNDER TY_TRALIX_LINEA
(
    idConcepto VARCHAR2(256 CHAR),
    baseDec NUMBER(10, 2),
    impuesto VARCHAR2(10 CHAR),
    tipoFactor VARCHAR2(10 CHAR),
    tasaCuota NUMBER(10, 2),
    importe NUMBER(10, 2),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_05C(
        idConcepto VARCHAR2,
        baseDec NUMBER,
        impuesto VARCHAR2,
        tasaCuota NUMBER,
        importe NUMBER,
        tipoFactor VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_05C AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_05C(
        idConcepto VARCHAR2,
        baseDec NUMBER,
        impuesto VARCHAR2,
        tasaCuota NUMBER,
        importe NUMBER,
        tipoFactor VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('05C');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.idConcepto := idConcepto;
        IF impuesto LIKE '%IVA' THEN
            SELF.impuesto := '002';
        ELSIF impuesto LIKE '%ISR' THEN
            SELF.impuesto := '001';
        END IF;
        SELF.tasaCuota := tasaCuota;
        SELF.importe := importe;
        SELF.tipoFactor := tipoFactor;
        SELF.baseDec := baseDec;

        RETURN;
    END TY_TRALIX_LINEA_05C;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
        respuesta VARCHAR2(500 CHAR);
    BEGIN
        respuesta := '\n' || SELF.tipo_registro || SELF.sep || 
            SELF.idConcepto || SELF.sep ||
            SELF.format_moneda(SELF.baseDec) || SELF.sep ||
            SELF.impuesto || SELF.sep ||
            SELF.tipoFactor || SELF.sep
        ;
        
        IF (SELF.tipoFactor != 'Exento') THEN
            respuesta := respuesta ||
                TRIM(TO_CHAR(SELF.tasaCuota, '0.009999')) || SELF.sep ||
                SELF.format_moneda(SELF.importe)
            ;
        ELSE
            respuesta := respuesta || SELF.sep;
        END IF;

        RETURN respuesta;
    END imprimir_linea;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        IF (NVL(SELF.impuesto, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Se debe especificar clave de impuesto 1.');
        END IF;

        IF (NVL(SELF.tipoFactor, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe indicarse tipo de Factor.');
        END IF;

        IF (NVL(SELF.baseDec, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe indicarse una base.');
        END IF;
    END validar;
END;

-- DROP TYPE TY_TRALIX_ARR_05C;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_05C AS TABLE OF TY_TRALIX_LINEA_05C;

-------------

-- DROP TYPE TY_TRALIX_LINEA_06;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_06 UNDER TY_TRALIX_LINEA
(
    clave_impuesto VARCHAR2(30 CHAR),
    tasaCuota NUMBER(10, 2),
    importe NUMBER(10, 2),
    tipoFactor VARCHAR2(10 CHAR),
    baseDec NUMBER(10, 2),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_06(
        clave_impuesto VARCHAR2,
        tasaCuota NUMBER,
        importe NUMBER,
        baseDec NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_06 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_06(
        clave_impuesto VARCHAR2,
        tasaCuota NUMBER,
        importe NUMBER,
        baseDec NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('06');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        -- dbms_output.put_line('clave_impuesto:'||clave_impuesto);

        IF clave_impuesto LIKE '%IVA' THEN
            SELF.clave_impuesto := '002';
        ELSIF clave_impuesto LIKE '%ISR' THEN
            SELF.clave_impuesto := '001';
        END IF;
        SELF.tasaCuota := tasaCuota;
        SELF.importe := importe;
        SELF.tipoFactor := 'Exento';
        IF (tasaCuota > 0) THEN
            SELF.tipoFactor := 'Tasa';
        END IF;
        SELF.baseDec := baseDec;

        RETURN;
    END TY_TRALIX_LINEA_06;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep || 
            SELF.clave_impuesto || SELF.sep ||
            TRIM(TO_CHAR(SELF.tasaCuota, '0.009999')) || SELF.sep ||
            SELF.format_moneda(SELF.importe) || SELF.sep ||
            SELF.tipoFactor || SELF.sep ||
            SELF.format_moneda(SELF.baseDec)
        ;
    END imprimir_linea;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        IF (NVL(SELF.clave_impuesto, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Se debe especificar clave de impuesto 2.');
        END IF;

        -- IF (NVL(SELF.tasaCuota, -1) = -1) THEN
        --     SELF.AGREGAR_ERROR('Debe indicarse si es tasa o cuota.');
        -- END IF;

        -- IF (NVL(SELF.importe, -1) = -1) THEN
        --     SELF.AGREGAR_ERROR('Debe haber importe de impuesto.');
        -- END IF;

        IF (NVL(SELF.tipoFactor, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Debe indicarse tipo de Factor.');
        END IF;

        IF (NVL(SELF.baseDec, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe indicarse una base.');
        END IF;
    END validar;
END;

-- DROP TYPE TY_TRALIX_ARR_06;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_06 AS TABLE OF TY_TRALIX_LINEA_06;


-------------

-- DROP TYPE TY_TRALIX_LINEA_07;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_07 UNDER TY_TRALIX_LINEA
(
    clave_impuesto VARCHAR2(30 CHAR),
    importe NUMBER(10, 2),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_07(
        clave_impuesto VARCHAR2,
        importe NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE validar
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_07 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_07(
        clave_impuesto VARCHAR2,
        importe NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('07');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.clave_impuesto := clave_impuesto;
        SELF.importe := importe;

        RETURN;
    END TY_TRALIX_LINEA_07;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep || 
            SELF.clave_impuesto || SELF.sep ||
            SELF.format_moneda(SELF.importe)
        ;
    END imprimir_linea;

    MEMBER PROCEDURE validar IS
    BEGIN
        SELF.INIT_ERRORES;
        IF (NVL(SELF.clave_impuesto, '|') = '|') THEN
            SELF.AGREGAR_ERROR('Se debe especificar clave de impuesto.');
        END IF;

        IF (NVL(SELF.importe, -1) = -1) THEN
            SELF.AGREGAR_ERROR('Debe haber importe de impuesto.');
        END IF;
    END validar;
END;

-- DROP TYPE TY_TRALIX_ARR_07;

CREATE OR REPLACE TYPE TY_TRALIX_ARR_07 AS TABLE OF TY_TRALIX_LINEA_07;

-------------

-- DROP TYPE TY_TRALIX_LINEA_09;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_09 UNDER TY_TRALIX_LINEA
(
    idIntReceptor VARCHAR2(15 CHAR),
    eMail VARCHAR2(255 CHAR),
    asunto VARCHAR2(255 CHAR),
    mensaje VARCHAR2(511 CHAR),
    adjunto VARCHAR2(10 CHAR),
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_09(
        matricula VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_09 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_09(
        matricula VARCHAR2
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
        correo VARCHAR2(200 CHAR);
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('09');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.asunto := 'CFDI IPADE de '||matricula;

        /* Determinar correo */
        FOR i IN (
            SELECT spr.spraddr_street_line4
            FROM spraddr spr 
                JOIN spriden sp ON (spr.spraddr_pidm = sp.spriden_pidm)
            WHERE sp.spriden_id = matricula
                AND sp.spriden_change_ind IS NULL
                AND spr.spraddr_street_line4 LIKE '%@%'
            ORDER BY spr.spraddr_activity_date DESC
        ) LOOP
            correo := i.spraddr_street_line4;

            IF (NVL(TRIM(correo), '|') != '|') THEN
                EXIT;
            END IF;
        END LOOP;

        IF (NVL(TRIM(correo), '|') = '|') THEN
            FOR j IN (
                SELECT g.goremal_email_address
                FROM goremal g
                    JOIN spriden s ON (g.goremal_pidm = s.spriden_pidm)
                WHERE g.goremal_emal_code = 'INS'
                ORDER BY g.goremal_activity_date DESC
            ) LOOP
                correo := j.goremal_email_address;

                IF (NVL(TRIM(correo), '|') != '|') THEN
                    SELF.eMail := correo;
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        RETURN;
    END TY_TRALIX_LINEA_09;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_Registro || SELF.sep || 
            SELF.idIntReceptor || SELF.sep ||
            SELF.eMail || SELF.sep ||
            SELF.asunto || SELF.sep ||
            SELF.mensaje || SELF.sep ||
            SELF.adjunto
        ;
    END imprimir_linea;
END;

-------------

-- DROP TYPE TY_TRALIX_LINEA_99;

CREATE OR REPLACE TYPE TY_TRALIX_LINEA_99 UNDER TY_TRALIX_LINEA
(
    numLineas NUMBER,
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_99(
        numLineas NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY TY_TRALIX_LINEA_99 AS
    CONSTRUCTOR FUNCTION TY_TRALIX_LINEA_99(
        numLineas NUMBER
    ) RETURN SELF AS RESULT IS
        parent TY_TRALIX_LINEA;
    BEGIN
        SELECT self INTO parent FROM dual;
        parent.INIT('99');

        SELF.tipo_registro := parent.tipo_registro;
        SELF.sep := parent.sep;

        SELF.numLineas := numLineas;
        RETURN;
    END TY_TRALIX_LINEA_99;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
    BEGIN
        RETURN '\n' || SELF.tipo_registro || SELF.sep ||
            SELF.numLineas;
    END imprimir_linea;
END;

--------------

-- DROP TYPE TY_TRALIX_FACTURA;

CREATE OR REPLACE TYPE TY_TRALIX_FACTURA AS OBJECT
(
    inicio_archivo TY_TRALIX_LINEA_00,
    info_gral_comprobante TY_TRALIX_LINEA_01,
    info_sustitucion TY_TRALIX_LINEA_02,
    info_sust_detalle TY_TRALIX_LINEA_02A,
    receptor TY_TRALIX_LINEA_03,
    conceptos TY_TRALIX_ARR_05,
    concImpTras TY_TRALIX_ARR_05C,
    envio_automatico TY_TRALIX_LINEA_09,
    finCfdi TY_TRALIX_LINEA_99,
    impuestosTras TY_TRALIX_ARR_06,
    impuestosRets TY_TRALIX_ARR_07,
    errores TY_TRALIX_ARR_ERROR,

    /* TODO: Agregar en este constructor si se va a enviar a PubGral o no */
    CONSTRUCTOR FUNCTION TY_TRALIX_FACTURA(
        matricula VARCHAR2,
        tranNumber NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        formaPago VARCHAR2,
        metodoPago VARCHAR2,
        procesoFactura VARCHAR2
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2,
    MEMBER PROCEDURE ajustar_pubgral,
    MEMBER PROCEDURE validar,
    MEMBER PROCEDURE impuestos_default(pidm NUMBER, tranNumber NUMBER,
        totalCargos OUT NUMBER, impTrasladados OUT NUMBER),
    MEMBER PROCEDURE impuestos_anticipada(pidm NUMBER, tranNumber NUMBER,
        totalCargos OUT NUMBER, impTrasladados OUT NUMBER)
) NOT FINAL INSTANTIABLE
;

create or replace TYPE BODY TY_TRALIX_FACTURA AS
    CONSTRUCTOR FUNCTION TY_TRALIX_FACTURA(
        matricula VARCHAR2,
        tranNumber NUMBER,
        numEntidad VARCHAR2,
        difEmpresa VARCHAR2,
        formaPago VARCHAR2,
        metodoPago VARCHAR2,
        procesoFactura VARCHAR2
    ) RETURN SELF AS RESULT IS
        concepto TY_TRALIX_LINEA_05;
        -- impuestoTras TY_TRALIX_LINEA_06;
        impuestoRet TY_TRALIX_LINEA_07;
        numLineas NUMBER := 0;
        totalCargos NUMBER := 0;
        impRetenidos NUMBER := 0;
        impTrasladados NUMBER := 0;
        cObjetoImp VARCHAR2(2 CHAR) := '01';
        -- vlc_camp_code stvcamp.stvcamp_dicd_code%TYPE;
        vln_pidm_entidad_fiscal SPRIDEN.SPRIDEN_PIDM%TYPE;
        vlc_nombreArchivo VARCHAR2(100 CHAR);
        vln_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;
        vln_contador NUMBER;
        -- concImpTrasRow TY_TRALIX_LINEA_05C;

        -- tranPagada TBRAPPL.tbrappl_chg_tran_number%TYPE;
        -- vln_sumaImpuestos NUMBER := 0;
        -- vlb_exento BOOLEAN;
        -- vln_subTotal TBRACCD.TBRACCD_AMOUNT%TYPE;
        -- vlc_detalleImp TBRACCD.TBRACCD_DETAIL_CODE%TYPE;
    BEGIN
        vlc_nombreArchivo := matricula || '_' || tranNumber || '.txt';
        SELF.inicio_archivo := ty_tralix_linea_00(vlc_nombreArchivo);
        numLineas := numLineas + 1;

        vln_pidm := gb_common.f_get_pidm(matricula);

        SELF.envio_automatico := ty_tralix_linea_09(matricula);

        SELF.info_gral_comprobante := ty_tralix_linea_01(vln_pidm, tranNumber, numEntidad, 
            difEmpresa, metodoPago, formaPago);
        -- IF (SELF.info_gral_comprobante.descuento = 0) THEN
        -- END IF; 
        numLineas := numLineas + 1;
        SELF.receptor := ty_tralix_linea_03(vln_pidm, numEntidad);

        IF (SELF.receptor.esPubGral = 'TRUE') THEN
            SELF.receptor.idParticipante := 'PUBGRAL' || numEntidad;
        END IF;

        SELF.envio_automatico.idIntReceptor := SELF.receptor.identificador;
        numLineas := numLineas + 1;

        SELF.info_sustitucion := TY_TRALIX_LINEA_02('', '');
        SELF.info_sust_detalle := TY_TRALIX_LINEA_02A('', '');

        SELF.conceptos := TY_TRALIX_ARR_05();
        SELF.concImpTras := TY_TRALIX_ARR_05C();
        SELF.impuestosTras := TY_TRALIX_ARR_06();
        SELF.impuestosRets := TY_TRALIX_ARR_07();
        SELF.errores := TY_TRALIX_ARR_ERROR();

        IF (procesoFactura = 'ANT') THEN
            impuestos_anticipada(vln_pidm, tranNumber, totalCargos, impTrasladados);
        ELSE
            impuestos_default(vln_pidm, tranNumber, totalCargos, impTrasladados);
        END IF;
        
        numLineas := numLineas + SELF.conceptos.COUNT
            + SELF.impuestosTras.COUNT + SELF.concImpTras.COUNT;

        SELF.info_gral_comprobante.set_cargos(totalCargos, impTrasladados);
        
        numLineas := numLineas + SELF.impuestosRets.COUNT;
        numLineas := numLineas + 1;
        SELF.finCfdi := ty_tralix_linea_99(numLineas);

        RETURN;
    END TY_TRALIX_FACTURA;

    MEMBER FUNCTION imprimir_linea RETURN VARCHAR2 IS
        vlc_respuesta VARCHAR2(4000 CHAR);
    BEGIN
        vlc_respuesta := SELF.inicio_archivo.imprimir_linea || '|' ||
            SELF.info_gral_comprobante.imprimir_linea;

        IF (SELF.info_sustitucion.tiene_valor) THEN
            vlc_respuesta := vlc_respuesta || '|' ||
                SELF.info_sustitucion.imprimir_linea || '|' ||
                SELF.info_sust_detalle.imprimir_linea
            ;
        END IF;
            
        vlc_respuesta := vlc_respuesta || '|' ||
            SELF.receptor.imprimir_linea
        ;

        IF (SELF.conceptos.COUNT > 0) THEN
            FOR i IN SELF.conceptos.FIRST .. SELF.conceptos.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.conceptos(i).imprimir_linea;
            END LOOP; 
        END IF;

        IF (SELF.concImpTras.COUNT > 0) THEN
            FOR m IN SELF.concImpTras.FIRST .. SELF.concImpTras.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.concImpTras(m).imprimir_linea;
            END LOOP;
        END IF;

        IF (SELF.impuestosTras.COUNT > 0) THEN
            FOR j IN SELF.impuestosTras.FIRST .. SELF.impuestosTras.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.impuestosTras(j).imprimir_linea;
            END LOOP;
        END IF;

        IF (SELF.impuestosRets.COUNT > 0) THEN
            FOR j IN SELF.impuestosRets.FIRST .. SELF.impuestosRets.LAST
            LOOP
                vlc_respuesta := vlc_respuesta || '|' || 
                    SELF.impuestosRets(j).imprimir_linea;
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
    END;

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

        IF ((SELF.impuestosTras.COUNT + SELF.impuestosRets.COUNT) > 0) THEN
        --     SELF.errores.EXTEND;
        --     SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('La transacción no tiene impuestos en TVRFWTX');
        -- ELSE
            IF (SELF.impuestosTras.COUNT > 0) THEN
                FOR p IN SELF.impuestosTras.FIRST .. SELF.impuestosTras.LAST
                LOOP
                    SELF.impuestosTras(p).validar;
                    IF (SELF.impuestosTras(p).errores.COUNT > 0) THEN
                        FOR q IN SELF.impuestosTras(p).errores.FIRST .. SELF.impuestosTras(p).errores.LAST
                        LOOP
                            SELF.errores.EXTEND;
                            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.impuestosTras(p).errores(1).mensaje);
                        END LOOP;
                    END IF;
                END LOOP;
            END IF;

            IF (SELF.impuestosRets.COUNT > 0) THEN
                FOR p IN SELF.impuestosRets.FIRST .. SELF.impuestosRets.LAST
                LOOP
                    SELF.impuestosRets(p).validar;
                    IF (SELF.impuestosRets(p).errores.COUNT > 0) THEN
                        FOR q IN SELF.impuestosRets(p).errores.FIRST .. SELF.impuestosRets(p).errores.LAST
                        LOOP
                            SELF.errores.EXTEND;
                            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(SELF.impuestosRets(p).errores(1).mensaje);
                        END LOOP;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END validar;

    MEMBER PROCEDURE impuestos_default(pidm NUMBER, tranNumber NUMBER,
        totalCargos OUT NUMBER, impTrasladados OUT NUMBER) IS
        impuestoTras TY_TRALIX_LINEA_06;
        concImpTrasRow TY_TRALIX_LINEA_05C;
        vln_sumaImpuestos NUMBER := 0;
        vlc_detalleImp TBRACCD.TBRACCD_DETAIL_CODE%TYPE;
        vlb_exento BOOLEAN;
        concepto TY_TRALIX_LINEA_05;
        vln_subTotal TBRACCD.TBRACCD_AMOUNT%TYPE;
    BEGIN
        totalCargos := 0;
        impTrasladados := 0;
        FOR j IN (
            SELECT tbraccd_amount, tbraccd_receipt_number,
                tbraccd_detail_code
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number = tranNumber
        ) LOOP
            /* Buscar impuestos */
            SELECT NVL(SUM(tbraccd_amount), 0),
                MAX(tbraccd_detail_code)
            INTO vln_sumaImpuestos,
                vlc_detalleImp
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number != tranNumber
                AND tbraccd_receipt_number = j.tbraccd_receipt_number
                AND tbraccd_srce_code = 'Z';

            /* si hay impuestos */
            IF (vln_sumaImpuestos <= 0) THEN
                vlb_exento := TRUE;
                concepto := TY_TRALIX_LINEA_05(pidm, tranNumber);
                SELF.conceptos.EXTEND;
                SELF.conceptos(SELF.conceptos.COUNT) := concepto;
                totalCargos := totalCargos + j.tbraccd_amount;

                impuestoTras := TY_TRALIX_LINEA_06(
                    'IVA',
                    NULL,
                    NULL,
                    j.tbraccd_amount
                );
                -- SELF.impuestosTras.EXTEND;
                -- SELF.impuestosTras(SELF.impuestosTras.COUNT) := impuestoTras;

                concImpTrasRow := TY_TRALIX_LINEA_05C(
                    concepto.idConcepto,
                    j.tbraccd_amount,
                    'IVA',
                    0,
                    0,
                    'Exento');
            ELSE
                vlb_exento := FALSE;
                vln_subTotal := j.tbraccd_amount - vln_sumaImpuestos;
                concepto := TY_TRALIX_LINEA_05(pidm, tranNumber);
                concepto.importe := vln_subTotal;
                SELF.conceptos.EXTEND;
                SELF.conceptos(SELF.conceptos.COUNT) := concepto;

                totalCargos := totalCargos + vln_subTotal;

                -- vlc_detalleImp := j.tbraccd_detail_code;
                vlc_detalleImp := 'IVA';    /* TEMPORAL */

                impuestoTras := TY_TRALIX_LINEA_06(
                    vlc_detalleImp, 
                    vln_sumaImpuestos / (j.tbraccd_amount - vln_sumaImpuestos),
                    vln_sumaImpuestos,
                    j.tbraccd_amount - vln_sumaImpuestos);

                impTrasladados := impTrasladados + vln_sumaImpuestos;

                concImpTrasRow := TY_TRALIX_LINEA_05C(
                    concepto.idConcepto,
                    j.tbraccd_amount - vln_sumaImpuestos,
                    vlc_detalleImp,
                    -- vln_sumaImpuestos / (j.tbraccd_amount - vln_sumaImpuestos),
                    impuestoTras.tasaCuota,
                    vln_sumaImpuestos,
                    'Tasa');
            END IF;

            SELF.impuestosTras.EXTEND;
            SELF.impuestosTras(SELF.impuestosTras.COUNT) := impuestoTras;    

            SELF.concImpTras.EXTEND;
            SELF.concImpTras(SELF.concImpTras.COUNT) := concImpTrasRow;
        END LOOP;
    END impuestos_default;

    MEMBER PROCEDURE impuestos_anticipada(pidm NUMBER, tranNumber NUMBER,
        totalCargos OUT NUMBER, impTrasladados OUT NUMBER) IS
        impuestoTras TY_TRALIX_LINEA_06;
        concImpTrasRow TY_TRALIX_LINEA_05C;
        vln_sumaImpuestos NUMBER := 0;
        vlc_detalleImp TBRACCD.TBRACCD_DETAIL_CODE%TYPE;
        vlb_exento BOOLEAN;
        concepto TY_TRALIX_LINEA_05;
        vln_subTotal TBRACCD.TBRACCD_AMOUNT%TYPE;
        generarImpuestos BOOLEAN := false;
        programa VARCHAR2(200 CHAR);
    BEGIN
        totalCargos := 0;
        impTrasladados := 0;

        programa := SELF.receptor.programa;
        IF (NVL(SELF.receptor.programa, '|') = '|') THEN
            FOR j IN (
                SELECT sovlcur_program
                FROM sovlcur
                WHERE sovlcur_pidm = pidm
	                AND sovlcur_lmod_code = sb_curriculum_str.f_learner)
            LOOP
                programa := j.sovlcur_program;
            END LOOP;
        END IF;

        /* Determinar si es necesario calcular impuestos o no */
        dbms_output.put_line('Programa: '||SELF.receptor.programa);
        FOR i IN (
            SELECT sorxref_banner_value
            FROM sorxref
            WHERE sorxref_xlbl_code = 'IMPUESTO'
                AND sorxref_edi_value = programa
        ) LOOP
            -- dbms_output.put_line('Tipo Impuesto: '||i.sorxref_banner_value);
            generarImpuestos := (i.sorxref_banner_value = 'IVA');
        END LOOP;

        vlc_detalleImp := 'IVA';
        FOR j IN (
            SELECT tbraccd_amount, tbraccd_receipt_number,
                tbraccd_detail_code
            FROM tbraccd
            WHERE tbraccd_pidm = pidm
                AND tbraccd_tran_number = tranNumber
        ) LOOP
            IF (generarImpuestos) THEN
                vlb_exento := FALSE;
                vln_subTotal := j.tbraccd_amount / 1.16;
                vln_sumaImpuestos := j.tbraccd_amount - vln_subTotal;
                concepto := TY_TRALIX_LINEA_05(pidm, tranNumber);
                concepto.importe := vln_subTotal;
                SELF.conceptos.EXTEND;
                SELF.conceptos(SELF.conceptos.COUNT) := concepto;

                totalCargos := totalCargos + vln_subTotal;

                impuestoTras := TY_TRALIX_LINEA_06(
                    vlc_detalleImp, 
                    vln_sumaImpuestos / (j.tbraccd_amount - vln_sumaImpuestos),
                    vln_sumaImpuestos,
                    j.tbraccd_amount - vln_sumaImpuestos);

                impTrasladados := impTrasladados + vln_sumaImpuestos;

                concImpTrasRow := TY_TRALIX_LINEA_05C(
                    concepto.idConcepto,
                    j.tbraccd_amount - vln_sumaImpuestos,
                    vlc_detalleImp,
                    -- vln_sumaImpuestos / (j.tbraccd_amount - vln_sumaImpuestos),
                    impuestoTras.tasaCuota,
                    vln_sumaImpuestos,
                    'Tasa');
            ELSE
                vlb_exento := TRUE;
                concepto := TY_TRALIX_LINEA_05(pidm, tranNumber);

                SELF.conceptos.EXTEND;
                SELF.conceptos(SELF.conceptos.COUNT) := concepto;
                totalCargos := totalCargos + j.tbraccd_amount;

                impuestoTras := TY_TRALIX_LINEA_06(
                    'IVA',
                    NULL,
                    NULL,
                    j.tbraccd_amount
                );

                concImpTrasRow := TY_TRALIX_LINEA_05C(
                    concepto.idConcepto,
                    j.tbraccd_amount,
                    'IVA',
                    0,
                    0,
                    'Exento');
            END IF;

            SELF.impuestosTras.EXTEND;
            SELF.impuestosTras(SELF.impuestosTras.COUNT) := impuestoTras;    

            SELF.concImpTras.EXTEND;
            SELF.concImpTras(SELF.concImpTras.COUNT) := concImpTrasRow;
        END LOOP;
    END impuestos_anticipada;
END;

-------------

-- DROP TYPE TY_TRALIX_ENVIOFAC_RESPONSE;

CREATE OR REPLACE TYPE TY_TRALIX_ENVIOFAC_RESPONSE AS OBJECT
(
    matricula VARCHAR2(20 CHAR),
    pidm NUMBER,
    tranNumber NUMBER,
    estatus VARCHAR2(10 CHAR),
    mainData CLOB,
    errores TY_TRALIX_ARR_ERROR,
    CONSTRUCTOR FUNCTION TY_TRALIX_ENVIOFAC_RESPONSE(
        matricula VARCHAR2,
        tranNumber NUMBER
    ) RETURN SELF AS RESULT,
    MEMBER PROCEDURE validar_datos,
    MEMBER FUNCTION imprimir_json RETURN CLOB,
    MEMBER PROCEDURE AGREGAR_ERROR(pic_mensaje VARCHAR2)
) NOT FINAL INSTANTIABLE
;

create or replace TYPE BODY TY_TRALIX_ENVIOFAC_RESPONSE AS
    CONSTRUCTOR FUNCTION TY_TRALIX_ENVIOFAC_RESPONSE(
        matricula VARCHAR2,
        tranNumber NUMBER
    ) RETURN SELF AS RESULT IS
    BEGIN
        SELF.estatus := 'OK';
        SELF.errores := TY_TRALIX_ARR_ERROR();
        SELF.tranNumber := tranNumber;
        SELF.matricula := matricula;
        RETURN;
    END TY_TRALIX_ENVIOFAC_RESPONSE;

    MEMBER PROCEDURE validar_datos IS
        vln_contador NUMBER := 0;
    BEGIN
        FOR i IN (
            SELECT spriden_pidm
            FROM spriden
            WHERE spriden_id = matricula
                AND spriden_change_ind IS NULL
        ) LOOP
            SELF.pidm := i.spriden_pidm;
            vln_contador := vln_contador + 1;
        END LOOP;

        IF (vln_contador < 1) THEN
            SELF.errores.EXTEND;
            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('No existe la matrícula en Banner.');
            SELF.estatus := 'ERROR';
            RETURN;
        END IF;

        SELECT COUNT(*)
        INTO vln_contador
        FROM tbraccd t
        WHERE t.tbraccd_pidm = SELF.pidm
            AND t.tbraccd_tran_number = tranNumber;

        IF (vln_contador < 1) THEN
            SELF.errores.EXTEND;
            SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR('El alumno no tiene una transacción con ese número en su estado de cuenta.');
            SELF.estatus := 'ERROR';
            RETURN;
        END IF; 

        /* Hacer validaciones adicionales en TBRACCD */

        /* Validar si ya se generó la factura en TZRPOFI */

    END validar_datos;

    MEMBER FUNCTION imprimir_json RETURN CLOB IS
        vlc_respuesta CLOB;
    BEGIN
        gokjson.initialize_clob_output;
        gokjson.open_object(NULL);
        gokjson.write('estatus', SELF.estatus);
        gokjson.write('main_data', SELF.mainData);

        gokjson.open_array('errores');
        IF (SELF.errores.COUNT > 0) THEN
            FOR i IN SELF.errores.FIRST .. SELF.errores.LAST
            LOOP
                gokjson.write('X1', SELF.errores(i).mensaje);
            END LOOP;
        END IF;
        gokjson.close_array;
        gokjson.close_object;
        vlc_respuesta := gokjson.get_clob_output;
        vlc_respuesta := REPLACE(vlc_respuesta, '\"', '"');
        vlc_respuesta := REPLACE(vlc_respuesta, '"{', '{');
        vlc_respuesta := REPLACE(vlc_respuesta, '}"', '}');
        gokjson.free_output;
        vlc_respuesta := REPLACE(vlc_respuesta, '"X1": ', ''); 
        RETURN vlc_respuesta;
    END imprimir_json;

    MEMBER PROCEDURE AGREGAR_ERROR(pic_mensaje VARCHAR2) IS
    BEGIN
        SELF.errores.EXTEND;
        SELF.errores(SELF.errores.COUNT) := TY_TRALIX_ROW_ERROR(pic_mensaje);
    END AGREGAR_ERROR;
END;