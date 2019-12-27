module.exports = {
  ademiqa1Pool: {
    user: process.env.NODE_ORACLEDB_USER || "system",//process.env.HR_USER,
    password: process.env.NODE_ORACLEDB_PASSWORD || "oracle",//process.env.HR_PASSWORD,
    connectString: process.env.NODE_ORACLEDB_CONNECTIONSTRING || "localhost/XE:1521",//process.env.HR_CONNECTIONSTRING,
    poolMin: 5,
    poolMax: 5,
    poolIncrement: 0
  }
};