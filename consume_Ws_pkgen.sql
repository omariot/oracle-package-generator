create or replace procedure ws_pkgen( p_schema in varchar2, p_tablename in varchar2, p_typename in varchar2, p_typelist in varchar2, p_packagename  in varchar2) is
  req utl_http.req;
  res utl_http.resp;
  url varchar2(4000) := 'http://172.23.0.117:3000/api/pkgen/types?';
  name varchar2(4000);
  value clob;
  buffer varchar2(4000); 
  content varchar2(4000) := '{"owner": "'||p_schema||'","tablename": "'||p_tablename||'","typename": "'||p_typename||'","typelist": "'||p_typelist||'"}';
  --{"room":"'||p_room_id||'", "partySize":"'||p_party_Size||'"}';
 
begin
  req := utl_http.begin_request(url, 'POST',' HTTP/1.1');
  utl_http.set_header(req, 'user-agent', 'mozilla/4.0'); 
  utl_http.set_header(req, 'Content-Type', 'application/json'); 
  utl_http.set_header(req, 'Content-Length', length(content));
 
  utl_http.write_text(req, content);
  res := utl_http.get_response(req);
dbms_output.put_line('Extraccion de datos:');
  -- process the response from the HTTP call
  begin
    loop
      utl_http.read_line(res, value, TRUE);
      INSERT INTO tc.datatemptc (CAMPO, FECHA, VALOR) VALUES ('PRUEBAWS', SYSDATE, value); commit;
      dbms_output.put_line(value);  
      --utl_http.read_line(res, buffer);
      --dbms_output.put_line(buffer);
    end loop;
    utl_http.end_response(res);
  exception
    when utl_http.end_of_body then
      utl_http.end_response(res);
    WHEN utl_http.too_many_requests THEN
      dbms_output.put_line('Demasiadas conexiones');  
      utl_http.end_response(res);
    WHEN UTL_HTTP.REQUEST_FAILED THEN
      utl_http.end_response(res);
    when others then
        utl_http.end_response(res);
  end;
end ws_pkgen;