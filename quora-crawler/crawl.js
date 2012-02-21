#!/usr/bin/env node
"use strict";

var sqlite3 = require('sqlite3').verbose();
var util  = require('util');
var spawn = require('child_process').spawn;

var db = new sqlite3.Database('quora.sqlite3', createTables);

var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;

var INSERT_IGNORE_SQL = 'INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)';

function runMain() {

    // Spawn a task that downloads links in the TODO state

    var download = spawn('./download.js');

    console.log(download, download.pid);

    download.stdout.on('data', function(d) {
        console.log("DATA:", d.toString());
    });

    setTimeout(function() { }, 30000);

    // 
    // Spawn a task that parses downloaded links in the SAVED state,
    // converts them to PARSED, enters fields in the DB and populates
    // the DB with more links in the TODO state.
    // 
    // If this task dies, we span one more to ensure that such a task
    // is always alive. This will happen because we will periodically
    // exit to work around the jsdom memory leak issue.
    // 

    var MIN_DELAY = 20 /* 20 second */;
    function spawnParser() {
        var parse = spawn('./parse.js');
        var started = new Date();
        parse.on('exit', function(code) {
            var diff = new Date() - started;
            if (diff > MIN_DELAY*1000) {
                spawnParser();
            } else {
                setTimeout(spawnParser, (20 - MIN_DELAY) * 1000);
            }
        });
    }

}

function createTables() {
    db.serialize(function() {
        db.run("CREATE TABLE IF NOT EXISTS QUESTIONS (id INTEGER PRIMARY KEY AUTOINCREMENT, " + 
               "url VARCHAR(1024) UNIQUE, status INTEGER(1), title TEXT, body TEXT) ");

        // Insert Seed Links
        db.run(INSERT_IGNORE_SQL, 
               '/What-do-you-hate-most-about-RabbitMQ', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/What-are-the-best-JMS-queue-implementations', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/Distributed-Caching/What-are-some-distributed-cache-systems', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/How-do-SSD-drives-change-things-for-main-memory-databases', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/Philanthropy-and-Charities/Should-I-donate-to-a-local-charity-focused-on-helping-local-women-and-girls-or-a-charity-focused-on-helping-women-and-girls-in-the-developing-world', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/How-does-Gearman-compare-with-a-messaging-queue-system-like-Beanstalkd-RabbitMQ-and-Amazon-SQS', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/Imagine-building-Quora-or-Facebook-today-using-Java-Spring-would-you-chose-ActiveMQ-ZeroMQ-RabbitMQ-or-a-XMPP-server', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/Microsoft-History/Why-did-Steve-Ballmer-say-except-in-Nebraska-at-the-end-of-the-Windows-1-0-ad', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/What-are-the-privacy-differences-between-ixquick-and-duckduckgo', TODO, null, null);

        db.run(INSERT_IGNORE_SQL, 
               '/HBase/From-an-overall-cluster-throughput-point-of-view-why-would-replicating-asynchronously-run-faster-than-sync-replication', 
               TODO, null, null, runMain);

    });
}
