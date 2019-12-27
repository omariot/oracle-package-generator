--DROP VIEW V_COLUMNAS;

CREATE OR REPLACE FORCE VIEW V_COLUMNAS
(
   OWNER,
   TABLE_NAME,
   COLUMN_NAME,
   DATA_TYPE,
   DATA_LENGTH,
   DATA_PRECISION,
   DATA_SCALE,
   NULLABLE,
   COLUMN_ID,
   PRIMARY_KEY,
   FOREIGN_KEY
) AS
     SELECT DISTINCT
            c.owner,
            c.table_name,
            c.column_name,
            c.data_type,
            c.data_length,
            c.data_precision,
            c.data_scale,
            c.nullable,
            c.column_id,
            NVL (o.primary_key, 'N') primary_key,
            NVL (f.foreign_key, 'N') foreign_key
       FROM SYS.ALL_TAB_COLUMNS c,
            (SELECT p.owner,
                    p.table_name,
                    P.column_name,
                    p.primary_key
               FROM V_PRIMARYKEY p) o,
            (SELECT a.owner,
                    a.table_name,
                    a.column_name,
                    'S' Foreign_key
               FROM all_cons_columns a, all_constraints c
              WHERE a.owner = c.owner
                AND a.constraint_name = c.constraint_name
                AND c.constraint_type = 'R') f
      WHERE c.owner = o.owner(+)
        AND c.table_name = o.table_name(+)
        AND c.column_name = o.column_name(+)
        AND c.owner = f.owner(+)
        AND c.table_name = f.table_name(+)
        AND c.column_name = f.column_name(+)
   ORDER BY c.column_id;
