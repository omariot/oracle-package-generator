CREATE OR REPLACE PACKAGE PKG_GENERATOR IS   
	/*
        Autor:  OMAR ARIEL MARIOT POLONIA.
        El propietario intelectual de este código le otorga el derecho de utiliza el mismo solo con fines comerciales.
        El autor no se hace responsable de la utilización del mismo.  
    */   
   
   -- Cursor de las tablas de un esquema
   CURSOR c_tables(pOwner IN VARCHAR2) IS
   SELECT t.owner, t.table_name
     FROM ALL_TABLES t
    WHERE t.owner = UPPER(pOwner)
    ORDER BY table_name;

   TYPE tTables IS TABLE OF c_tables%ROWTYPE;
   vTableList   tTables := tTables();   
   nIndexParam  PLS_INTEGER := 0;
   
   TYPE tList IS TABLE OF VARCHAR2(60);  
   
   TYPE tColumns IS RECORD (
        column_name      ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
        data_type        ALL_TAB_COLUMNS.data_type%TYPE,
        data_length      ALL_TAB_COLUMNS.data_length%TYPE,
        data_precision   ALL_TAB_COLUMNS.data_precision%TYPE,
        data_scale       ALL_TAB_COLUMNS.data_scale%TYPE,      
        nullable         ALL_TAB_COLUMNS.nullable%TYPE,
        column_id        ALL_TAB_COLUMNS.column_id%TYPE,
        primary_key      VARCHAR2(1),
        foreign_key      VARCHAR2(1)
   );
   
   TYPE tColumnsList IS TABLE OF tColumns;  
   
    FUNCTION getTableList(inSchema      IN VARCHAR2)
     RETURN PKG_GENERATOR.tTables;     
   
   PROCEDURE addTableList(inSchema      IN VARCHAR2,
                          inTablename   IN VARCHAR2,
                          inAlias       IN VARCHAR2 DEFAULT NULL);
                          
   PROCEDURE delTableList;
   
   FUNCTION compactMethodName(inOwner       IN VARCHAR2,
                              inTablename   IN VARCHAR2,
                              inMethod      IN VARCHAR2)
     RETURN VARCHAR2;
   
   FUNCTION compactName(inName      IN VARCHAR2)
     RETURN VARCHAR2;
     
   PROCEDURE addScripts(pCurrentScripts   IN OUT TSCRIPTS,
                        pNewScript        IN TSCRIPT);  
     
   FUNCTION getParamList(pColumnsList      IN tColumnsList, 
                         pTypeFormat       IN VARCHAR2)
     RETURN TSCRIPTS;  
   
   -- Generar script IA.a type
    FUNCTION generateTypeScript(inOwner     IN VARCHAR2,
                               inTableName  IN VARCHAR2,
                               inTypeName   IN VARCHAR2,
                               inTypeList   IN VARCHAR2)
      RETURN TSCRIPTS;
   
   -- Generar script IA.a IA.kage spec o body
   FUNCTION generatePackageScript(inOwner        IN VARCHAR2,
                                  inTableName    IN VARCHAR2,
                                  inPackageName  IN VARCHAR2,
                                  inTypeName     IN VARCHAR2,
                                  inTypeList     IN VARCHAR2)
      RETURN TSCRIPTS;
   
   FUNCTION getTables(inOwner IN VARCHAR2)
      RETURN PKG_GENERATOR.tTables;
            
   -- Listado de columnas de una tabla
   FUNCTION getColumnas(inOwner IN VARCHAR2, inTableName IN VARCHAR2)
      RETURN PKG_GENERATOR.tColumnsList;
      
   FUNCTION getColumnsPrimary(inColumns     IN tColumnsList,
                              inPrimary     IN VARCHAR2)
      RETURN PKG_GENERATOR.tColumnsList; 
   
    FUNCTION getColumnsNotNull(inColumns     IN tColumnsList, 
                               inNull    IN VARCHAR2)
      RETURN PKG_GENERATOR.tColumnsList; 

    FUNCTION getScriptValidaFK(inOwner       IN VARCHAR2,
                              inTableName   IN VARCHAR2,
                              inColumnName  IN VARCHAR2)
      RETURN tScripts;

END PKG_GENERATOR;
/