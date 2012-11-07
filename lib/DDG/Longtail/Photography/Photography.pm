package DDG::Longtail::Photography;

use DDG::Meta::Information;
use DDG::Longtail;

name 'Photography';
description 'Photography answers';
source "Photography StackExchange";
icon_url "/i/photo.stackexchange.com.ico";
topics => 'special_interest';
categories => 'q/a';
primary_example_queries => 'dust inside SLR';
secondary_example_queries => 'petal shaped lens hoods', 'control contrast';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Photography/';
