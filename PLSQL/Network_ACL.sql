DECLARE
    -- vlc_acl VARCHAR2(200 CHAR) := '/sys/acls/tralix_v01.xml';
    vlc_acl VARCHAR2(200 CHAR) := 'NETWORK_ACL_3BA6184F866D6C3BE063D8021FAC7FEF';

BEGIN
    -- DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
    --     acl => vlc_acl,
    --     description => 'Permitir conexión a Tralix',
    --     principal => 'PUBLIC',
    --     is_grant => TRUE,
    --     privilege => 'connect',
    --     start_date => SYSTIMESTAMP,
    --     end_date => NULL);

    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
        acl => vlc_acl,
        principal => 'IPADEDEV',
        is_grant => true,
        privilege => 'resolve');

    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
        acl => vlc_acl,
        principal => 'IPADEDEV',
        is_grant => true,
        privilege => 'connect');

    -- DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
    --     acl => vlc_acl,
    --     host => 'mstest.ipade.mx');

    COMMIT;
END;
/

SELECT * FROM DBA_NETWORK_ACLS
-- WHERE acl = '/sys/acls/tralix_v01.xml'
;

SELECT * FROM DBA_NETWORK_ACL_PRIVILEGES
WHERE acl = 'NETWORK_ACL_3BA6184F866D6C3BE063D8021FAC7FEF'
;