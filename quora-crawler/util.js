"use strict";

var fs      = require('fs');
var qs      = require('querystring');
var jsdom   = require('jsdom');
var request = require('request');
var HTML5   = require('html5');

var jquery  = fs.readFileSync(require.resolve("./jquery.min.js"), 'utf-8');

function loadDOM(html, cb) {
    function _foo() {
        var window = jsdom.jsdom(null, null, {parser: HTML5}).createWindow()
        var parser = new HTML5.Parser({document: window.document});
        parser.parse(html);
        
        jsdom.jQueryify(window, require.resolve("./jquery.min.js"), function(window, jquery) {
            cb(jquery, window, null);
        });
        
        return;
    }

    try {
        jsdom.env({
            html: html, 
            // parser: html5, 
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

function mkdirSync(path, mode) {
    try {
        return fs.mkdirSync(path, mode);
    } catch(ex) {
        // console.error("util.js::mkdirSync::", ex);
    }
    return 0;
}

exportVars('loadDOM mkdirSync');
