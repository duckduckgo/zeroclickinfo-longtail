#!/usr/bin/env node
"use strict";

var sqlite3 = require('sqlite3').verbose();
var fs      = require('fs');
var path    = require('path');
var util    = require('./util.js');
var request = require('request');

var db = new sqlite3.Database('quora.sqlite3', runMain);

console.log("FOO");

var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;
var ERROR  = 4;

var LIMIT = 50;
var NEW_DIR_MODE = '0755';

function runMain() {
    console.log("[1] Started download.js");
    util.mkdirSync('./quora-data', NEW_DIR_MODE);
    console.log("[2] Started download.js");

    db.serialize(function() {
        db.all("SELECT id, url FROM QUESTIONS WHERE status = ? LIMIT ?", TODO, LIMIT, function(err, rows) {
            console.log("ERROR:", err);

            for (var i = 0; i < rows.length; ++i) {
                // Download the file and update the 'state' once the
                // download is complete.

                var urlPath = rows[i].url;
                var fDir =  "./quora-data" + path.dirname(urlPath, NEW_DIR_MODE);
                var fPath = "./quora-data" + urlPath;

                console.log("Creating directory:", fDir);
                util.mkdirSync(fDir, NEW_DIR_MODE);

                request('http://www.quora.com' + urlPath, function(error, response, body) {
                    // console.log(body);
                    if (!error && response.statusCode === 200) {
                        fs.writeFileSync(fPath, body);
                    } else {
                        // TODO: Set this row in the 'ERROR' state.
                    }
                });


            }
        });
    });

}
