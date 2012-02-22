#!/usr/bin/env node
"use strict";

var sqlite3 = require('sqlite3').verbose();
var fs      = require('fs');
var path    = require('path');
var util    = require('./util.js');
var request = require('request');

var db = new sqlite3.Database('quora.sqlite3', runMain);

var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;
var ERROR  = 4;

var LIMIT = 10;
var NEW_DIR_MODE = '0755';

function runMain() {
    util.mkdirSync('./quora-data', NEW_DIR_MODE);

    db.serialize(function() {
        db.all("SELECT id, url FROM QUESTIONS WHERE status = ? LIMIT ?", TODO, LIMIT, function(err, rows) {
            // console.log("ERROR:", err);
            var rowsProcessed = 0;
            console.log("1");

            rows.forEach(function(row, i) {
                // Download the file and update the 'state' once the
                // download is complete.

                // console.log(row);

                var urlPath = row.url;
                var fDir =  "./quora-data" + path.dirname(urlPath, NEW_DIR_MODE);
                var fPath = "./quora-data" + urlPath;

                // console.log("Creating directory:", fDir);
                util.mkdirSync(fDir, NEW_DIR_MODE);

                var rOpts = {
                    url: 'http://www.quora.com' + urlPath, 
                    headers: {
                        'User-Agent': 'DuckDuckBot/1.1'
                    }
                };
                request(rOpts, function(error, response, body) {
                    // console.log(body);
                    // console.log("downloaded:", row.url);

                    if (!error && response.statusCode === 200) {
                        // Write file to disk.
                        fs.writeFileSync(fPath, body);

                        // Update DB.
                        db.run("UPDATE QUESTIONS SET status=? WHERE id=?", 
                               SAVED, row.id);
                    } else {
                        // Set this row in the 'ERROR' state.
                        db.run("UPDATE QUESTIONS SET status=? WHERE id=?", 
                               ERROR, row.id);
                    }

                    if (++rowsProcessed == rows.length) {
                        // Restart downloader after LIMIT sec
                        setTimeout(runMain, LIMIT * 1000);
                    }

                });

            });

        });
    });

}
