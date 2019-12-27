/*jshint esversion: 8 */
const oracledb = require('oracledb');
const dbConfig = require('../config/database.js');

async function initialize() {
  await oracledb.createPool(dbConfig.ademiqa1Pool);
}

module.exports.initialize = initialize;

async function close() {
  await oracledb.getPool().close();
}

module.exports.close = close;

function getUserDefinerType(typename) {

  return new Promise(async (resolve, reject) => {
    var connection;    
    try {
      connection = await oracledb.getConnection();   
      const scriptsClass = await connection.getDbObjectClass(typename);
      resolve(scriptsClass);
    } catch (err) {
      reject(err);
    } 
  });
}
module.exports.getUserDefinerType = getUserDefinerType;

function simpleExecute(statement, binds = [], opts = {}) {
  return new Promise(async (resolve, reject) => {
    let conn;
 
    opts.autoCommit = true;
 
    try {
      conn = await oracledb.getConnection(); 

      const result = await conn.execute(statement, binds, opts);
      resolve(result);
    } catch (err) {
      reject(err);
    } 
  });
}

module.exports.simpleExecute = simpleExecute;
