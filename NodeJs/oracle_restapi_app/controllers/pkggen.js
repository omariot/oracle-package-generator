/*jshint esversion: 8 */
const pkgen = require('../db_apis/pkggen.js');

async function post(req, res, next) {
    try {
        var context = {};
        context.owner =req.body.owner;
        context.tablename =req.body.tablename;
        context.packagename =req.body.packagename;
        context.typename =req.body.typename;
        context.typelist =req.body.typelist;
        
        var rows = await pkgen.generatePkg(context);      
          

        res.status(201).json(rows);

        if (rows.length === 1) {
            res.status(200).json(rows[0]);
        } else {
            res.status(404).end();
        } 
      } catch (err) {
        next(err);
      }        
  }

  module.exports.post = post;