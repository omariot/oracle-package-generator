-- First you must be connected with SYS AS SYSDBA 
-- ALTER SESSION SET "_ORACLE_SCRIPT"=true; -- only use this instruction on Oracle 12c or superior
CREATE USER PKGEN IDENTIFIED BY ORACLE;
GRANT CONNECT, DBA, RESOURCE TO PKGEN;
GRANT EXECUTE ON UTL_FILE TO PKGEN;

/* -- Creation of Directory -- */


-- For Windows -- For Linux must used CREATE OR REPLACE DIRECTORY DIR_PKGEN AS '/mnt/tempdir';
CREATE OR REPLACE DIRECTORY DIR_PKGEN AS 'c:\temp\';
GRANT EXECUTE, READ, WRITE ON DIRECTORY DIR_PKGEN TO PKGEN WITH GRANT OPTION;

--  Connecting to Schema User
CONNECT PKGEN/ORACLE;

-- Executing Objects Creations
@1-Type_Scripts.sql
@2-View_v_PrimaryKey.sql 
@3-View_v_Columnas.sql 
@4-Package_spec_Pkg_Generator.sql 
@5-Package_body_Pkg_Generator.sql

