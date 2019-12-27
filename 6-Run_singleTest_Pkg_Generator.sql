-- NOTE:  Las tablas deben contener Primary Key para poder generar correctamente el código
-- NOTE:  Debe activar la salida por Output del editor PLSQL
set serveroutput on
CREATE TABLE MYTABLE1
(
    Codigo      VARCHAR2(30) NOT NULL,
    Descripcion VARCHAR2(60) NOT NULL,
    Fecha       DATE,
    Valor       NUMBER(12,2) NOT NULL
);

-- Primary Key
ALTER TABLE MYTABLE1 ADD CONSTRAINT PK_MYTABLE1 PRIMARY KEY (Codigo);

DECLARE
    vScripts        TSCRIPTS := TSCRIPTS();
    vSchema         VARCHAR2(30) := USER;
    vTableName      VARCHAR2(30) := 'MYTABLE1';
    vTypeName       VARCHAR2(30) := 'MYTABLE1_OBJ';
    vTypeList       VARCHAR2(30) := 'MYTABLE1_LIST';
    vPackageName    VARCHAR2(30) := 'PKG_MYTABLE1';
BEGIN
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
    
END;

