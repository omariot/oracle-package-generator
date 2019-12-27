--DROP VIEW V_PRIMARYKEY;

CREATE OR REPLACE FORCE VIEW V_PRIMARYKEY
(
   OWNER,
   TABLE_NAME,
   COLUMN_NAME,
   PRIMARY_KEY
) AS
   SELECT p.owner,
          p.table_name,
          cc.column_name,
          'S' primary_key
     FROM sys.all_constraints p, sys.all_cons_columns cc
    WHERE p.constraint_type = 'P'
      AND p.status = 'ENABLED'
      AND p.owner = cc.owner
      AND p.constraint_name = cc.constraint_name;
