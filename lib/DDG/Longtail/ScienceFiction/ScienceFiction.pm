package DDG::Longtail::ScienceFiction;

use DDG::Meta::Information;
use DDG::Longtail;

name 'ScienceFiction';
description 'Science Fiction answers';
source "Science Fiction StackExchange";
icon_url "/i/scifi.stackexchange.com.ico";
topics => 'geek';
categories => 'q/a';
primary_example_queries => 'asimov robots';
secondary_example_queries => 'origin of star wars', 'FTL drive cylon';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/ScienceFiction/';
