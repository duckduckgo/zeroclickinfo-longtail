#!/usr/bin/env node
"use strict";

var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('quora.sqlite3');

var TODO   = 1;
var SAVED  = 2;
var PARSED = 3;

setTimeout(function() { }, 30000);
console.log("[1][2][3]");
