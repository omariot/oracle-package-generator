## Package generador de codigo PL/SQL

Este package permite generar por output el codigo necesario para crear package con operaciones CRUD en Oracle.
Recibe como parámetro el nombre de una table y muestra por output el código para generar Crud en package utilizando UDT.

## Instalación:

1 - Conectese a Oracle a traves de un editor de PL/SQL con un usuario con privilegios DBA
2 - Ejecute los siguiente scripts:
        ``` @1-Type_Scripts.sql
            @2-View_v_PrimaryKey.sql
            @3-View_v_Columnas.sql
            @4-Package_spec_Pkg_Generator.sql
            @5-Package_body_Pkg_Generator.sql
            ```

## Ejemplos en PLSQL:

```@6-Run_singleTest_Pkg_Generator.sql``` para generar simple de una sola tabla.
```@7-Run_EntireSchema_Test_Pkg_Generator.sql``` para generar de todas las tablas de un schema.


## Webservices con NodeJS

recuerde instalar los paquetes necesarios de Node ```npm install```

edite el archivo NodeJs/oracle_restapi_app/config/database.js y coloque las credenciales de conexion de su base de datos Oracle

## Ejemplo de ejecucion del Web services

1 - Cargue el servidor Node:
```
cd NodeJs/oracle_restapi_app/
```
```
node .
```

2 - Con Postman ejecute un POST
    URL:   ```http://localhost:3000/api/pkgen/types?```

    Header:  Content-Type: "application/json"

    Body:  {
    "owner": "OMARIOT",
    "tablename": "MYTABLE1",
    "packagename": "PKG_MYTABLE1",
    "typename": "MYTABLE1_OBJ",
    "typelist": "MYTABLE1_LIST"
    }
