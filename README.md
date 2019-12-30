## Package generador de codigo PL/SQL

Este package permite generar por output el codigo necesario para crear package con operaciones CRUD en Oracle.
Recibe como parámetro el nombre de una table y muestra por output el código para generar Crud en package utilizando UDT.

## Instalación:

1 - Conectese a Oracle a traves de un editor de PL/SQL con un usuario con privilegios DBA

2 - Ejecute el siguiente script en SQL Plus:
        ```@0- Install_Pkgen.sql```

## Ejemplos en PL/SQL:

```@6-Run_singleTest_Pkg_Generator.sql``` para generar un package simple de una sola tabla.

```@7-Run_EntireSchema_Test_Pkg_Generator.sql``` para generar packages de todas las tablas de un schema.

```@8-Run_EntireSchemaWithFiles_Test_Pkg_Generator.sql``` para generar package de todoas las tabla de un schema en archivos de scripts.


## Webservices con NodeJS

Primero debes tener instalado  [NodeJs](https://nodejs.org/es/) en tu equipo

Descomprima el proyecto en una carpeta o directorio deseado.

Edite el archivo NodeJs/oracle_restapi_app/config/database.js y coloque las credenciales de conexion de su base de datos Oracle

Recuerde instalar los paquetes necesarios del proyecto de NodeJs ```npm install``` desce la Línea de comandos.

## Ejemplo de ejecución del Web services

1 - Cargue el servidor Node:

```cd NodeJs/oracle_restapi_app/```

```node .```

2 - Opcional con [Postman](https://www.getpostman.com/) ejecute un request POST con la siguiente estructura JSON

    URL:   http://localhost:3000/api/pkgen/types?

    Header:  Content-Type: "application/json"

    Body:  {
    "owner": "PKGEN",
    "tablename": "MYTABLE1",
    "packagename": "PKG_MYTABLE1",
    "typename": "MYTABLE1_OBJ",
    "typelist": "MYTABLE1_LIST"
    }

