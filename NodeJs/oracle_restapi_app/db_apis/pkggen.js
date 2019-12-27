/*jshint esversion: 8 */
const oracledb = require("oracledb");
const database = require("../services/database.js");

async function generatePkg(datos) {
  var bindsType = Object.assign({});
  const scriptsDef = await database.getUserDefinerType("TSCRIPTS");
  var generateTypeSql = `DECLARE
            vScripts        TSCRIPTS := TSCRIPTS();
        BEGIN
            vScripts.DELETE;
            vScripts  := PKG_GENERATOR.generateTypeScript(:owner,
                                                          :tablename,
                                                          :typename,
                                                          :typelist
                                                         );

            :scripts := vScripts;
        END;`;
  opts = { outFormat: oracledb.OUT_FORMAT_OBJECT };

  bindsType.owner = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.owner
  };
  bindsType.tablename = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.tablename
  };
  bindsType.typename = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.typename
  };
  bindsType.typelist = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.typelist
  };
  bindsType.scripts = {
    dir: oracledb.BIND_OUT,
    type: scriptsDef
  };
  //console.log(bindsType);
  var resultType = await database.simpleExecute(
    generateTypeSql,
    bindsType,
    opts
  );
  var scriptResultType = resultType.outBinds.scripts;
  var scripts = [];
  for (const b of scriptResultType) {
    scripts.push(b.LINEA);
    //console.log(b.LINEA);
  }

  var generatePkgSql = `
        DECLARE
            vScripts        TSCRIPTS := TSCRIPTS();
        BEGIN
            vScripts.DELETE;
            vScripts  := PKG_GENERATOR.generatePackageScript(:owner,
                                                            :tablename,
                                                            :packagename,
                                                            :typename,
                                                            :typelist);
            :scripts := vScripts;
        END;
        `;

  opts = { outFormat: oracledb.OUT_FORMAT_OBJECT };
  var bindsPkg = Object.assign({});
  bindsPkg.owner = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.owner
  };
  bindsPkg.tablename = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.tablename
  };
  bindsPkg.packagename = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.packagename
  };
  bindsPkg.typename = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.typename
  };
  bindsPkg.typelist = {
    dir: oracledb.BIND_IN,
    type: oracledb.DB_TYPE_VARCHAR,
    val: datos.typelist
  };
  bindsPkg.scripts = {
    dir: oracledb.BIND_OUT,
    type: scriptsDef
  };
  //console.log(bindsPkg);
  var resultPkg = await database.simpleExecute(generatePkgSql, bindsPkg, opts);
  var scriptResultPkg = resultPkg.outBinds.scripts;

  for (const b of scriptResultPkg) {
    scripts.push(b.LINEA);
    //console.log(b.LINEA);
  }
  return scripts;
}

module.exports.generatePkg = generatePkg;
