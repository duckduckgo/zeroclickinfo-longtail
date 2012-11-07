package DDG::Longtail::Wikipedia;

use DDG::Meta::Information;
use DDG::Longtail;

name 'Wikipedia';
description 'Wikipedia full text search';
source "Wikipedia";
icon_url "/i/wikipedia.com.ico"
topics => 'everyday';
categories => 'q/a';
primary_example_queries => 'snow albedo';
secondary_example_queries => 'darpa early history', 'will mcraven';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Wikipedia/';
