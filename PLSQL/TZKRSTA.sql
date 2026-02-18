CREATE OR REPLACE PACKAGE TZKRSTA IS
    FUNCTION fn_registrar(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        tran_number_orig IN NUMBER,
        uuidTralix IN VARCHAR2,
        datos_factura IN TY_TRALIX_FACTURA,
        datos_compPago IN TY_TRALIX_COMPPAGO,
        tipo_factura IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION fn_cancelar_factura(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        motivo_sust IN VARCHAR2) 
        RETURN VARCHAR2;

    FUNCTION fn_sustituir_factura(
        pidm_canc IN NUMBER,
        tran_number_canc IN NUMBER,
        nuevo_guid IN VARCHAR2) 
        RETURN VARCHAR2;  

    FUNCTION fn_registrar_canc_1(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        motivo_canc IN VARCHAR2) 
        RETURN VARCHAR2;
END TZKRSTA;
/
show errors;

CREATE OR REPLACE PACKAGE BODY TZKRSTA IS
    cgc_estatus_debug     CONSTANT VARCHAR2(1) := 'A'; --Estatus de debug en GURDBUG D debug, O Output, A Ambos, I Inactivo
	cgc_raiz_debug        CONSTANT VARCHAR2(100) := 'TZKRSTA-';

    PROCEDURE pr_registrar_debug (
        pic_procedimiento	IN	VARCHAR2,
        pic_texto   		IN  VARCHAR2
    ) IS
	BEGIN
		IF cgc_estatus_debug IN ('A','D') THEN
			P_BAN_DEBUG(cgc_raiz_debug||pic_procedimiento,pic_texto);
		END IF;
		
		IF cgc_estatus_debug IN ('A','O') THEN
			DBMS_OUTPUT.PUT_LINE(pic_procedimiento||' -> '||pic_texto);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;

    FUNCTION fn_determina_sigNumero(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        inicio_codigo IN VARCHAR2)
        RETURN VARCHAR2 IS

        vln_respuesta NUMBER := 1;
        vlc_respuesta VARCHAR2(2 CHAR);
        vlc_tipoCodigo tvrtsta.tvrtsta_tsta_code%TYPE;
        vlc_regExp VARCHAR2(10 CHAR);
        vln_longResp NUMBER := 1;
        vlc_formato VARCHAR2(2 CHAR);
    BEGIN
        vlc_regExp := inicio_codigo;
        IF (LENGTH(inicio_codigo) = 1) THEN
            vlc_regExp := vlc_regExp || '\d\d';
            vln_longResp := 2;
            vlc_formato := '00';
        ELSE
            vlc_regExp := vlc_regExp || '\d';
            vln_longResp := 1;
            vlc_formato := '0';
        END IF;

        pr_registrar_debug('fn_determina_sigNumero','inicio_codigo:'||inicio_codigo);
        pr_registrar_debug('fn_determina_sigNumero','vlc_regExp:'||vlc_regExp);

        SELECT NVL(MAX(tvrtsta_tsta_code), '|')
        INTO vlc_tipoCodigo
        FROM tvrtsta
        WHERE REGEXP_LIKE (tvrtsta_tsta_code, vlc_regExp)
            AND tvrtsta_pidm = pidm
            AND tvrtsta_tran_number = tran_number
        ;

        pr_registrar_debug('fn_determina_sigNumero','vlc_tipoCodigo:'||vlc_tipoCodigo);

        IF (vlc_tipoCodigo != '|') THEN
            vln_respuesta := TO_NUMBER(SUBSTR(vlc_tipoCodigo, (vln_longResp * -1))) + 1;
        END IF;

        IF (vln_respuesta > 9) THEN
            vln_respuesta := 9;
        END IF;

        /* TODO: Verificar que no pase de cierto numero en determinados casos */
        IF (inicio_codigo IN ('PC')) THEN
            IF (vln_respuesta > 2) THEN
                vln_respuesta := 2;
            END IF;
        END IF;

        vlc_respuesta := TRIM(TO_CHAR(vln_respuesta, vlc_formato));

        pr_registrar_debug('fn_determina_sigNumero','respuesta:*'||vlc_respuesta||'*');

        RETURN vlc_respuesta;        
    END fn_determina_sigNumero;

    FUNCTION fn_insertar_tvrtsta(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        registros TY_TRALIX_TSTA_ARR
    ) RETURN VARCHAR2 IS
        reg_agregar TY_TRALIX_TSTA_ARR;
        vln_contador NUMBER := 0;
        secuencial NUMBER;
    BEGIN
        reg_agregar := TY_TRALIX_TSTA_ARR();
        FOR i IN registros.FIRST .. registros.LAST
        LOOP
            SELECT COUNT(*)
            INTO vln_contador
            FROM tvrtsta
            WHERE tvrtsta_pidm = pidm
                AND tvrtsta_tran_number = tran_number
                AND tvrtsta_tsta_code = registros(i).codigo
            ;

            pr_registrar_debug('fn_insertar_tvrtsta','UPDATE codigo:'||registros(i).codigo||' - Contador:'||vln_contador);

            IF (vln_contador > 0) THEN
                UPDATE tvrtsta
                SET tvrtsta_comments = registros(i).valor,
                    TVRTSTA_DLOC_CODE = registros(i).dLocCode,
                    tvrtsta_activity_date = SYSDATE
                WHERE tvrtsta_pidm = pidm
                    AND tvrtsta_tran_number = tran_number
                    AND tvrtsta_tsta_code = registros(i).codigo;
            ELSE
                SELECT COUNT(*)
                INTO vln_contador
                FROM tvvtsta
                WHERE tvvtsta_code = registros(i).codigo;

                IF (vln_contador > 0) THEN
                    reg_agregar.EXTEND;
                    reg_agregar(reg_agregar.COUNT) := registros(i);
                ELSE
                    pr_registrar_debug('fn_insertar_tvrtsta','codigo:'||registros(i).codigo||' no existe en TVVTSTA');
                END IF;  
            END IF;
        END LOOP; 

        pr_registrar_debug('fn_insertar_tvrtsta','para agregar:'||reg_agregar.COUNT);
        
        IF (reg_agregar.COUNT > 0) THEN
            SELECT NVL(MAX(tvrtsta_seq_no), 0)
            INTO secuencial
            FROM tvrtsta
            WHERE tvrtsta_pidm = pidm
                AND tvrtsta_tran_number = tran_number
            ;

            INSERT INTO TAISMGR.TVRTSTA (
                TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER, TVRTSTA_SEQ_NO, 
                TVRTSTA_TSTA_CODE, TVRTSTA_DATE_TSTA, 
                TVRTSTA_DLOC_CODE, TVRTSTA_COMMENTS, 
                TVRTSTA_ACTIVITY_DATE, TVRTSTA_USER_ID, TVRTSTA_DATA_ORIGIN
            ) SELECT pidm, tran_number, secuencial + rownum, 
                t.codigo, SYSDATE,
                t.dLocCode, t.valor,
                SYSDATE, USER, 'Tralix'
            FROM table(reg_agregar) t
            ;
        END IF;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            return 'INS_TVR:'||sqlerrm;
    END fn_insertar_tvrtsta;

    PROCEDURE pr_registrar_tvsta(
        codigo IN VARCHAR2,
        dLocCode IN VARCHAR2,
        valor IN VARCHAR2,
        registros IN OUT TY_TRALIX_TSTA_ARR
    ) IS
        registro TY_TRALIX_TSTA_OBJ;
    BEGIN
        registro := TY_TRALIX_TSTA_OBJ(codigo, dLocCode, valor);
        registros.EXTEND();
        registros(registros.COUNT) := registro;
    END pr_registrar_tvsta;

    /* El valor de tipo_transaccion tiene que ser 
    FA - Factura Anticipada
    FP - Factura Público en General
    FC - Factura al Cobro. Default
    */

    FUNCTION fn_registrar_tipo_factura(
        pidm in NUMBER,
        tran_number IN NUMBER,
        tipo_transaccion IN VARCHAR2,
        numFactura IN VARCHAR2,
        registros IN OUT TY_TRALIX_TSTA_ARR
    ) RETURN VARCHAR2 IS
        vlc_seqCodigo VARCHAR2(2 CHAR);
        codigo tvrtsta.TVRTSTA_TSTA_CODE%TYPE;
        -- registro TY_TRALIX_TSTA_OBJ;
    BEGIN
        pr_registrar_debug('fn_registrar_tipo_factura','tipoFactura:'||tipo_transaccion);

        IF (tipo_transaccion NOT IN ('FA', 'FC', 'FP')) THEN
            RETURN 'Tipo de factura no válida';
        END IF;

        vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number, 'T'); 
        codigo := 'T'||vlc_seqCodigo;
        pr_registrar_debug('fn_registrar',codigo||' - '||numFactura);
        pr_registrar_tvsta(codigo, tipo_transaccion, numFactura, registros);

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_registrar_tipo_factura;

    FUNCTION fn_registrar_direccion_fiscal(
        pidm in NUMBER,
        tran_number IN NUMBER,
        receptor IN TY_TRALIX_LINEA_03,
        registros IN OUT TY_TRALIX_TSTA_ARR
    ) RETURN VARCHAR2 IS
        vlc_comment tvrtsta.tvrtsta_comments%TYPE;
    BEGIN
        pr_registrar_debug('fn_registrar_direccion_fiscal', receptor.imprimir_linea);

        vlc_comment := receptor.calle;
        pr_registrar_tvsta('CL1', '', vlc_comment, registros);
        
        vlc_comment := receptor.numExterior;
        pr_registrar_tvsta('CL2', '', vlc_comment, registros);
        
        vlc_comment := receptor.colonia;
        pr_registrar_tvsta('CL3', '', vlc_comment, registros);
        
        vlc_comment := receptor.localidad;
        pr_registrar_tvsta('CIT', '', vlc_comment, registros);
        
        vlc_comment := receptor.estado;
        pr_registrar_tvsta('STA', '', vlc_comment, registros);
        
        vlc_comment := receptor.domFiscal;
        pr_registrar_tvsta('ZIP', '', vlc_comment, registros);
        
        vlc_comment := receptor.municipio;
        pr_registrar_tvsta('CNT', '', vlc_comment, registros);
        
        vlc_comment := receptor.pais;
        pr_registrar_tvsta('NAT', '', vlc_comment, registros);
        
        -- END LOOP;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'REG_DIR_FIS:'||sqlerrm;
    END fn_registrar_direccion_fiscal;

    FUNCTION fn_registrar_datos_fiscales(
        pidm in NUMBER,
        tran_number IN NUMBER,
        receptor IN TY_TRALIX_LINEA_03,
        registros IN OUT TY_TRALIX_TSTA_ARR
    ) RETURN VARCHAR2 IS
        numGrupo NUMBER := 0;
        vln_regSocial NUMBER := 1;
        vlc_razonSocial tvrtsta.tvrtsta_comments%TYPE;
        
        vlc_temporal VARCHAR2(500 CHAR);
        vlc_codigo VARCHAR2(3 CHAR);
        vlc_valor tvrtsta.tvrtsta_comments%TYPE;

    BEGIN
        IF (NVL(receptor.numGrupo, 0) < 1) THEN
            RETURN 'OP_EXITOSA';
        END IF;

        numGrupo := receptor.numGrupo;
        vlc_codigo := 'FC'||numGrupo;
        vlc_valor := receptor.rfc;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar_datos_fiscales',vlc_codigo||' - '||vlc_valor);

        vlc_codigo := 'RF'||numGrupo;
        vlc_valor := receptor.regimenFiscal;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar_datos_fiscales',vlc_codigo||' - '||vlc_valor);

        /* TODO: Ajustar a que segmente en varchar de 50 datos_factura.receptor.nombre */
        vlc_temporal := receptor.nombre;
        vlc_razonSocial := '';

        pr_registrar_debug('fn_registrar_datos_fiscales',vlc_temporal||' ('||LENGTH(vlc_temporal)||')');

        WHILE (LENGTH(vlc_temporal) > 100)
        LOOP
            vlc_razonSocial := SUBSTR(vlc_temporal, 1, 100);
            pr_registrar_debug('fn_registrar_datos_fiscales', 'SubSeccion:'||vln_regSocial||' Razon Social Temp:'||vlc_razonSocial);

            vlc_codigo := numGrupo||'R'||vln_regSocial;
            vlc_valor := vlc_razonSocial;
            pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
            pr_registrar_debug('fn_registrar_datos_fiscales',vlc_codigo||' - '||vlc_valor);

            vln_regSocial := vln_regSocial + 1;
            vlc_temporal := SUBSTR(vlc_temporal, 101, 500);
            pr_registrar_debug('fn_registrar_datos_fiscales','Nva subseccion:'||vln_regSocial||' '||
                vlc_temporal||' ('||LENGTH(vlc_temporal)||')');
        END LOOP;

        vlc_razonSocial := vlc_temporal;

        vlc_codigo := numGrupo||'R'||vln_regSocial;
        vlc_valor := vlc_razonSocial;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar_datos_fiscales',vlc_codigo||' - '||vlc_valor);

        vlc_codigo := 'UF'||numGrupo;
        vlc_valor := receptor.usoCFDI;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar_datos_fiscales',vlc_codigo||' - '||vlc_valor);

        vlc_codigo := 'RFC';
        vlc_valor := receptor.rfc;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar_datos_fiscales',vlc_codigo||' - '||vlc_valor);

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'REG_DAT_FISC:'||sqlerrm;
    END fn_registrar_datos_fiscales;

    FUNCTION fn_registrar_canc_1(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        motivo_canc IN VARCHAR2) 
        RETURN VARCHAR2 IS
        registros TY_TRALIX_TSTA_ARR;
        vlc_respCall VARCHAR2(1000 CHAR);
        vlc_seqCodigo VARCHAR2(2 CHAR);
        vlc_codigo VARCHAR2(3 CHAR);
        vlc_valor tvrtsta.tvrtsta_comments%TYPE;
        vlc_dloc_code TVRTSTA.TVRTSTA_DLOC_CODE%TYPE := '';
    BEGIN
        registros := TY_TRALIX_TSTA_ARR();
        vlc_codigo := 'PC';
        vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number, vlc_codigo);
        vlc_codigo := vlc_codigo || vlc_seqCodigo;

        FOR i IN (
            SELECT tvrtsta_comments
            FROM tvrtsta
            WHERE tvrtsta_pidm = pidm
                AND tvrtsta_tran_number = tran_number
                AND tvrtsta_tsta_code LIKE 'F0%'
            ORDER BY tvrtsta_tsta_code DESC, 
                tvrtsta_activity_date DESC
        ) LOOP
            vlc_valor := i.tvrtsta_comments;
            EXIT;
        END LOOP;

        IF (NVL(vlc_valor, '|') != '|') THEN
            FOR i IN (
                SELECT tvvdloc_code
                FROM tvvdloc
                WHERE tvvdloc_code = motivo_canc
            ) LOOP
                vlc_dloc_code := i.tvvdloc_code;
            END LOOP;

            pr_registrar_tvsta(vlc_codigo, vlc_dloc_code, vlc_valor, registros);

            vlc_respCall := fn_insertar_tvrtsta(pidm, tran_number, registros);
            IF (vlc_respCall != 'OP_EXITOSA') THEN
                RETURN vlc_respCall;
            END IF;
        END IF;

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_registrar_canc_1;

    FUNCTION fn_registrar(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        tran_number_orig IN NUMBER,
        uuidTralix IN VARCHAR2,
        datos_factura IN TY_TRALIX_FACTURA,
        datos_compPago IN TY_TRALIX_COMPPAGO,
        tipo_factura IN VARCHAR2)
        RETURN VARCHAR2 IS

        vlc_respCall VARCHAR2(1000 CHAR);
        vlc_seqCodigo VARCHAR2(2 CHAR);

        vlc_codigo VARCHAR2(3 CHAR);
        vlc_valor tvrtsta.tvrtsta_comments%TYPE;
        vlc_dloc tvrtsta.tvrtsta_dloc_code%TYPE;

        registros TY_TRALIX_TSTA_ARR;
        receptor TY_TRALIX_LINEA_03;
        secuencial NUMBER;

        vln_tipo_factura VARCHAR2(10 CHAR);
    BEGIN
        registros := TY_TRALIX_TSTA_ARR();

        pr_registrar_debug('fn_registrar','tipo_factura:'||tipo_factura);

        vln_tipo_factura := tipo_factura;
        IF (tipo_factura != 'FP') THEN
            vlc_valor := datos_factura.info_gral_comprobante.cfdi;
            /* TODO: Ver si efectivamente lleva prioridad FP sobre FA */
            -- IF (datos_factura.receptor.esPubGral = 'TRUE') THEN
            --     vln_tipo_factura := 'FP';
            -- END IF;
        ELSE
            vlc_valor := datos_compPago.info_gral_comprobante.cfdi;
            vln_tipo_factura := 'FC';
        END IF;
        pr_registrar_debug('fn_registrar',vlc_valor || ' - ' || vlc_valor||' - '||vln_tipo_factura);

        vlc_respCall := fn_registrar_tipo_factura(pidm, tran_number, vln_tipo_factura, 
            vlc_valor, registros);
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            return vlc_respCall;
        END IF;

        -- pr_registrar_debug('fn_registrar','F'||vlc_seqCodigo);
        vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number, 'F');
        -- pr_registrar_debug('fn_registrar','F'||vlc_seqCodigo);
        vlc_codigo := 'F'||vlc_seqCodigo;
        pr_registrar_debug('fn_registrar',vlc_codigo||' - '||vlc_valor);

        IF (tipo_factura != 'FP') THEN
            vlc_dloc := datos_factura.info_gral_comprobante.metodoPago;
        ELSE
            vlc_dloc := 'PUE';
        END IF;
        pr_registrar_tvsta(vlc_codigo, vlc_dloc, vlc_valor, registros);

        -- pr_registrar_tvsta('SOC', '', datos_factura.sociedad, registros);
        vlc_codigo := 'SOC';

        IF (tipo_factura != 'FP') THEN
            vlc_valor := 'IPADE'||datos_factura.receptor.numEntidad;  
        ELSE
            vlc_valor := 'IPADE'||datos_compPago.receptor.numEntidad;  
        END IF;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar',vlc_codigo||' - '||vlc_valor);

        vlc_seqCodigo := SUBSTR(vlc_seqCodigo, 2, 1);
        vlc_codigo := 'FV'||vlc_seqCodigo;        
        IF (tipo_factura != 'FP') THEN
            vlc_valor := TO_CHAR(datos_factura.info_gral_comprobante.fecha, 'DD-MON-YYYY');
        ELSE
            vlc_valor := TO_CHAR(datos_compPago.info_gral_comprobante.fecha, 'DD-MON-YYYY');
        END IF;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar',vlc_codigo||' - '||vlc_valor);

        -- pr_registrar_tvsta('UI'||vlc_seqCodigo, '', datos_factura.uuid, registros);
        vlc_valor := uuidTralix;
        -- IF (tipo_factura = 'FC') THEN
        --     vlc_codigo := 'UI'||vlc_seqCodigo;
        --     pr_registrar_tvsta('UI'||vlc_seqCodigo, '', uuidTralix, registros);
        -- ELSE
            vlc_codigo := 'UID';
            -- pr_registrar_tvsta('UID', '', uuidTralix, registros);    
        -- END IF;
        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar',vlc_codigo||' - '||vlc_valor);
        
        -- pr_registrar_tvsta('FP'||vlc_seqCodigo, '', datos_factura.formaPago, registros);
        vlc_codigo := 'FP'||vlc_seqCodigo;
        IF (tipo_factura != 'FP') THEN
            vlc_valor := datos_factura.info_gral_comprobante.formaPago;
        ELSE
            vlc_valor := 'PUE';
        END IF;

        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        pr_registrar_debug('fn_registrar',vlc_codigo||' - '||vlc_valor);
        -- vln_secuencial := vln_secuencial + 1;
        
        IF (tipo_factura != 'FP') THEN
            receptor := datos_factura.receptor;
        ELSE
            receptor := datos_comppago.receptor;
        END IF;
        vlc_respCall := fn_registrar_datos_fiscales(
            pidm, tran_number, 
            receptor, 
            registros
        );

        IF (vlc_respCall != 'OP_EXITOSA') THEN
            return vlc_respCall;
        END IF;

        vlc_respCall := fn_registrar_direccion_fiscal(
            pidm, tran_number, receptor, registros
        );
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        IF (tipo_factura = 'FP') THEN
            vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number, 'DR');
            vlc_codigo := 'DR'||vlc_seqCodigo;
            vlc_valor := datos_compPago.doctoRel.uuidPagoOriginal;

            pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);
        END IF;

        vlc_respCall := fn_insertar_tvrtsta(pidm, tran_number, registros);
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        IF (tipo_factura = 'FP') THEN
            SELECT NVL(MAX(tvrtsta_seq_no), 0) + 1
            INTO secuencial
            FROM tvrtsta
            WHERE tvrtsta_pidm = pidm
                AND tvrtsta_tran_number = tran_number_orig
            ;

            vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number, 'UI');

            INSERT INTO TAISMGR.TVRTSTA (
                TVRTSTA_PIDM, TVRTSTA_TRAN_NUMBER, TVRTSTA_SEQ_NO, 
                TVRTSTA_TSTA_CODE, TVRTSTA_DATE_TSTA, 
                TVRTSTA_DLOC_CODE, TVRTSTA_COMMENTS, 
                TVRTSTA_ACTIVITY_DATE, TVRTSTA_USER_ID, TVRTSTA_DATA_ORIGIN
            ) VALUES (
                pidm, tran_number_orig, secuencial,
                'UI'||vlc_seqCodigo, SYSDATE,
                '', uuidTralix,
                SYSDATE, USER, 'Tralix'
            );
        END IF;

        -- COMMIT;

        pr_registrar_debug('fn_registrar','RespCall:'||vlc_respCall);

        RETURN 'OP_EXITOSA';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN sqlerrm;
    END fn_registrar;

    FUNCTION fn_cancelar_factura(
        pidm IN NUMBER,
        tran_number IN NUMBER,
        motivo_sust IN VARCHAR2) 
        RETURN VARCHAR2 IS
        registros TY_TRALIX_TSTA_ARR;
        vlc_respCall VARCHAR2(1000 CHAR);
        vlc_seqCodigo VARCHAR2(2 CHAR);
        vlc_codigo VARCHAR2(3 CHAR);
        vlc_valor tvrtsta.tvrtsta_comments%TYPE;
        vlc_dloc_code TVRTSTA.TVRTSTA_DLOC_CODE%TYPE := '';
    BEGIN
        registros := TY_TRALIX_TSTA_ARR();
        vlc_codigo := 'CA';
        vlc_seqCodigo := fn_determina_sigNumero(pidm, tran_number, vlc_codigo);
        vlc_codigo := vlc_codigo || vlc_seqCodigo;
        -- vlc_valor := motivo_sust;

        FOR j IN (
            SELECT tvrtsta_comments
            FROM tvrtsta
            WHERE tvrtsta_pidm = pidm
                AND tvrtsta_tran_number = tran_number
                AND tvrtsta_tsta_code LIKE 'PC%'
            ORDER BY tvrtsta_tsta_code DESC, 
                tvrtsta_activity_date DESC
        ) LOOP
            vlc_valor := j.tvrtsta_comments;
            EXIT;
        END LOOP;

        FOR i IN (
            SELECT tvvdloc_code
            FROM tvvdloc
            WHERE tvvdloc_code = motivo_sust
        ) LOOP
            vlc_dloc_code := i.tvvdloc_code;
        END LOOP;

        pr_registrar_tvsta(vlc_codigo, vlc_dloc_code, vlc_valor, registros);

        vlc_respCall := fn_insertar_tvrtsta(pidm, tran_number, registros);
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        RETURN 'OP_EXITOSA';
    END fn_cancelar_factura;

    FUNCTION fn_sustituir_factura(
        pidm_canc IN NUMBER,
        tran_number_canc IN NUMBER,
        nuevo_guid IN VARCHAR2) 
        RETURN VARCHAR2 IS
        registros TY_TRALIX_TSTA_ARR;
        vlc_respCall VARCHAR2(1000 CHAR);
        vlc_seqCodigo VARCHAR2(2 CHAR);
        vlc_codigo VARCHAR2(3 CHAR);
        vlc_valor tvrtsta.tvrtsta_comments%TYPE;
    BEGIN
        registros := TY_TRALIX_TSTA_ARR();
        vlc_codigo := 'RCL';
        vlc_valor := nuevo_guid;

        pr_registrar_tvsta(vlc_codigo, '', vlc_valor, registros);

        vlc_respCall := fn_insertar_tvrtsta(pidm_canc, tran_number_canc, registros);
        IF (vlc_respCall != 'OP_EXITOSA') THEN
            RETURN vlc_respCall;
        END IF;

        RETURN 'OP_EXITOSA';
    END fn_sustituir_factura;
END TZKRSTA;
/
show errors;

