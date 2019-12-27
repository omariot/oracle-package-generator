/*jshint esversion: 8 */
const logerror = require('../db_apis/logerror.js');

async function get(req, res, next) {
  try {
    var context = {};
    context.iderror =req.query.iderror;
    context.skip = parseInt(req.query.skip, 10);
    context.limit = parseInt(req.query.limit, 10);
    context.sort = req.query.sort;
    context.error_date = req.query.error_date;

    var rows = await logerror.find(context);

    if (req.params.iderror) {
      if (rows.length === 1) {
        res.status(200).json(rows[0]);
      } else {
        res.status(404).end();
      }
    } else {
      res.status(200).json(rows);
    }
  } catch (err) {
    next(err);
  }
}

module.exports.get = get;

function getErrorlogFromRec(req) {
  var logerror = {
    iderror: req.body.iderror,
    package_name: req.body.package_name, 
    program_unit: req.body.program_unit, 
    piece_codeName: req.body.piece_codeName, 
    error_description: req.body.error_description, 
    error_trace: req.body.error_trace
  };

  return logerror;
}

async function post(req, res, next) {
  try {
    var logerr = getErrorlogFromRec(req);

    logerr = await logerror.create(logerr);

    res.status(201).json(logerr);
  } catch (err) {
    next(err);
  }
}

module.exports.post = post;
/*
async function put(req, res, next) {
  try {
    let employee = getEmployeeFromRec(req);

    employee.employee_id = parseInt(req.params.id, 10);

    employee = await employees.update(employee);

    if (employee !== null) {
      res.status(200).json(employee);
    } else {
      res.status(404).end();
    }
  } catch (err) {
    next(err);
  }
}

module.exports.put = put;*/

async function del(req, res, next) {
  try {
    var iderror = parseInt(req.params.iderror, 10);

    var success = await errorlog.delete(iderror);

    if (success) {
      res.status(204).end();
    } else {
      res.status(404).end();
    }
  } catch (err) {
    next(err);
  }
}

module.exports.delete = del;

