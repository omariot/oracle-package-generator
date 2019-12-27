CREATE OR REPLACE PACKAGE BODY PKG_GENERATOR AS

   FUNCTION getTableList(inSchema      IN VARCHAR2)
     RETURN PKG_GENERATOR.tTables IS    
     vTables        tTables := tTables(); 
   BEGIN
      vTables.DELETE;      
      OPEN c_tables(inSchema);
      LOOP
        FETCH c_tables BULK COLLECT INTO vTableList LIMIT 500;
        FOR i IN 1 .. vTables.COUNT LOOP
            vTableList.EXTEND;
            nIndexParam := nIndexParam + 1;
            vTableList(nIndexParam) := vTables(i);
        END LOOP;        
        EXIT WHEN c_tables%NOTFOUND;
      END LOOP;
      CLOSE c_tables;
      RETURN vTableList;  
   END; 

   PROCEDURE addTableList(inSchema      IN VARCHAR2,
                          inTablename   IN VARCHAR2,
                          inAlias       IN VARCHAR2 DEFAULT NULL) IS
   BEGIN
        nIndexParam := nIndexParam + 1; 
        vTableList.EXTEND;         
        vTableList(nIndexParam).owner := inSchema;  
        vTableList(nIndexParam).table_name := inTablename;
   END addTableList; 

   PROCEDURE delTableList IS
   BEGIN
        IF vTableList IS NOT NULL THEN
            IF vTableList.COUNT > 0 THEN 
                vTableList.DELETE;
            END IF;
        END IF;
   END delTableList; 
   
   FUNCTION getParamList(pColumnsList      IN tColumnsList, 
                         pTypeFormat       IN VARCHAR2)
     RETURN TSCRIPTS IS
     vParamList     TSCRIPTS := TSCRIPTS();
     vScript        TSCRIPT  := TSCRIPT();    
     vComma         VARCHAR2(1) := ',';
   BEGIN
        vParamList.DELETE;
        --  Build IA.am List by Table and Columns
        FOR i IN 1 .. pColumnsList.COUNT LOOP             
            --  Parametro
            IF pTypeFormat = 'P' THEN                                                   
                
                vScript.linea := '    '||compactName('p'||InitCap(pColumnsList(i).column_name))||'  IN '||pColumnsList(i).data_type||' '||vComma;                     
            -- Asignacion de Parametro                                
            ELSIF pTypeFormat = 'A' THEN
                           
                vScript.linea := '    '||compactName('p'||InitCap(pColumnsList(i).column_name))||'    => '||compactName('p'||InitCap(pColumnsList(i).column_name))||' '||vComma;
                
            --  Columna    
            ELSIF pTypeFormat = 'C' THEN
                IF pColumnsList(i).data_type IN ('VARCHAR2', 'VARCHAR', 'CHAR') THEN
                    vScript.linea := pColumnsList(i).column_name||'   '||pColumnsList(i).data_type||'('||pColumnsList(i).data_length||')'||vComma;
                ELSIF pColumnsList(i).data_type = 'NUMBER' THEN
                    IF pColumnsList(i).data_scale IS NULL THEN
                        IF pColumnsList(i).data_precision IS NULL THEN 
                            vScript.linea := pColumnsList(i).column_name||'   '||pColumnsList(i).data_type||vComma;
                        ELSE
                            vScript.linea := pColumnsList(i).column_name||'   '||pColumnsList(i).data_type||'('||pColumnsList(i).data_precision||')'||vComma;
                        END IF;
                    ELSE
                        vScript.linea := pColumnsList(i).column_name||'   '||pColumnsList(i).data_type||'('||pColumnsList(i).data_precision||','||pColumnsList(i).data_scale||')'||vComma;
                    END IF;
                ELSE
                    vScript.linea := pColumnsList(i).column_name||'   '||pColumnsList(i).data_type||vComma;
                END IF;  
            END IF;
            vParamList.EXTEND;
            vParamList(i) := vScript;
            
        END LOOP;
        
        RETURN vParamList;
        
   END getParamList;
   
   FUNCTION compactMethodName(inOwner       IN VARCHAR2,
                              inTablename   IN VARCHAR2,
                              inMethod      IN VARCHAR2)
     RETURN VARCHAR2 IS
     
     vIdentifierName        VARCHAR2(150);
   BEGIN
        --  Concatenar Method
        IF inMethod IS NOT NULL THEN
            vIdentifierName := inTablename||'_'||inMethod;
        END IF;
   
        --  Concatenar el Schema Owner
        IF  vIdentifierName like inOwner||'%' THEN
            vIdentifierName     := InitCap(vIdentifierName);
        ELSE
            vIdentifierName     := InitCap(inOwner)||'_'||InitCap(vIdentifierName);
        END IF;           
        
        -- Remueve Subguion _
        IF LENGTH(vIdentifierName) > 30 THEN
            vIdentifierName := REPLACE(vIdentifierName, '_', '');            
        END IF;
        
        -- Remueve Owner
        IF LENGTH(vIdentifierName) > 30 THEN
          vIdentifierName := REPLACE(vIdentifierName, inOwner, '');    
        END IF;
        
        RETURN vIdentifierName;
   END compactMethodName;
   
   FUNCTION compactName(inName      IN VARCHAR2)
     RETURN VARCHAR2 IS
     vIdentifierName        VARCHAR2(150);
   BEGIN
      vIdentifierName := inName;  
      -- Remueve Subguion _
      IF LENGTH(vIdentifierName) > 30 THEN
         vIdentifierName := REPLACE(vIdentifierName, '_', '');            
      END IF;
      
      RETURN vIdentifierName;
   END;
   
   PROCEDURE addScripts(pCurrentScripts   IN OUT TSCRIPTS,
                        pNewScript        IN TSCRIPT) IS                               
   BEGIN
        pCurrentScripts.EXTEND;    pCurrentScripts(pCurrentScripts.COUNT) := pNewScript;
   END;
   
   -- Generar script IA.a IA.kage spec o body
   FUNCTION generateTypeScript(inOwner     IN VARCHAR2,
                               inTableName IN VARCHAR2,
                               inTypeName  IN VARCHAR2,
                               inTypeList  IN VARCHAR2)
      RETURN TSCRIPTS IS
      vScripts              TSCRIPTS    := TSCRIPTS();  
      vScript               TSCRIPT     := TSCRIPT();
      --vScripts.K             TSCRIPTS     := TSCRIPTS();
      vColumnsList          PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList(); 
      vColumnsPrimary       PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();
      vColumnsNotNull       PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();
      vParamList            TSCRIPTS := TSCRIPTS();
      vComma                VARCHAR2(1) := ',';
      vAnd                  VARCHAR2(10) := ' AND ';
      vTotalColumns         NUMBER := 0;      
      nIndex                NUMBER := 0;
   BEGIN
      vAnd := 'AND';
      vComma := ',';
      vScripts.DELETE; 
      vScript.linea := '-- TYPE '||inOwner||'.'||inTypeName; addScripts(vScripts, vScript);   
      vScript.linea := 'CREATE OR REPLACE TYPE '||inOwner||'.'||inTypeName||' AS OBJECT ('; addScripts(vScripts, vScript);
      
      --  Get column list of the tablename
      vColumnsList.DELETE;
      vColumnsList  := PKG_GENERATOR.getColumnas(inOwner => inOwner, inTableName => inTableName);
      vTotalColumns := vColumnsList.COUNT; 
      vParamList.DELETE;
      vParamList := getParamList(pColumnsList      => vColumnsList, 
                                 pTypeFormat       => 'C');
      vColumnsPrimary.DELETE;
      vColumnsPrimary := PKG_GENERATOR.getColumnsPrimary(inColumns => vColumnsList, inPrimary => 'S');
      
      vColumnsNotNull.DELETE;
      vColumnsNotNull := PKG_GENERATOR.getColumnsNotNull(inColumns => vColumnsList, inNull => 'N');
                                   
      FOR i IN 1.. vParamList.COUNT LOOP
          vScript.linea := vParamList(i).linea; addScripts(vScripts, vScript);    
      END LOOP;
      vScript.linea := '                CONSTRUCTOR FUNCTION '||inTypeName||' RETURN SELF AS RESULT,';  addScripts(vScripts, vScript);
      vScript.linea := '                MEMBER PROCEDURE Generar (SELF IN OUT NOCOPY '||inTypeName||'),'; addScripts(vScripts, vScript);
      vScript.linea := '                MEMBER PROCEDURE Crear (SELF IN OUT NOCOPY '||inTypeName||'),'; addScripts(vScripts, vScript);
      vScript.linea := '                MEMBER PROCEDURE Actualizar (SELF IN OUT NOCOPY '||inTypeName||'),'; addScripts(vScripts, vScript);
      vScript.linea := '                MEMBER PROCEDURE Borrar (SELF IN OUT NOCOPY '||inTypeName||'),'; addScripts(vScripts, vScript);
      vScript.linea := '                MEMBER FUNCTION  Existe (SELF IN OUT NOCOPY '||inTypeName||') RETURN BOOLEAN,'; addScripts(vScripts, vScript);
      vScript.linea := '                MEMBER FUNCTION  Compare(SELF IN OUT NOCOPY  '||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                                         ORIG IN OUT NOCOPY  '||inTypeName||')'; addScripts(vScripts, vScript);
      vScript.linea := '                   RETURN BOOLEAN,'; addScripts(vScripts, vScript); 
      vScript.linea := '                MEMBER FUNCTION  Validar (SELF          IN OUT NOCOPY '||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                                          p_Operacion   IN            VARCHAR2,'; addScripts(vScripts, vScript);
      vScript.linea := '                                          p_Error       IN OUT        VARCHAR2)'; addScripts(vScripts, vScript);
      vScript.linea := '                   RETURN BOOLEAN'; addScripts(vScripts, vScript);      
      vScript.linea := '                ) NOT FINAL;'; addScripts(vScripts, vScript);
      vScript.linea := '                /'; addScripts(vScripts, vScript);     
      vScript.linea := 'CREATE OR REPLACE TYPE BODY '||inOwner||'.'||inTypeName||' AS'; addScripts(vScripts, vScript);
      vScript.linea := '  CONSTRUCTOR FUNCTION '||inTypeName||' RETURN SELF AS RESULT AS'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '    RETURN;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER PROCEDURE Generar (SELF IN OUT NOCOPY '||inTypeName||') IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vExiste    BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar   BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vError     VARCHAR2(4000);'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar := SELF.Validar (p_Operacion => ''G'', p_Error => vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      IF vValidar THEN'; addScripts(vScripts, vScript);
      vScript.linea := '          vExiste := SELF.Existe ();'; addScripts(vScripts, vScript);
      vScript.linea := '          IF vExiste = FALSE THEN'; addScripts(vScripts, vScript);
      vScript.linea := '              SELF.Crear ();'; addScripts(vScripts, vScript);
      vScript.linea := '          ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '              SELF.Actualizar ();'; addScripts(vScripts, vScript);
      vScript.linea := '          END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '          RAISE_APPLICATION_ERROR ( -20102, ''Error - Los parámetros para Generar de '||inTableName||' no son validos.  ''||vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER PROCEDURE Crear (SELF IN OUT NOCOPY '||inTypeName||') IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar   BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vError     VARCHAR2(4000);'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar := SELF.Validar (p_Operacion => ''C'', p_Error => vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      IF vValidar THEN'; addScripts(vScripts, vScript);
      vScript.linea := '          BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '              INSERT INTO '||inOwner||'.'||inTableName; addScripts(vScripts, vScript);
      vScript.linea := '              VALUES ('; addScripts(vScripts, vScript);
      FOR i IN 1.. vColumnsList.COUNT LOOP
          IF i = vTotalColumns THEN
              vComma := NULL;
          END IF;  
          vScript.linea := '                  SELF.'||vColumnsList(i).column_name||vComma; addScripts(vScripts, vScript); 
      END LOOP;                                          
      vScript.linea := '              );'; addScripts(vScripts, vScript);
      vScript.linea := '          EXCEPTION'; addScripts(vScripts, vScript);
      vScript.linea := '              WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '                  RAISE_APPLICATION_ERROR (-20102, ''Error - Insertando '' || SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '          END;'; addScripts(vScripts, vScript);
      vScript.linea := '      ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '          RAISE_APPLICATION_ERROR ( -20102, ''Error - Los parámetros para inserción de '||inTableName||' no son validos. ''||vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER PROCEDURE Actualizar ( SELF   IN OUT NOCOPY '||inTypeName||') IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar   BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vError     VARCHAR2(4000);'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar := SELF.Validar (p_Operacion => ''U'', p_Error => vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      IF vValidar THEN'; addScripts(vScripts, vScript);
      vScript.linea := '          BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '              UPDATE '||inOwner||'.'||inTableName; addScripts(vScripts, vScript);
      vScript.linea := '                 SET '; addScripts(vScripts, vScript);
      vComma := ','; 
      FOR i IN 1.. vColumnsList.COUNT LOOP
          IF i = vTotalColumns THEN
              vComma := NULL;
          END IF;
          vScript.linea := '                      '||vColumnsList(i).column_name||' = SELF.'||vColumnsList(i).column_name||vComma; addScripts(vScripts, vScript); 
      END LOOP;     
      vScript.linea := '              WHERE '; addScripts(vScripts, vScript);
      vTotalColumns := vColumnsPrimary.COUNT;
      FOR i IN 1.. vColumnsPrimary.COUNT LOOP
         IF i = vTotalColumns OR vTotalColumns = 1 THEN
              vAnd := NULL;
         ELSE
            vAnd := ' AND ';
         END IF;
         vScript.linea := '                      '||vColumnsPrimary(i).column_name||' = SELF.'||vColumnsPrimary(i).column_name||' '||vAnd; addScripts(vScripts, vScript);         
      END LOOP;
      vScript.linea := '                      ;'; addScripts(vScripts, vScript);
      vScript.linea := '          EXCEPTION'; addScripts(vScripts, vScript);
      vScript.linea := '              WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '                  RAISE_APPLICATION_ERROR (-20102, ''Error - Actualizando '' || SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '          END;'; addScripts(vScripts, vScript);
      vScript.linea := '      ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '          RAISE_APPLICATION_ERROR ( -20102, ''Error - Los parámetros para actualización de '||inTableName||' no son validos. ''||vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER PROCEDURE Borrar (SELF IN OUT NOCOPY '||inTypeName||') IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar   BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vExiste    BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vError     VARCHAR2(4000);'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar := SELF.Validar (p_Operacion => ''D'', p_Error => vError);'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      IF vValidar THEN'; addScripts(vScripts, vScript);
      vScript.linea := '          vExiste := SELF.Existe ();'; addScripts(vScripts, vScript);
      vScript.linea := '          IF vExiste THEN'; addScripts(vScripts, vScript);
      vScript.linea := '              BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '                  DELETE '||inOwner||'.'||inTableName; addScripts(vScripts, vScript);
      vScript.linea := '                  WHERE '; addScripts(vScripts, vScript);
      vTotalColumns := vColumnsPrimary.COUNT;
      FOR i IN 1.. vColumnsPrimary.COUNT LOOP
         IF i = vTotalColumns OR vTotalColumns = 1 THEN
            vAnd := NULL;
         ELSE
            vAnd := ' AND ';
         END IF;
         vScript.linea := '                      '||vColumnsPrimary(i).column_name||' = SELF.'||vColumnsPrimary(i).column_name||' '||vAnd; addScripts(vScripts, vScript);         
      END LOOP;
      vAnd := ' AND '; 
      vScript.linea := '                      ;'; addScripts(vScripts, vScript);
      vScript.linea := '              EXCEPTION'; addScripts(vScripts, vScript);
      vScript.linea := '                  WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '                      RAISE_APPLICATION_ERROR (-20102, ''Error - Borrando '' || SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '              END;'; addScripts(vScripts, vScript);
      vScript.linea := '          ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '              RAISE_APPLICATION_ERROR ( -20102, ''Error - No existe esta información.'');'; addScripts(vScripts, vScript);
      vScript.linea := '          END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '          RAISE_APPLICATION_ERROR ( -20102, ''Error - Los parámetros para borrar de '||inTableName||' no son validos. ''||vError);'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER FUNCTION Existe (SELF IN OUT NOCOPY '||inTypeName||')'; addScripts(vScripts, vScript);
      vScript.linea := '  RETURN BOOLEAN IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vExiste   NUMBER := 0;'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      SELECT COUNT (1)'; addScripts(vScripts, vScript);
      vScript.linea := '        INTO vExiste'; addScripts(vScripts, vScript);
      vScript.linea := '        FROM '||inOwner||'.'||inTableName; addScripts(vScripts, vScript);
      vScript.linea := '       WHERE '; addScripts(vScripts, vScript);
      vTotalColumns := vColumnsPrimary.COUNT;
      FOR i IN 1.. vColumnsPrimary.COUNT LOOP
         IF i = vTotalColumns OR vTotalColumns = 1 THEN
              vAnd := NULL;
         ELSE
            vAnd := ' AND ';
         END IF;
         vScript.linea := '                      '||vColumnsPrimary(i).column_name||' = SELF.'||vColumnsPrimary(i).column_name||' '||vAnd; addScripts(vScripts, vScript);
      END LOOP;
      vAnd := ' AND ';
      vScript.linea := '  ;'; addScripts(vScripts, vScript);
      vScript.linea := ''||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      RETURN (vExiste > 0);'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER FUNCTION  Compare(SELF IN OUT NOCOPY  '||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                           ORIG IN OUT NOCOPY  '||inTypeName||')'; addScripts(vScripts, vScript);
      vScript.linea := '  RETURN BOOLEAN IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vIgual  BOOLEAN := TRUE;'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      FOR i IN 1.. vColumnsList.COUNT LOOP
         vScript.linea := '       IF SELF.'||vColumnsList(i).column_name||' <> ORIG.'||vColumnsList(i).column_name||' THEN'; addScripts(vScripts, vScript);
         vScript.linea := '          vIgual := FALSE;'; addScripts(vScripts, vScript);
         vScript.linea := '          RETURN vIgual;'; addScripts(vScripts, vScript);
         vScript.linea := '       END IF;'; addScripts(vScripts, vScript);
      END LOOP;
      vScript.linea := '       RETURN vIgual;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;';addScripts(vScripts, vScript);
      vScript.linea := '  MEMBER FUNCTION Validar (SELF          IN OUT NOCOPY '||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                           p_Operacion                 VARCHAR2,'; addScripts(vScripts, vScript);
      vScript.linea := '                           p_Error       IN OUT        VARCHAR2)'; addScripts(vScripts, vScript);
      vScript.linea := '  RETURN BOOLEAN IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar   BOOLEAN := TRUE;'; addScripts(vScripts, vScript);
      vScript.linea := '  BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      vValidar := TRUE;'; addScripts(vScripts, vScript);
      vScript.linea := '      -- Validar Campos Nulos'; addScripts(vScripts, vScript);
      vScript.linea := '      IF p_Operacion IN (''C'', ''G'') THEN';  addScripts(vScripts, vScript);     
      FOR i IN 1.. vColumnsNotNull.COUNT LOOP
        vScript.linea := '          IF SELF.'||vColumnsNotNull(i).column_name||' IS NULL THEN'; addScripts(vScripts, vScript);
        vScript.linea := '              vValidar := FALSE;'; addScripts(vScripts, vScript);
        vScript.linea := '              p_Error := ''El campo '||vColumnsNotNull(i).column_name||' no puede estar en blanco para Insertar.'';'; addScripts(vScripts, vScript);
        vScript.linea := '              RETURN vValidar;';   addScripts(vScripts, vScript);           
        vScript.linea := '          END IF;'; addScripts(vScripts, vScript);          
      END LOOP;
      vScript.linea := '          -- //TODO: Poner validaciones/controles adicionales aqui';addScripts(vScripts, vScript);
      vScript.linea := '      ELSIF p_Operacion IN (''U'',''G'') THEN'; addScripts(vScripts, vScript);
      FOR i IN 1.. vColumnsPrimary.COUNT LOOP
        vScript.linea := '          IF SELF.'||vColumnsPrimary(i).column_name||' IS NULL THEN';   addScripts(vScripts, vScript);  
        vScript.linea := '              vValidar := FALSE;'; addScripts(vScripts, vScript);
        vScript.linea := '              p_Error := ''El campo '||vColumnsNotNull(i).column_name||' no puede estar en blanco para Actualizar.'';'; addScripts(vScripts, vScript);
        vScript.linea := '              RETURN vValidar;'; addScripts(vScripts, vScript);        
        vScript.linea := '          END IF;'; addScripts(vScripts, vScript);
      END LOOP;            
      vScript.linea := '          -- //TODO: Poner validaciones/controles adicionales aqui';addScripts(vScripts, vScript);
      vScript.linea := '      ELSIF p_Operacion = ''D'' THEN'; addScripts(vScripts, vScript);
      FOR i IN 1.. vColumnsPrimary.COUNT LOOP
        vScript.linea := '          IF SELF.'||vColumnsPrimary(i).column_name||' IS NULL THEN'; addScripts(vScripts, vScript);    
        vScript.linea := '              vValidar := FALSE;'; addScripts(vScripts, vScript);
        vScript.linea := '              p_Error := ''El campo '||vColumnsNotNull(i).column_name||' no puede estar en blanco para Borrar.'';'; addScripts(vScripts, vScript);
        vScript.linea := '              RETURN vValidar;'; addScripts(vScripts, vScript);        
        vScript.linea := '          END IF;'; addScripts(vScripts, vScript);
      END LOOP;
      vScript.linea := '          -- //TODO: Poner validaciones/controles adicionales aqui';addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      RETURN vValidar;'; addScripts(vScripts, vScript);
      vScript.linea := '  END;'; addScripts(vScripts, vScript);
      vScript.linea := 'END;'; addScripts(vScripts, vScript);
      vScript.linea := '/'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13);      addScripts(vScripts, vScript);
      vScript.linea := 'CREATE OR REPLACE TYPE '||inOwner||'.'||inTypeList||' AS TABLE OF '||inOwner||'.'||inTypeName||';'; addScripts(vScripts, vScript);
      vScript.linea := '/'; addScripts(vScripts, vScript);
      vAnd := 'AND';
      vComma := ',';
      RETURN vScripts;
         
   END generateTypeScript; 

   -- Generar script IA.a IA.kage spec o body
   FUNCTION generatePackageScript(inOwner        IN VARCHAR2,
                                  inTableName    IN VARCHAR2,
                                  inPackageName  IN VARCHAR2,
                                  inTypeName     IN VARCHAR2,
                                  inTypeList     IN VARCHAR2)
      RETURN TSCRIPTS IS
      
      vColumnsList          PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList(); 
      vColumnsPrimary       PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();
      vColumnsNotNull       PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();
      vScripts              TSCRIPTS := TSCRIPTS();
      vScript               TSCRIPT  := TSCRIPT();      
      vParamList            TSCRIPTS := TSCRIPTS();
      nIndex                PLS_INTEGER := 0;
            
      vComma                VARCHAR2(1) := ',';
      vAnd                  VARCHAR2(3) := 'AND';
      vTotalColumns         NUMBER := 0;
      
      vTypeNameList         VARCHAR2(150) := NULL;
      vCursor               VARCHAR2(150) := NULL;
      vCursorVariable       VARCHAR2(150) := NULL; 
      vTables               tTables := PKG_GENERATOR.tTables();
      vMethod               VARCHAR2(128);
      
   BEGIN
      vAnd := 'AND';
      vComma := ',';    
      vScripts.DELETE;   
      vScript.linea := ' '||CHR(13);
      vScript.linea := '   /******************************************************************************'; addScripts(vScripts, vScript);
      vScript.linea := '    NAME:    '||inPackagename; addScripts(vScripts, vScript);
      vScript.linea := '    PURPOSE: PACKAGE DE INTERFACE CRUD.'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '    REVISIONS:'; addScripts(vScripts, vScript);
      vScript.linea := '    Ver        Date        Author           Description'; addScripts(vScripts, vScript);
      vScript.linea := '    ---------  ----------  ---------------  ------------------------------------'; addScripts(vScripts, vScript);
      vScript.linea := '    1.0        '||TO_CHAR(SYSDATE, 'dd/mm/yyyy')||'    '|| USER ||'  '; addScripts(vScripts, vScript);
      vScript.linea := '   ******************************************************************************/'; addScripts(vScripts, vScript);  
      --  For Package Spec                                                                                             
      vScript.linea := '-- PACKAGE: '|| inPackageName; addScripts(vScripts, vScript);
      vScript.linea := '   CREATE OR REPLACE PACKAGE '||inOwner||'.'||inPackageName||' IS'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '       TYPE resultado IS RECORD'; addScripts(vScripts, vScript);
      vScript.linea := '       ('; addScripts(vScripts, vScript);
      vScript.linea := '           codigo        VARCHAR2(30),'; addScripts(vScripts, vScript);
      vScript.linea := '           descripcion   VARCHAR2(4000)'; addScripts(vScripts, vScript);
      vScript.linea := '       );'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '   PROCEDURE Generar ('; addScripts(vScripts, vScript); 
      --  Get column list of the tablename
      vColumnsList.DELETE;
      vColumnsList   := getColumnas(inOwner     => inOwner,  inTableName => inTableName); 
      vTotalColumns  := vColumnsList.COUNT;
      vParamList.DELETE;
      vParamList := getParamList(pColumnsList      => vColumnsList, 
                                 pTypeFormat       => 'P');
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado);'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '    PROCEDURE Crear   ('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado);'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '    PROCEDURE Actualizar ('; addScripts(vScripts, vScript);    
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado);'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '    PROCEDURE Borrar ('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado);'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);  
      vScript.linea := '    FUNCTION Consultar('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        nIndex  := nIndex + 1;vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;   
      vScript.linea := '                     pResultado   IN OUT resultado)'; addScripts(vScripts, vScript);
      vScript.linea := '      RETURN '||InOwner||'.'||inTypeList||';'; addScripts(vScripts, vScript);
      vScript.linea := '    FUNCTION Comparar ( pData1  IN '||InOwner||'.'||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                        pData2  IN '||InOwner||'.'||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                        pModo   IN VARCHAR2)    -- O = (Compare between Objects pData1 and pData2),  T = (Compare pData1 and Table data)'; addScripts(vScripts, vScript);
      vScript.linea := '      RETURN BOOLEAN;';addScripts(vScripts, vScript);
      vScript.linea := '    FUNCTION Existe ('; addScripts(vScripts, vScript);
      vColumnsPrimary.DELETE;
      vColumnsPrimary := PKG_GENERATOR.getColumnsPrimary(inColumns => vColumnsList, inPrimary => 'S');
      vParamList := getParamList(pColumnsList      => vColumnsPrimary, 
                                 pTypeFormat       => 'P');
      FOR i IN 1.. vParamList.COUNT LOOP
         vScript.linea := '                      '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                 
      vScript.linea := '                     pResultado   IN OUT resultado)'; addScripts(vScripts, vScript);
      vScript.linea := '            RETURN BOOLEAN;'; addScripts(vScripts, vScript);
      vScript.linea := '    FUNCTION Validar('; addScripts(vScripts, vScript);
      vParamList.DELETE;
      vParamList := getParamList(pColumnsList      => vColumnsList, 
                                 pTypeFormat       => 'P');
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;       
      vScript.linea := '                     pOperacion   IN      VARCHAR2,         -- G=Generar, C=Crear, U=Actualizar, D=Borrar'; addScripts(vScripts, vScript);
      vScript.linea := '                     pError       IN OUT  VARCHAR2) RETURN BOOLEAN;'; addScripts(vScripts, vScript);
      vScript.linea := '    END '||inPackageName||';'; addScripts(vScripts, vScript);
      vScript.linea := ' /'; addScripts(vScripts, vScript);
      
      --  For Package Body                                                                                             
      vScript.linea := '  -- PACKAGE BODY: '|| inPackageName; addScripts(vScripts, vScript);
      vScript.linea := '   CREATE OR REPLACE PACKAGE BODY '||inOwner||'.'||inPackageName||' IS'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '   PROCEDURE Generar ('; addScripts(vScripts, vScript);
      --  Get column list of the tablename
      vColumnsList.DELETE;
      vColumnsList   := getColumnas(inOwner     => inOwner,  inTableName => inTableName); 
      vParamList.DELETE;
      vParamList := getParamList(pColumnsList      => vColumnsList, 
                                 pTypeFormat       => 'P');
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado) IS'; addScripts(vScripts, vScript);
      vScript.linea := '      pData '||inOwner||'.'||inTypeName||';'; addScripts(vScripts, vScript);
      vScript.linea := '   BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        vScript.linea := '      pData.'||vColumnsList(i).column_name||' :=  '||compactName('p'||InitCap(vColumnsList(i).column_name))||';'; addScripts(vScripts, vScript);
      END LOOP;   
      vScript.linea := '      IF pData.Validar(''G'', pResultado.descripcion) then'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '         -- Existe'; addScripts(vScripts, vScript);
      vScript.linea := '         IF pData.Existe() = FALSE THEN'; addScripts(vScripts, vScript);
      vScript.linea := '            -- Insertar'; addScripts(vScripts, vScript);
      vScript.linea := '            pData.crear();'; addScripts(vScripts, vScript);
      vScript.linea := '         ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '            -- Modificar'; addScripts(vScripts, vScript);
      vScript.linea := '            pData.Actualizar ();'; addScripts(vScripts, vScript);
      vScript.linea := '         END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      EXCEPTION WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.codigo := SQLCODE;'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.descripcion := SQLERRM;'; addScripts(vScripts, vScript);
      vScript.linea := '           RAISE_APPLICATION_ERROR(-20100, ''Error ''||SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '      END Generar;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '    PROCEDURE Crear   ('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado) IS'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      pData '||inOwner||'.'||inTypeName||';'; addScripts(vScripts, vScript);                      
      vScript.linea := '   BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        vScript.linea := '      pData.'||vColumnsList(i).column_name||' :=  '||compactName('p'||InitCap(vColumnsList(i).column_name))||';'; addScripts(vScripts, vScript);
      END LOOP;   
      vScript.linea := '      IF pData.Validar(''C'', pResultado.descripcion) then'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '         -- Existe'; addScripts(vScripts, vScript);
      vScript.linea := '         IF pData.Existe() = FALSE THEN'; addScripts(vScripts, vScript);
      vScript.linea := '            pData.Crear ();'; addScripts(vScripts, vScript);
      vScript.linea := '         END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      EXCEPTION WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.codigo := SQLCODE;'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.descripcion := SQLERRM;'; addScripts(vScripts, vScript);
      vScript.linea := '           RAISE_APPLICATION_ERROR(-20100, ''Error ''||SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '    END Crear;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '    PROCEDURE Actualizar ('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado) IS'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      pData '||inOwner||'.'||inTypeName||';'; addScripts(vScripts, vScript);                      
      vScript.linea := '   BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        vScript.linea := '      pData.'||vColumnsList(i).column_name||' :=  '||compactName('p'||InitCap(vColumnsList(i).column_name))||';'; addScripts(vScripts, vScript);
      END LOOP;   
      vScript.linea := '      IF pData.Validar(''U'', pResultado.descripcion) then'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '         -- Existe'; addScripts(vScripts, vScript);
      vScript.linea := '         IF pData.Existe() = TRUE THEN'; addScripts(vScripts, vScript);
      vScript.linea := '            pData.Actualizar ();'; addScripts(vScripts, vScript);
      vScript.linea := '         END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      EXCEPTION WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.codigo := SQLCODE;'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.descripcion := SQLERRM;'; addScripts(vScripts, vScript);
      vScript.linea := '           RAISE_APPLICATION_ERROR(-20100, ''Error ''||SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '    END Actualizar;'; addScripts(vScripts, vScript);
      vScript.linea := '    PROCEDURE Borrar ('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;                                   
      vScript.linea := '                     pResultado   IN OUT resultado) IS'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      pData '||inOwner||'.'||inTypeName||';'; addScripts(vScripts, vScript);                      
      vScript.linea := '   BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '      pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        vScript.linea := '      pData.'||vColumnsList(i).column_name||' :=  '||compactName('p'||InitCap(vColumnsList(i).column_name))||';'; addScripts(vScripts, vScript);
      END LOOP;   
      vScript.linea := '      IF pData.Validar(''D'', pResultado.descripcion) then'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '         -- Existe'; addScripts(vScripts, vScript);
      vScript.linea := '         IF pData.Existe() = TRUE THEN'; addScripts(vScripts, vScript);
      vScript.linea := '            pData.Borrar ();'; addScripts(vScripts, vScript);
      vScript.linea := '         END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '      EXCEPTION WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.codigo := SQLCODE;'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.descripcion := SQLERRM;'; addScripts(vScripts, vScript);
      vScript.linea := '           RAISE_APPLICATION_ERROR(-20100, ''Error ''||SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '    END Borrar;'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);  
      vScript.linea := '    FUNCTION Consultar('; addScripts(vScripts, vScript);
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;            
      vScript.linea := '                     pResultado   IN OUT resultado)'; addScripts(vScripts, vScript);
      vScript.linea := '     RETURN '||InOwner||'.'||inTypeList||' IS'; addScripts(vScripts, vScript);
      vScript.linea := '    CURSOR cData IS'; addScripts(vScripts, vScript);
      vScript.linea := '    SELECT *'; addScripts(vScripts, vScript);
      vScript.linea := '          FROM '||InOwner||'.'||inTableName||' t1'; addScripts(vScripts, vScript);
      vScript.linea := '         WHERE '; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        IF i = 1 THEN
            vAnd := '';
        ELSE
            vAnd := 'AND';
        END IF;
        vScript.linea := '          '||vAnd||' (t1.'||vColumnsList(i).column_name||' = '||compactName('p'||InitCap(vColumnsList(i).column_name))||' OR '||compactName('p'||InitCap(vColumnsList(i).column_name))||' IS NULL)'; addScripts(vScripts, vScript);
      END LOOP;     
      vScript.linea := '          ;'; addScripts(vScripts, vScript);
      vAnd := 'AND';
      vScript.linea := '      TYPE tData IS TABLE OF cData%ROWTYPE;'; addScripts(vScripts, vScript);      
      vScript.linea := '      vData        tData;'; addScripts(vScripts, vScript);         
      vScript.linea := '      vDataList    '||InOwner||'.'||inTypeList ||' := '||InOwner||'.'||inTypeList||'();'; addScripts(vScripts, vScript);
      vScript.linea := '      pData        '||InOwner||'.'||inTypeName ||';'; addScripts(vScripts, vScript);
      vScript.linea := '      indice       NUMBER := 0;'; addScripts(vScripts, vScript);
      vScript.linea := '    BEGIN'; addScripts(vScripts, vScript);             
      vScript.linea := '       vDataList.DELETE;'; addScripts(vScripts, vScript);       
      vScript.linea := '       OPEN cData;'; addScripts(vScripts, vScript);
      vScript.linea := '       LOOP'; addScripts(vScripts, vScript);
      vScript.linea := '         FETCH cData BULK COLLECT INTO vData LIMIT 5000;'; addScripts(vScripts, vScript);
      vScript.linea := '         FOR i IN 1 .. vData.COUNT LOOP'; addScripts(vScripts, vScript);
      vScript.linea := '             pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        vScript.linea := '             pData.'||vColumnsList(i).column_name||' := vData(i).'||vColumnsList(i).column_name||';'; addScripts(vScripts, vScript);
      END LOOP;          
      vScript.linea := '             indice := indice + i;'; addScripts(vScripts, vScript);
      vScript.linea := '             vDataList.EXTEND;'; addScripts(vScripts, vScript);
      vScript.linea := '             vDataList(indice) := pData;'; addScripts(vScripts, vScript);   
      vScript.linea := '         END LOOP;'; addScripts(vScripts, vScript);
      vScript.linea := '         EXIT WHEN cData%NOTFOUND;'; addScripts(vScripts, vScript);
      vScript.linea := '       END LOOP;'; addScripts(vScripts, vScript);
      vScript.linea := '       CLOSE cData;'; addScripts(vScripts, vScript);      
      vScript.linea := ' '||CHR(13);
      vScript.linea := '       RETURN vDataList;'; addScripts(vScripts, vScript);  
      vScript.linea := '      EXCEPTION WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.codigo := SQLCODE;'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.descripcion := SQLERRM;'; addScripts(vScripts, vScript);
      vScript.linea := '           RAISE_APPLICATION_ERROR(-20404, ''Error ''||SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '    END Consultar;'; addScripts(vScripts, vScript);   
      vScript.linea := '    FUNCTION Comparar ( pData1  IN '||InOwner||'.'||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                        pData2  IN '||InOwner||'.'||inTypeName||','; addScripts(vScripts, vScript);
      vScript.linea := '                        pMode   IN VARCHAR2)'; addScripts(vScripts, vScript);    
      vScript.linea := '                                                -- O = (Compare between Objects pData1 and pData2),'; addScripts(vScripts, vScript);  
      vScript.linea := '                                                -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)'; addScripts(vScripts, vScript);
      vScript.linea := '      RETURN BOOLEAN IS'; addScripts(vScripts, vScript);
      vScript.linea := '      vIgual        BOOLEAN := FALSE;'; addScripts(vScripts, vScript);
      vScript.linea := '      vDataList     '||InOwner||'.'||inTypeList||' := '||InOwner||'.'||inTypeList||'();'; addScripts(vScripts, vScript);
      vScript.linea := '      vData         '||InOwner||'.'||inTypeName||' := '||InOwner||'.'||inTypeName||'();'; addScripts(vScripts, vScript);
      vScript.linea := '    BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '        IF pMode = ''O'' THEN'; addScripts(vScripts, vScript);
      vScript.linea := '            IF pData1 IS NOT NULL AND pData2 IS NOT NULL THEN'; addScripts(vScripts, vScript);
      vScript.linea := '                vIgual := pData1.Compare(pData2);'; addScripts(vScripts, vScript);
      vScript.linea := '            ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '                vIgual := TRUE;'; addScripts(vScripts, vScript);
      vScript.linea := '            END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '        ELSIF pMode = ''T'' THEN'; addScripts(vScripts, vScript);
      vScript.linea := '            vDataList := Consultar('; addScripts(vScripts, vScript);
      vTotalColumns := vColumnsList.COUNT;
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        IF i = vTotalColumns OR vTotalColumns = 1 THEN
            vComma := ' ';
        ELSE
            vComma := ','; 
        END IF;
        vScript.linea := '          '||compactName('p'||InitCap(vColumnsList(i).column_name))||' => pData2.'||vColumnsList(i).column_name||vComma; addScripts(vScripts, vScript);
      END LOOP;
      vComma := ',';
      vScript.linea := '                                   );'; addScripts(vScripts, vScript);
      vScript.linea := '            IF vDataList.COUNT > 0 THEN'; addScripts(vScripts, vScript);
      vScript.linea := '                vData := vDataList(1);'; addScripts(vScripts, vScript);
      vScript.linea := '                vIgual := pData1.Compare(vData);'; addScripts(vScripts, vScript);
      vScript.linea := '            ELSE'; addScripts(vScripts, vScript);
      vScript.linea := '                vIgual := FALSE;'; addScripts(vScripts, vScript);              
      vScript.linea := '            END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '        END IF;'; addScripts(vScripts, vScript);
      vScript.linea := '        RETURN vIgual;'; addScripts(vScripts, vScript); 
      vScript.linea := '    END Comparar;'; addScripts(vScripts, vScript);
      vScript.linea := '    FUNCTION Existe ('; addScripts(vScripts, vScript);
      vParamList := getParamList(pColumnsList      => vColumnsPrimary, 
                                 pTypeFormat       => 'P');
      FOR i IN 1.. vParamList.COUNT LOOP
          vScript.linea := '                      '||vParamList(i).linea; addScripts(vScripts, vScript);         
      END LOOP; 
      vScript.linea := '                     pResultado   IN OUT resultado)'; addScripts(vScripts, vScript);
      vScript.linea := '                     RETURN BOOLEAN IS'; addScripts(vScripts, vScript);
      vScript.linea := ' '||CHR(13); addScripts(vScripts, vScript);
      vScript.linea := '        pData        '||InOwner||'.'||inTypeName ||';'; addScripts(vScripts, vScript);
      vScript.linea := '    BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsPrimary.COUNT LOOP
        vScript.linea := '      pData.'||vColumnsList(i).column_name||' :=  '||compactName('p'||InitCap(vColumnsList(i).column_name))||';'; addScripts(vScripts, vScript);
      END LOOP;
      vScript.linea := '       RETURN  pData.Existe();'; addScripts(vScripts, vScript);
      vScript.linea := '      EXCEPTION WHEN OTHERS THEN'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.codigo := SQLCODE;'; addScripts(vScripts, vScript);
      vScript.linea := '           pResultado.descripcion := SQLERRM;'; addScripts(vScripts, vScript);
      vScript.linea := '           RAISE_APPLICATION_ERROR(-20404, ''Error ''||SQLERRM);'; addScripts(vScripts, vScript);
      vScript.linea := '    END Existe;'; addScripts(vScripts, vScript);      
      vScript.linea := '    FUNCTION Validar('; addScripts(vScripts, vScript);
      vParamList.DELETE;
      vParamList := getParamList(pColumnsList      => vColumnsList, 
                                 pTypeFormat       => 'P');
      FOR i IN 1 .. vParamList.COUNT LOOP
        vScript.linea := '                     '||vParamList(i).linea; addScripts(vScripts, vScript);
      END LOOP;       
      vScript.linea := '                     pOperacion   IN      VARCHAR2,         -- G=Generar, C=Crear, U=Actualizar, D=Borrar'; addScripts(vScripts, vScript);
      vScript.linea := '                     pError       IN OUT  VARCHAR2) RETURN BOOLEAN IS'; addScripts(vScripts, vScript);
      vScript.linea := '        pData        '||InOwner||'.'||inTypeName ||';'; addScripts(vScripts, vScript);
      vScript.linea := '    BEGIN'; addScripts(vScripts, vScript);
      vScript.linea := '      pData := '||InOwner||'.'||inTypeName ||'();'; addScripts(vScripts, vScript);
      FOR i IN 1 .. vColumnsList.COUNT LOOP
        vScript.linea := '      pData.'||vColumnsList(i).column_name||' :=  '||compactName('p'||InitCap(vColumnsList(i).column_name))||';'; addScripts(vScripts, vScript);
      END LOOP;
      vScript.linea := '        RETURN pData.Validar(pOperacion, pError);'; addScripts(vScripts, vScript);
      vScript.linea := '    END Validar;'; addScripts(vScripts, vScript);
      vScript.linea := '  END '||inPackageName||';'; addScripts(vScripts, vScript);            
      vScript.linea := ' /'; addScripts(vScripts, vScript);     
      vAnd := 'AND';
      vComma := ',';   
      RETURN vScripts;
      
   END generatePackageScript;   

   FUNCTION getTables(inOwner IN VARCHAR2)
      RETURN PKG_GENERATOR.tTables IS      

      vTables        PKG_GENERATOR.tTables := PKG_GENERATOR.tTables();
   BEGIN
      vTables.DELETE;
      OPEN c_tables(inOwner);
      LOOP
          FETCH c_tables BULK COLLECT INTO vTables LIMIT 1000;
          EXIT WHEN c_tables%NOTFOUND;
      END LOOP;
      CLOSE c_tables;

      RETURN vTables;
   END getTables;

   -- Listado de columnas de una tabla
   FUNCTION getColumnas(inOwner IN VARCHAR2, inTableName IN VARCHAR2)
      RETURN PKG_GENERATOR.tColumnsList IS 
           
      -- Cursor de las columnas de una tabla
      CURSOR c_columns(pOwner       IN VARCHAR2, 
                       pTableName   IN VARCHAR2) IS
      SELECT c.column_name,
             c.data_type,
             c.data_length,
             c.data_precision,
             c.data_scale,             
             c.nullable,
             c.column_id,
             c.primary_key,
             c.foreign_key
        FROM v_columnas c
       WHERE c.owner = UPPER(pOwner)
         AND c.table_name = UPPER(pTableName)
       ORDER BY c.column_id;      
      
      vColumnsList   PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();             
   BEGIN
      vColumnsList.DELETE;
      OPEN c_Columns(inOwner, inTableName);
      
      LOOP
        FETCH c_Columns BULK COLLECT INTO vColumnsList LIMIT 1000;       
        EXIT WHEN c_Columns%NOTFOUND;
      END LOOP;
      CLOSE c_Columns;            
      
      RETURN vColumnsList;
      
   EXCEPTION WHEN OTHERS THEN
      
      DBMS_OUTPUT.PUT_LINE('Datos de la columna no encontrados '||SQLERRM);
         
   END getColumnas;
   
   FUNCTION getColumnsPrimary(inColumns     IN tColumnsList,
                              inPrimary     IN VARCHAR2)
      RETURN PKG_GENERATOR.tColumnsList IS
      vColumns  PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();
      nIndx     NUMBER := 0;
   BEGIN
      vColumns.DELETE;
      FOR i IN 1 .. inColumns.COUNT LOOP
        IF inColumns(i).primary_key = inPrimary THEN
            nIndx := nIndx + 1;vColumns.EXTEND;vColumns(nIndx) :=  inColumns(i);           
        END IF;
      END LOOP;
      
      RETURN vColumns;
   END getColumnsPrimary; 
   
   FUNCTION getColumnsNotNull(inColumns     IN tColumnsList, 
                               inNull    IN VARCHAR2)
      RETURN PKG_GENERATOR.tColumnsList IS
     vColumns  PKG_GENERATOR.tColumnsList := PKG_GENERATOR.tColumnsList();
      nIndx     NUMBER := 0;
   BEGIN
      vColumns.DELETE;
      FOR i IN 1 .. inColumns.COUNT LOOP
        IF inColumns(i).nullable = inNull THEN
            nIndx := nIndx + 1;vColumns.EXTEND;vColumns(nIndx) :=  inColumns(i);           
        END IF;
      END LOOP;
      
      RETURN vColumns;
      
   END getColumnsNotNUll;
   
   
   FUNCTION getScriptValidaFK(inOwner       IN VARCHAR2,
                              inTableName   IN VARCHAR2,
                              inColumnName  IN VARCHAR2)
      RETURN TSCRIPTS IS
       -- Tablas FK
      CURSOR cTablasFK IS
      SELECT a.table_name, a.constraint_name, c_pk.owner r_owner, c_pk.table_name r_table_name, c_pk.constraint_name r_pk
        FROM all_cons_columns a
             JOIN all_constraints c  ON a.owner = c.owner AND a.constraint_name = c.constraint_name
             JOIN all_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
       WHERE c.constraint_type = 'R'
         AND a.owner = inOwner
         AND a.table_name = inTableName;
         
        -- 2 - Columnas por FK
        CURSOR c_ColFK(p_Owner          IN VARCHAR2,
                       p_tablename      IN VARCHAR2,
                       p_ConstraintFK   IN VARCHAR2) IS
        SELECT a.column_name, b.column_name r_column_name
          FROM all_cons_columns a,
               all_constraints c, 
               all_cons_columns b,              
               all_constraints c_pk                      
         WHERE a.owner = p_Owner
           AND a.table_name = p_tablename
           AND a.constraint_name = p_ConstraintFK
           AND a.owner = c.owner 
           AND a.constraint_name = c.constraint_name
           AND c.constraint_type = 'R'
           AND c.r_owner = c_pk.owner
           AND c.r_constraint_name = c_pk.constraint_name   
           AND b.owner = c_pk.owner 
           AND b.constraint_name = c_pk.constraint_name;  
        
        TYPE tTablasFK IS TABLE OF cTablasFK%ROWTYPE;
        TYPE tColFK IS TABLE OF c_ColFK%ROWTYPE;
        
        vTablasFK     tTablasFK := tTablasFK();
        vColFK        tColFK := tColFK();
         
        vScripts    TSCRIPTS := TSCRIPTS();
        vScript     TSCRIPT  := TSCRIPT();
        nIndex      NUMBER := 0;     
        vAnd        VARCHAR2(10);
    BEGIN
        
        OPEN cTablasFK;
        vScripts.DELETE;
         nIndex := nIndex + 1; vScript.linea := '          IF SELF.'||inColumnName||' IS NOT NULL THEN';
        LOOP
            vTablasFK.DELETE;
            FETCH cTablasFK BULK COLLECT INTO vTablasFK LIMIT 500;
            FOR i IN 1 .. vTablasFK.COUNT LOOP 
                vColFK.DELETE;
                OPEN c_ColFK(vTablasFK(i).r_owner, vTablasFK(i).table_name, vTablasFK(i).constraint_name);
                FETCH c_ColFK BULK COLLECT INTO vColFK LIMIT 100;
                CLOSE c_ColFK;
                 nIndex := nIndex + 1; vScript.linea := '            DECLARE';            
                 nIndex := nIndex + 1; vScript.linea := '              vExiste     NUMBER(1);';            
                 nIndex := nIndex + 1; vScript.linea := '            BEGIN';
                 nIndex := nIndex + 1; vScript.linea := ''||CHR(13);        
                 nIndex := nIndex + 1; vScript.linea := '              BEGIN';
                 nIndex := nIndex + 1; vScript.linea := '                  SELECT 1';
                 nIndex := nIndex + 1; vScript.linea := '                    INTO vExiste';
                 nIndex := nIndex + 1; vScript.linea := '                    FROM '||vTablasFK(i).r_owner||'.'||vTablasFK(i).r_table_name||' t ';
                 nIndex := nIndex + 1; vScript.linea := '                   WHERE ';
                FOR x IN 1 .. vColFK.COUNT LOOP
                    IF x = 1 THEN
                        vAnd := NULL;
                    ELSE
                        vAnd := 'AND';
                    END IF;
                     nIndex := nIndex + 1; vScript.linea := '                '||vAnd||' T.'||vColFK(x).r_column_name||' = SELF.'||vColFK(x).column_name;
                END LOOP;
                 nIndex := nIndex + 1; vScript.linea := '                    ;';
                 nIndex := nIndex + 1; vScript.linea := '              EXCEPTION WHEN NO_DATA_FOUND THEN';
                 nIndex := nIndex + 1; vScript.linea := '                  vExiste := 1; ';
                 nIndex := nIndex + 1; vScript.linea := '              END;';
                 nIndex := nIndex + 1; vScript.linea := ''||CHR(13);        
                 nIndex := nIndex + 1; vScript.linea := '                IF vExiste = 0 THEN';
                 nIndex := nIndex + 1; vScript.linea := '                    vValidar := FALSE;';
                 nIndex := nIndex + 1; vScript.linea := '                    p_Error := ''El '||inColumnName||' (''||SELF.'||inColumnName||'||'') no existe o no está registrado.'';';
                 nIndex := nIndex + 1; vScript.linea := '                    RETURN p_Error;';
                 nIndex := nIndex + 1; vScript.linea := '                END IF;';
                 nIndex := nIndex + 1; vScript.linea := ''||CHR(13);    
                 nIndex := nIndex + 1; vScript.linea := '            END;';
            END LOOP;
            EXIT WHEN cTablasFK%NOTFOUND;
        END LOOP;
         nIndex := nIndex + 1; vScript.linea := '          END IF;';
        CLOSE cTablasFK;
                
        
        RETURN vScripts;
        
    END getScriptValidaFK;

END PKG_GENERATOR;
/