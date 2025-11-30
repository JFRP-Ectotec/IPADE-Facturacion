CREATE OR REPLACE PACKAGE GZKNUMB IS
    FUNCTION monto_escrito (p_monto  IN NUMBER) RETURN VARCHAR2;
    PROCEDURE cientos (p_cantidad IN VARCHAR2,
        p_monto    IN NUMBER,
        p_parte    IN OUT VARCHAR2,
        p_longitud IN OUT NUMBER,
        p_cero     IN VARCHAR2);
    PROCEDURE decenas (p_cantidad IN VARCHAR2,
        p_parte    IN OUT VARCHAR2,
        p_longitud IN OUT NUMBER);
    PRAGMA RESTRICT_REFERENCES(cientos, WNDS);
    PRAGMA RESTRICT_REFERENCES(decenas, WNDS);
    PRAGMA RESTRICT_REFERENCES(monto_escrito, WNDS);
END GZKNUMB;
/
show errors;

CREATE OR REPLACE PACKAGE BODY GZKNUMB IS
/***********************************************************************/
/* MONTO_ESCRITO: Retorna el valor en letras de una cantidad numerica. */
/***********************************************************************/
    FUNCTION monto_escrito (p_monto  IN NUMBER) RETURN VARCHAR2 IS
        num_letra VARCHAR2(18);
        longitud  NUMBER(10);
        contador  NUMBER(10);
        aux       VARCHAR2(2);
        parte     VARCHAR2(20);
        partee     VARCHAR2(30);
        tempo     VARCHAR2(18);
        may       NUMBER(14,2);
        mil_mil   VARCHAR2(50);
        p_letra   VARCHAR2(250);
    BEGIN
        -- Coloca ceros a la izquierda hasta completar 16 digitos
        tempo := SUBSTR(LTRIM(TO_CHAR(p_monto,'000000000000.00')),1,16);
        num_letra := tempo;
        contador  := 1;

        -- Evalua la primera terna (Millardos) del monto
        IF SUBSTR(num_letra,1,3) <> '000' THEN
        -- verifica si hay valor en la centena
            IF SUBSTR(num_letra,1,1) <> '0' THEN
                aux      := SUBSTR(num_letra,1,1);
                cientos (aux,p_monto,parte,longitud,SUBSTR(num_letra,2,2));
                contador := contador + longitud;
                p_letra  := parte;
            END IF;
            -- Evalua si hay valor en las decenas
            IF SUBSTR(num_letra,2,2) <> '00' THEN
                aux      := SUBSTR(num_letra,2,2);
                decenas (aux,parte,longitud);
                p_letra  := SUBSTR(p_letra,1,contador)||parte;
                contador := contador + longitud;
            END IF;
            -- Evalua si el resto del numero tiene valor
            IF SUBSTR(num_letra,4,3) = '000' THEN -- E.A.   POSICION 4 AL 9   '000000000'
                MIL_MIL  := SUBSTR(p_letra,1,contador)||'MIL MILLONES ';
                contador := contador + 13;
            ELSE
                MIL_MIL  := SUBSTR(p_letra,1,contador)||'MIL ';
                contador := contador + 4;
            END IF;
        END IF;

    -- Blanquea p_letra
        p_letra := NULL;

        IF SUBSTR(num_letra,4,5) = '00000' AND SUBSTR(p_monto,1,1)=',' THEN
            cientos(0,SUBSTR(num_letra,14,2),parte,longitud,SUBSTR(num_letra,2,2));
            decenas(SUBSTR(num_letra,14,2),partee,longitud);
            contador := contador + longitud;
            p_letra  := parte || partee;
        END IF;

        -- Evalua la segunda terna (Millones) del monto
        IF SUBSTR(num_letra,4,3) <> '000' THEN
            -- verifica si hay valor en la centena
            IF SUBSTR(num_letra,4,1) <> '0' THEN
                aux      := SUBSTR(num_letra,4,1);
                cientos (aux,p_monto,parte,longitud,SUBSTR(num_letra,5,2));
                contador := contador + longitud;
                p_letra  := parte;
            END IF;
            -- evalua si hay valor en las decenas
            IF SUBSTR(num_letra,5,2) <> '00' THEN
                aux      := SUBSTR(num_letra,5,2);
                decenas (aux,parte,longitud);
                p_letra  := SUBSTR(p_letra,1,contador)||parte;
                contador := contador + longitud;
            END IF;

            -- Verifica si la terna es mas de un millon (Contador es mayor que 4)
            IF contador = 4 THEN
                p_letra  := SUBSTR(p_letra,1,contador)||'MILLON ';
                contador := contador + 7;
            ELSE
                p_letra  := SUBSTR(p_letra,1,contador)||'MILLONES ';
                contador := contador + 9;
            END IF;
        END IF;

        -- Evalua la tercera terna (miles) del numero
        IF SUBSTR(num_letra,7,3) <> '000' THEN
        -- Evalua si las centenas tienen valor
            IF SUBSTR(num_letra,7,1) <> '0' THEN
                aux      := SUBSTR(num_letra,7,1);
                cientos(aux,p_monto,parte,longitud,SUBSTR(num_letra,8,2));
                p_letra  := SUBSTR(p_letra,1,contador)||parte;
                contador := contador + longitud;
            END IF;
            -- Evalua si las decenas tienen valor
            IF SUBSTR(num_letra,8,2) <> '00' THEN
                aux      := SUBSTR(num_letra,8,2);
                decenas(aux,parte,longitud);
                p_letra  := SUBSTR(p_letra,1,contador)||parte;
                contador := contador + longitud;
            END IF;
            -- Sufija el monto en letras  con la palabra MIL e incrementa el contador
            p_letra     := SUBSTR(p_letra,1,contador)||'MIL ';
            contador    := contador + 4;
        END IF;

        -- Evalua la cuarta terna (cientos) del numero
        IF SUBSTR(num_letra,10,3) <> '000' THEN
        -- Evalua si la centena tiene valor
            IF SUBSTR(num_letra,10,1) <> '0' THEN
                aux      := SUBSTR(num_letra,10,1);
                cientos(aux,p_monto,parte,longitud,SUBSTR(num_letra,11,2));
                p_letra  := SUBSTR(p_letra,1,contador)||parte;
                contador := contador + longitud;
            END IF;
            -- Evalua si la decena tiene valor
            IF SUBSTR(num_letra,11,2) <> '00' THEN
                aux      := SUBSTR(num_letra,11,2);
                decenas(aux,parte,longitud);
                p_letra  := SUBSTR(p_letra,1,contador)||parte;
                contador := contador + longitud;
            END IF;
        END IF;

        -- Si el monto involucra cantidades de millon, coloca ' DE '
        IF SUBSTR(num_letra,1,6) != '000000' AND  SUBSTR(num_letra,7,6) = '000000'  THEN
            p_letra := mil_mil || SUBSTR(p_letra,1,contador+1) ||
                    --' BOLIVARES CON ' ||
                    ' PESOS CON ' ||
                    SUBSTR(num_letra,14,2) ||'/100';
        ELSIF SUBSTR(num_letra,4,5) = '00000' AND SUBSTR(p_monto,1,1)=',' THEN
            p_letra := mil_mil || p_letra;
        ELSE
            p_letra := mil_mil || SUBSTR(p_letra,1,contador+1) ||
                    --' BOLIVARES CON ' ||
                    ' PESOS CON ' ||
                    SUBSTR(num_letra,14,2) ||'/100';
        END IF;

        -- Elimina doble espacio en blanco
        p_letra := REPLACE(p_letra,'  ',' ');
        p_letra := REPLACE (p_letra, 'UN CON','UNO CON');

        -- RETURN(RPAD(p_letra,LENGTH(p_letra)+5,'*'));
        RETURN p_letra;
    END monto_escrito;

    /***********************************************************************/
    /* CIENTOS: Retorna el valor en letras de las centenas de una cantidad */
    /*          y la longitud que esta ocupa.                              */
    /***********************************************************************/
    PROCEDURE cientos (p_cantidad IN VARCHAR2,
                    p_monto    IN NUMBER,
                    p_parte    IN OUT VARCHAR2,
                    p_longitud IN OUT NUMBER,
                    p_cero     IN VARCHAR2) IS
    BEGIN
        IF p_cantidad = '1'  THEN
            IF p_cero  = '00' THEN
                p_parte := 'CIEN ';
            ELSE
                p_parte := 'CIENTO ';
            END IF;
        ELSIF p_cantidad = '2' THEN
            p_parte    := 'DOSCIENTOS ';
        ELSIF p_cantidad = '3' THEN
            p_parte    := 'TRESCIENTOS ';
        ELSIF p_cantidad = '4' THEN
            p_parte    := 'CUATROCIENTOS ';
        ELSIF p_cantidad = '5' THEN
            p_parte    := 'QUINIENTOS ';
        ELSIF p_cantidad = '6' THEN
            p_parte    := 'SEISCIENTOS ';
        ELSIF p_cantidad = '7' THEN
            p_parte    := 'SETECIENTOS ';
        ELSIF p_cantidad = '8' THEN
            p_parte    := 'OCHOCIENTOS ';
        ELSIF p_cantidad = '9' THEN
            p_parte    := 'NOVECIENTOS ';
        END IF;
        IF p_cantidad = '0'  THEN
            p_parte    := 'CERO CON ';
        END IF;
        p_longitud := LENGTH(p_parte);
    END cientos;

/****************************************************************************/
/* DECENAS: Retorna el valor en letras de una cantidad expresada en decenas */
/*          y la longitud que esta ocupa.                                   */
/****************************************************************************/

    PROCEDURE decenas (p_cantidad IN VARCHAR2,
                    p_parte    IN OUT VARCHAR2,
                    p_longitud IN OUT NUMBER) IS
    BEGIN
        IF p_cantidad = '01' THEN
            p_parte   := 'UN ';
        ELSIF p_cantidad = '02' THEN
            p_parte   := 'DOS ';
        ELSIF p_cantidad = '03' THEN
            p_parte   := 'TRES ';
        ELSIF p_cantidad = '04' THEN
            p_parte   := 'CUATRO ';
        ELSIF p_cantidad = '05' THEN
            p_parte   := 'CINCO ';
        ELSIF p_cantidad = '06' THEN
            p_parte   := 'SEIS ';
        ELSIF p_cantidad = '07' THEN
            p_parte   := 'SIETE ';
        ELSIF p_cantidad = '08' THEN
            p_parte   := 'OCHO ';
        ELSIF p_cantidad = '09' THEN
            p_parte   := 'NUEVE ';
        ELSIF p_cantidad = '10' THEN
            p_parte   := 'DIEZ ';
        ELSIF p_cantidad = '11' THEN
            p_parte   := 'ONCE ';
        ELSIF p_cantidad = '12' THEN
            p_parte   := 'DOCE ';
        ELSIF p_cantidad = '13' THEN
            p_parte   := 'TRECE ';
        ELSIF p_cantidad = '14' THEN
            p_parte   := 'CATORCE ';
        ELSIF p_cantidad = '15' THEN
            p_parte   := 'QUINCE ';
        ELSIF p_cantidad = '16' THEN
            p_parte   := 'DIECISEIS ';
        ELSIF p_cantidad = '17' THEN
            p_parte   := 'DIECISIETE ';
        ELSIF p_cantidad = '18' THEN
            p_parte   := 'DIECIOCHO ';
        ELSIF p_cantidad = '19' THEN
            p_parte   := 'DIECINUEVE ';
        ELSIF p_cantidad = '20' THEN
            p_parte   := 'VEINTE ';
        ELSIF p_cantidad = '21' THEN
            p_parte   := 'VEINTIUN ';
        ELSIF p_cantidad = '22' THEN
            p_parte   := 'VEINTIDOS ';
        ELSIF p_cantidad = '23' THEN
            p_parte   := 'VEINTITRES ';
        ELSIF p_cantidad = '24' THEN
            p_parte   := 'VEINTICUATRO ';
        ELSIF p_cantidad = '25' THEN
            p_parte   := 'VEINTICINCO ';
        ELSIF p_cantidad = '26' THEN
            p_parte   := 'VEINTISEIS ';
        ELSIF p_cantidad = '27' THEN
            p_parte   := 'VEINTISIETE ';
        ELSIF p_cantidad = '28' THEN
            p_parte   := 'VEINTIOCHO ';
        ELSIF p_cantidad = '29' THEN
            p_parte   := 'VEINTINUEVE ';
        ELSIF p_cantidad = '30' THEN
            p_parte   := 'TREINTA ';
        ELSIF p_cantidad = '31' THEN
            p_parte   := 'TREINTA Y UN ';
        ELSIF p_cantidad = '32' THEN
            p_parte   := 'TREINTA Y DOS ';
        ELSIF p_cantidad = '33' THEN
            p_parte   := 'TREINTA Y TRES ';
        ELSIF p_cantidad = '34' THEN
            p_parte   := 'TREINTA Y CUATRO ';
        ELSIF p_cantidad = '35' THEN
            p_parte   := 'TREINTA Y CINCO ';
        ELSIF p_cantidad = '36' THEN
            p_parte   := 'TREINTA Y SEIS ';
        ELSIF p_cantidad = '37' THEN
            p_parte   := 'TREINTA Y SIETE ';
        ELSIF p_cantidad = '38' THEN
            p_parte   := 'TREINTA Y OCHO ';
        ELSIF p_cantidad = '39' THEN
            p_parte   := 'TREINTA Y NUEVE ';
        ELSIF p_cantidad = '40' THEN
            p_parte   := 'CUARENTA ';
        ELSIF p_cantidad = '41' THEN
            p_parte   := 'CUARENTA Y UN ';
        ELSIF p_cantidad = '42' THEN
            p_parte   := 'CUARENTA Y DOS ';
        ELSIF p_cantidad = '43' THEN
            p_parte   := 'CUARENTA Y TRES ';
        ELSIF p_cantidad = '44' THEN
            p_parte   := 'CUARENTA Y CUATRO ';
        ELSIF p_cantidad = '45' THEN
            p_parte   := 'CUARENTA Y CINCO ';
        ELSIF p_cantidad = '46' THEN
            p_parte   := 'CUARENTA Y SEIS ';
        ELSIF p_cantidad = '47' THEN
            p_parte   := 'CUARENTA Y SIETE ';
        ELSIF p_cantidad = '48' THEN
            p_parte   := 'CUARENTA Y OCHO ';
        ELSIF p_cantidad = '49' THEN
            p_parte   := 'CUARENTA Y NUEVE ';
        ELSIF p_cantidad = '50' THEN
            p_parte   := 'CINCUENTA ';
        ELSIF p_cantidad = '51' THEN
            p_parte   := 'CINCUENTA Y UN ';
        ELSIF p_cantidad = '52' THEN
            p_parte   := 'CINCUENTA Y DOS ';
        ELSIF p_cantidad = '53' THEN
            p_parte   := 'CINCUENTA Y TRES ';
        ELSIF p_cantidad = '54' THEN
            p_parte   := 'CINCUENTA Y CUATRO ';
        ELSIF p_cantidad = '55' THEN
            p_parte   := 'CINCUENTA Y CINCO ';
        ELSIF p_cantidad = '56' THEN
            p_parte   := 'CINCUENTA Y SEIS ';
        ELSIF p_cantidad = '57' THEN
            p_parte   := 'CINCUENTA Y SIETE ';
        ELSIF p_cantidad = '58' THEN
            p_parte   := 'CINCUENTA Y OCHO ';
        ELSIF p_cantidad = '59' THEN
            p_parte   := 'CINCUENTA Y NUEVE ';
        ELSIF p_cantidad = '60' THEN
            p_parte   := 'SESENTA ';
        ELSIF p_cantidad = '61' THEN
            p_parte   := 'SESENTA Y UN ';
        ELSIF p_cantidad = '62' THEN
            p_parte   := 'SESENTA Y DOS ';
        ELSIF p_cantidad = '63' THEN
            p_parte   := 'SESENTA Y TRES ';
        ELSIF p_cantidad = '64' THEN
            p_parte   := 'SESENTA Y CUATRO ';
        ELSIF p_cantidad = '65' THEN
            p_parte   := 'SESENTA Y CINCO ';
        ELSIF p_cantidad = '66' THEN
            p_parte   := 'SESENTA Y SEIS ';
        ELSIF p_cantidad = '67' THEN
            p_parte   := 'SESENTA Y SIETE ';
        ELSIF p_cantidad = '68' THEN
            p_parte   := 'SESENTA Y OCHO ';
        ELSIF p_cantidad = '69' THEN
            p_parte   := 'SESENTA Y NUEVE ';
        ELSIF p_cantidad = '70' THEN
            p_parte   := 'SETENTA ';
        ELSIF p_cantidad = '71' THEN
            p_parte   := 'SETENTA Y UN ';
        ELSIF p_cantidad = '72' THEN
            p_parte   := 'SETENTA Y DOS ';
        ELSIF p_cantidad = '73' THEN
            p_parte   := 'SETENTA Y TRES ';
        ELSIF p_cantidad = '74' THEN
            p_parte   := 'SETENTA Y CUATRO ';
        ELSIF p_cantidad = '75' THEN
            p_parte   := 'SETENTA Y CINCO ';
        ELSIF p_cantidad = '76' THEN
            p_parte   := 'SETENTA Y SEIS ';
        ELSIF p_cantidad = '77' THEN
            p_parte   := 'SETENTA Y SIETE ';
        ELSIF p_cantidad = '78' THEN
            p_parte   := 'SETENTA Y OCHO ';
        ELSIF p_cantidad = '79' THEN
            p_parte   := 'SETENTA Y NUEVE ';
        ELSIF p_cantidad = '80' THEN
            p_parte   := 'OCHENTA ';
        ELSIF p_cantidad = '81' THEN
            p_parte   := 'OCHENTA Y UN ';
        ELSIF p_cantidad = '82' THEN
            p_parte   := 'OCHENTA Y DOS ';
        ELSIF p_cantidad = '83' THEN
            p_parte   := 'OCHENTA Y TRES ';
        ELSIF p_cantidad = '84' THEN
            p_parte   := 'OCHENTA Y CUATRO ';
        ELSIF p_cantidad = '85' THEN
            p_parte   := 'OCHENTA Y CINCO ';
        ELSIF p_cantidad = '86' THEN
            p_parte   := 'OCHENTA Y SEIS ';
        ELSIF p_cantidad = '87' THEN
            p_parte   := 'OCHENTA Y SIETE ';
        ELSIF p_cantidad = '88' THEN
            p_parte   := 'OCHENTA Y OCHO ';
        ELSIF p_cantidad = '89' THEN
            p_parte   := 'OCHENTA Y NUEVE ';
        ELSIF p_cantidad = '90' THEN
            p_parte   := 'NOVENTA ';
        ELSIF p_cantidad = '91' THEN
            p_parte   := 'NOVENTA Y UN ';
        ELSIF p_cantidad = '92' THEN
            p_parte   := 'NOVENTA Y DOS ';
        ELSIF p_cantidad = '93' THEN
            p_parte   := 'NOVENTA Y TRES ';
        ELSIF p_cantidad = '94' THEN
            p_parte   := 'NOVENTA Y CUATRO ';
        ELSIF p_cantidad = '95' THEN
            p_parte   := 'NOVENTA Y CINCO ';
        ELSIF p_cantidad = '96' THEN
            p_parte   := 'NOVENTA Y SEIS ';
        ELSIF p_cantidad = '97' THEN
            p_parte   := 'NOVENTA Y SIETE ';
        ELSIF p_cantidad = '98' THEN
            p_parte   := 'NOVENTA Y OCHO ';
        ELSIF p_cantidad = '99' THEN
            p_parte   := 'NOVENTA Y NUEVE ';
        END IF;
    p_longitud := LENGTH(p_parte);
    END decenas;
END GZKNUMB;
/
show errors;