package DDG::Longtail::CrossValidated;

use DDG::Meta::Information;
use DDG::Longtail;

name 'CrossValidated';
description 'Statistics answers';
source "Statistics StackExcchange";
icon_url "/i/stats.stackexchange.com.ico";
topics => 'math';
categories => 'q/a';
primary_example_queries => 'spatial models car';
secondary_example_queries => 'structural equation modeling techniques', 'famous statistician quotes';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/CrossValidated/';
