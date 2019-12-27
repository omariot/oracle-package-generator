-- NOTE:  Las tablas deben contener Primary Key para poder generar correctamente el código
-- NOTE:  Debe activar la salida por Output del editor PLSQL
set serveroutput on
CREATE TABLE MYTABLE2
(
    Codigo          VARCHAR2(30) NOT NULL,
    Fecha           DATE,
    Valor           NUMBER(12,2) NOT NULL,
    CodRefMyTable1  VARCHAR2(30) NOT NULL
);
-- Primary Key
ALTER TABLE MYTABLE2 
ADD CONSTRAINT PK_MYTABLE2 PRIMARY KEY (Codigo);

-- Foreign Key
ALTER TABLE MYTABLE2 
ADD CONSTRAINT FK_MYTABLE2 FOREIGN KEY (CodRefMyTable1) REFERENCES MYTABLE1(Codigo);

DECLARE
    vScripts        TSCRIPTS := TSCRIPTS();
    vSchema         VARCHAR2(30) := USER;
    vTableName      VARCHAR2(30) := NULL;
    vTypeName       VARCHAR2(30) := NULL;
    vTypeList       VARCHAR2(30) := NULL;
    vPackageName    VARCHAR2(30) := NULL;
    
    vTableList      PKG_GENERATOR.tTables := PKG_GENERATOR.tTables();
    
BEGIN
    vTableList.DELETE;
    vTableList := PKG_GENERATOR.getTableList(vSchema);
    
    FOR i IN 1 .. vTableList.COUNT LOOP
        
        vTableName := vTableList(i).table_name;
        vTypeName := PKG_GENERATOR.COMPACTNAME(vTableName||'_OBJ');
        vTypeList := PKG_GENERATOR.COMPACTNAME(vTableName||'_LIST');
        vPackageName := PKG_GENERATOR.COMPACTNAME('PKG_'||vTableName);
        
        --  Generando Scripts del Type Object
        vScripts.DELETE;
        vScripts := PKG_GENERATOR.generateTypeScript(inOwner     => vSchema,
                                                        inTableName => vTableName,
                                                        inTypeName  => vTypeName,
                                                        inTypeList  => vTypeList);
                                                        
        FOR i IN 1..vScripts.COUNT LOOP
           DBMS_OUTPUT.PUT_LINE(vScripts(i).linea);
        END LOOP;
        
        -- Generando Script del Package Utilizando el Type Object
        vScripts.DELETE;
        vScripts := PKG_GENERATOR.generatePackageScript( inOwner         => vSchema,
                                                            inTableName     => vTableName,
                                                            inPackageName   => vPackageName,
                                                            inTypeName      => vTypeName,
                                                            inTypeList      => vTypeList);        
                                                        
        FOR i IN 1..vScripts.COUNT LOOP
           DBMS_OUTPUT.PUT_LINE(vScripts(i).linea);
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(' '||CHR(13));
        
    END LOOP;
    
END;

