grant execute on utl_http to bia;
grant execute on dbms_lock to bia;
 
BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'prueba_omar_acl_file.xml', 
    description  => 'A test of the ACL functionality',
    principal    => 'IA',
    is_grant     => TRUE, 
    privilege    => 'connect',
    start_date   => SYSTIMESTAMP,
    end_date     => NULL);
end;
 
begin
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => 'prueba_omar_acl_file.xml',
    host        => '172.23.0.117', 
    lower_port  => 3000,
    upper_port  => NULL);    
end; 