#!/usr/bin/env node
"use strict";

var sqlite3 = require('sqlite3').verbose();
var util    = require('./util.js');
var fs      = require('fs');
var spawn   = require('child_process').spawn;

var db = new sqlite3.Database('quora.sqlite3', runMain);


var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;

var LIMIT = 50;

var TARFILE_NAME = 'archive.tar';
var NEW_DIR_MODE = '0755';
var INSERT_IGNORE_SQL = 'INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)';

function runMain() {
    util.mkdirSync('./quora-data', NEW_DIR_MODE);
    db.serialize(function() {
        db.all("SELECT id, url FROM QUESTIONS WHERE status = ? LIMIT ?", SAVED, LIMIT, function(err, rows) {
            console.log("parse.js::err::", err);
            console.log("rows:", rows);
            // rows = rows.slice(0, 1);
            var rowsProcessed = 0;
            var filePaths = [ ];

            rows.forEach(function(row, i) {
                // Parse the file and set state to 'PARSED'
                var fPath = "./quora-data" + row.url;
                console.log("Parsing file:", fPath);
                var contents = fs.readFileSync(fPath, 'utf-8');
                contents = contents.substr(contents.indexOf('<body>'));
                contents = contents.substr(0, contents.indexOf('<script'));

                filePaths.push(fPath);

                // console.log("contents:", contents);

                util.loadDOM(contents, function($, window, errors) {
                    if (!errors) {
                        console.log("Successfully parsed file:", fPath);

                        // $(".question_link"). // other questions
                        // $(".question_text_edit:first").text() // title
                        // $(".inline_editor_content:first").text() // question text
                        
                        // Add file to tar archive
                        // tar -rf "./TARFILE_NAME" PATH_OF_FILE(S)_TO_ADD ...

                        // console.log("$:", $);
                        // console.log("innerHTML:", window.document.innerHTML);

                        var questionURLs = $(".question_link").map(function(i, q) {
                            return $(q).attr('href');
                        }).toArray();

                        console.log("questionURLs:", questionURLs);

                        var title = $(".question_text_edit:first").text();
                        var body = $(".inline_editor_content:first").text();

                        console.log("id:", row.id, "title:", title, "body:", body);

                        window.close();

                        // Add question to DB.
                        db.run("UPDATE QUESTIONS SET status=?, title=?, body=? WHERE id=?", 
                               PARSED, title, body, row.id);

                        // Add (potentially) new links to the DB.
                        questionURLs.forEach(function(questionURL) {
                            db.run(INSERT_IGNORE_SQL, questionURL, TODO, null, null);
                        });

                    } else {
                        console.error("Error parsing file:", fPath, errors);
                        return;
                    }

                    if (++rowsProcessed == rows.length) {
                        // Add all processed files to the tar archive TARFILE_NAME.
                        var tarArgs = ['-rf', './' + TARFILE_NAME ].concat(filePaths);
                        var tar = spawn('tar', tarArgs);
                        tar.on('exit', function(code) {
                            // Let process automatically exit. The caller will restart it.
                            // Empty function to delay process exit by 2 sec.
                            filePaths.forEach(function(filePath) {
                                fs.unlinkSync(filePath);
                            });
                            setTimeout(function() { }, 2000);
                        });
                    }

                });

            });

        });
    });

}
