const express = require('express');
const router = new express.Router();

const employees = require('../controllers/employees.js');
const logerror = require('../controllers/logerror.js');
const pkgen = require('../controllers/pkggen.js');

router.route('/employees/:id?')
  .get(employees.get)
  .post(employees.post)
  .put(employees.put)
  .delete(employees.delete);

  router.route('/logerror/:iderror?')
  .get(logerror.get)
  .post(logerror.post)
  .delete(logerror.delete);

  router.route('/pkgen/:types?').post(pkgen.post);

module.exports = router;
