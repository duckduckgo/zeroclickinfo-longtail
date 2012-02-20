"use strict";

var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('quora.sqlite3', createTables);

var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;

function runMain() {

    // Spawn a task that downloads links in the TODO state

    // 
    // Spawn a task that parses downloaded links in the SAVED state,
    // converts them to PARSED, enters fields in the DB and populates
    // the DB with more links in the TODO state.
    // 
    // If this task dies, we span one more to ensure that such a task
    // is always alive. This will happen because we will periodically
    // exit to work around the jsdom memory leak issue.
    // 
}

function createTables() {
    db.serialize(function() {
        db.run("CREATE TABLE IF NOT EXISTS QUESTIONS (id INT PRIMARY KEY AUTOINCREMENT, " + 
               "url VARCHAR(1024) UNIQUE, status INT(1), title TEXT, body TEXT) ");

        // Insert Seed Links
        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/What-do-you-hate-most-about-RabbitMQ', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/What-are-the-best-JMS-queue-implementations', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/Distributed-Caching/What-are-some-distributed-cache-systems', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/How-do-SSD-drives-change-things-for-main-memory-databases', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/Philanthropy-and-Charities/Should-I-donate-to-a-local-charity-focused-on-helping-local-women-and-girls-or-a-charity-focused-on-helping-women-and-girls-in-the-developing-world', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/How-does-Gearman-compare-with-a-messaging-queue-system-like-Beanstalkd-RabbitMQ-and-Amazon-SQS', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/Imagine-building-Quora-or-Facebook-today-using-Java-Spring-would-you-chose-ActiveMQ-ZeroMQ-RabbitMQ-or-a-XMPP-server', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/Microsoft-History/Why-did-Steve-Ballmer-say-except-in-Nebraska-at-the-end-of-the-Windows-1-0-ad', TODO, null, null);

        db.run("INSERT OR IGNORE INTO QUESTIONS (url, status, title, body) VALUES (?, ?, ?, ?)", 
               '/What-are-the-privacy-differences-between-ixquick-and-duckduckgo', TODO, null, null, runMain);


    });
}
