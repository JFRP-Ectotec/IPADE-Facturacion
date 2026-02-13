DECLARE
    vlc_response VARCHAR2(500 CHAR) := '{"uuid": "A65087A5-87A6-4E52-A847-C112D090A258", "fecha": "2025-03-13 11:09:16.0", "serie": "", "folio": "", "rfc": "", "iva": "", "monto": "", "descuento": "", "subtotal": "", "tipoCambio": "", "tipoMoneda": "", "idCfd": "161b80698f6bfb29ba85be68a1c14183", "idSucursal": "", "status": "", "produccion": false,"fechaCancelacion": "2026-02-14", "animo":"Galeon"}';

    lc_fechaCancBag VARCHAR2(30) := '"fechaCancelacion": "';
    ln_indice NUMBER := 0;
    ln_indFin NUMBER := 0;
BEGIN
    ln_indice := INSTR(vlc_response, lc_fechaCancBag);
    ln_indFin := INSTR(vlc_response, '"', ln_indice + LENGTH(lc_fechaCancBag));
    dbms_output.put_line('Longitud: '||LENGTH(lc_fechaCancBag));
    dbms_output.put_line(ln_indice || ' - ' || ln_indFin);
    dbms_output.put_line(SUBSTR(vlc_response, ln_indice + LENGTH(lc_fechaCancBag), 
        ln_indFin - (ln_indice + LENGTH(lc_fechaCancBag))));
END;


DECLARE
    vlc_response VARCHAR2(300 CHAR) := '03 - 201 - Exito';
    ln_indice NUMBER := 0;
    ln_indFin NUMBER := 0;
    vlc_tagBuscar VARCHAR2(100 CHAR) := ' - ';
BEGIN
    ln_indice := INSTR(vlc_response, vlc_tagBuscar);
    dbms_output.put_line(SUBSTR(vlc_response, 1, ln_indice - 1));
END;