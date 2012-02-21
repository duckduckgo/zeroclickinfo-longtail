"use strict";

var fs      = require('fs');
var qs      = require('querystring');
var jsdom   = require('jsdom');
var request = require('request');
var jquery  = fs.readFileSync(require.resolve("./jquery.min.js"), 'utf-8');

function loadDOM(html, cb) {
    try {
        jsdom.env({
            html: html, 
            src: [
                jquery
            ],
            done: function(errors, window) {
                cb(window.$, window, errors);
            }
        });
    } catch(ex) {
        cb(null, null, ex);
    }
}

function exportVars(vars) {
    // console.error('vars:', vars);
    if (typeof vars === 'string') {
        vars = vars.split(/\s+/);
    }
    for (var i = 0; i < vars.length; ++i) {
        exports[vars[i]] = eval(vars[i]);
    }
}

exportVars('loadDOM');
