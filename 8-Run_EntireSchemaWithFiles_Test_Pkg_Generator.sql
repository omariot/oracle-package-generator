-- NOTE:  Las tablas deben contener Primary Key para poder generar correctamente el código
-- NOTE:  Debe activar la salida por Output del editor PLSQL
set serveroutput on

DECLARE
    vScripts        TSCRIPTS := TSCRIPTS();
    vSchema         VARCHAR2(30) := USER;
    vTableName      VARCHAR2(30) := NULL;
    vTypeName       VARCHAR2(30) := NULL;
    vTypeList       VARCHAR2(30) := NULL;
    vPackageName    VARCHAR2(30) := NULL;
    vFilename       VARCHAR2(256):= NULL;
    
    vTableList      PKG_GENERATOR.tTables := PKG_GENERATOR.tTables();
    
BEGIN
    vTableList.DELETE;
    vTableList := PKG_GENERATOR.getTableList(vSchema);
    
    FOR i IN 1 .. vTableList.COUNT LOOP
        
        vTableName   := vTableList(i).table_name;
        vTypeName    := PKG_GENERATOR.COMPACTNAME(vTableName||'_OBJ');
        vTypeList    := PKG_GENERATOR.COMPACTNAME(vTableName||'_LIST');
        vPackageName := PKG_GENERATOR.COMPACTNAME('PKG_'||vTableName);
        
        
        --  Generando Scripts del Type Object
        vScripts.DELETE;
        vScripts := PKG_GENERATOR.generateTypeScript(inOwner     => vSchema,
                                                        inTableName => vTableName,
                                                        inTypeName  => vTypeName,
                                                        inTypeList  => vTypeList);
                                                        
        /*
        FOR i IN 1..vScripts.COUNT LOOP
           DBMS_OUTPUT.PUT_LINE(vScripts(i).linea);
        END LOOP;
        */
        vFilename    := vTableName||'_types.sql';
        PKG_GENERATOR.createScriptFile(
                                inDirectory     => 'DIR_PKGEN',
                                inFilename      => vFilename,
                                inScripts       => vScripts
                              );
        
        -- Generando Script del Package Utilizando el Type Object
        vScripts.DELETE;
        vScripts := PKG_GENERATOR.generatePackageScript( inOwner         => vSchema,
                                                            inTableName     => vTableName,
                                                            inPackageName   => vPackageName,
                                                            inTypeName      => vTypeName,
                                                            inTypeList      => vTypeList);        
                                                        
        /*
        FOR i IN 1..vScripts.COUNT LOOP
           DBMS_OUTPUT.PUT_LINE(vScripts(i).linea);
        END LOOP;
        */
        vFilename    := vTableName||'_pkgs.sql';
        PKG_GENERATOR.createScriptFile(
                                inDirectory     => 'DIR_PKGEN',
                                inFilename      => vFilename,
                                inScripts       => vScripts
                              );
        
    END LOOP;
    
END;

