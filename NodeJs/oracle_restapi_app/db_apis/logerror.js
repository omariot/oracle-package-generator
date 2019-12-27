/*jshint esversion: 8 */
const oracledb = require('oracledb');
const database = require('../services/database.js');

const baseQuery =
 `select iderror "iderror",
 errordate "errordate",
 owner "owner",
 packagename "packagename",
 programunit "programunit",
 piececodename "piececodename",
 errordescription "errordescription",
 username "username",
 hostname "hotname",
 programexecutor "programexecutor"
from log_error
where 1=1`;

const sortableColumns = ['iderror', 'errordate', 'owner', 'packagename', 'programunit', 'errordescription', 'username', 'hostname', 'programexecutor'];

async function find(context) {
  let query = baseQuery;
  const binds = {};

  if (context.iderror) {
    binds.iderror = context.iderror;
    query += '\nand iderror = :iderror';
  } 

  if (context.errorid) {
    binds.iderror = context.errorid;
    query += '\nand iderror = :iderror';
  } 
 
  if (context.errordate) {
    binds.error_date = context.error_date;
 
    query += '\nand trunc(error_date) = trunc(:error_date)';
  }

  if (context.sort === undefined) {
    query += '\norder by errordate asc';
  } else {
    let [column, order] = context.sort.split(':');
 
    if (!sortableColumns.includes(column)) {
      throw new Error('Invalid "sort" column');
    }
 
    if (order === undefined) {
      order = 'asc';
    }
 
    if (order !== 'asc' && order !== 'desc') {
      throw new Error('Invalid "sort" order');
    }
 
    query += `\norder by "${column}" ${order}`;
  }

  if (context.skip) {
    binds.row_offset = context.skip;
    query += '\noffset :row_offset rows';
  }
  
  /*const limit = (context.limit > 0) ? context.limit : 30;

  binds.row_limit = limit;

  query += '\nfetch next :row_limit rows only';*/

  console.log(query);
  const result = await database.simpleExecute(query, binds);

  return result.rows;
}

module.exports.find = find;

const createSql =
 `begin
    IA.LOGGER.LOG(INOWNER => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 
                  INPACKAGENAME => :package_name, 
                  INPROGRAMUNIT => :program_unit, 
                  INPIECECODENAME => :piece_codeName, 
                  INERRORDESCRIPTION => :error_description, 
                  INERRORTRACE => :error_trace, 
                  INEMAILNOTIFICATION => NULL, 
                  INPARAMLIST => IA.LOGGER.VPARAMLIST, 
                  INOUTPUTLOGGER => FALSE, 
                  INEXECUTIONTIME => NULL, 
                  outIdError => :iderror);

     IF IA.LOGGER.VPARAMLIST.COUNT > 0 THEN
          IA.LOGGER.VPARAMLIST.DELETE;
     END IF;
 end;`;

async function create(logerr) {
  var errorlog = Object.assign({}, logerr);

  errorlog = {
    dir: oracledb.BIND_OUT,
    type: oracledb.NUMBER
  };
  console.log(errorlog);
  var result = await database.simpleExecute(createSql, errorlog);

  errorlog.errorid = result.outBinds.iderror[0];
  console.log(result);
  return errorlog;  
  
}

module.exports.create = create;
/*
const updateSql =
 `update IA.LOG_ERROR
  set first_name = :first_name,
    last_name = :last_name,
    email = :email,
    phone_number = :phone_number,
    hire_date = :hire_date,
    job_id = :job_id,
    salary = :salary,
    commission_pct = :commission_pct,
    manager_id = :manager_id,
    department_id = :department_id
  where employee_id = :employee_id`;

async function update(emp) {
  const employee = Object.assign({}, emp);
  const result = await database.simpleExecute(updateSql, employee);

  if (result.rowsAffected && result.rowsAffected === 1) {
    return employee;
  } else {
    return null;
  }
}

module.exports.update = update;*/

const deleteSql =
 `begin
    
    delete from ia.log_error
    where iderror = :iderror;

    :rowcount := sql%rowcount;

  end;`;

async function del(id) {
  const binds = {
    iderror: id,
    rowcount: {
      dir: oracledb.BIND_OUT,
      type: oracledb.NUMBER
    }
  };
  const result = await database.simpleExecute(deleteSql, binds);

  return result.outBinds.rowcount === 1;
}

module.exports.delete = del;
