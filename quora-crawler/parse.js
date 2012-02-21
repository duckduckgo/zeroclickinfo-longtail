#!/usr/bin/env node
"use strict";

var sqlite3 = require('sqlite3').verbose();
var util    = require('./util.js');
var fs      = require('fs');

var db = new sqlite3.Database('quora.sqlite3', runMain);


var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;

var LIMIT = 50;

var TARFILE_NAME = 'archive.tar';
var NEW_DIR_MODE = '0755';

function runMain() {
    fs.mkdirSync('./quora-data', NEW_DIR_MODE);
    db.serialize(function() {
        db.all("SELECT id, url FROM QUESTIONS WHERE state = ? LIMIT ?", SAVED, LIMIT, function(err, rows) {
            for (var i = 0; i < rows.length; ++i) {
                // Parse the file and set state to 'PARSED'
                var fPath = "./quora-data" + rows[i].url;
                util.loadDOM(fs.readFileSync(fPath), function($, window, errors) {
                    // $(".question_link"). // other questions
                    // $(".question_text_edit:first").text() // title
                    // $(".inline_editor_content:first").text() // question text

                    // Add file to tar archive
                    // tar -rf "./TARFILE_NAME" PATH_OF_FILE_TO_ADD

                });
            }
        });
    });

}
