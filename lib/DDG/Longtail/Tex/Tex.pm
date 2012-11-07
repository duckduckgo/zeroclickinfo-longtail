package DDG::Longtail::Tex;

use DDG::Meta::Information;
use DDG::Longtail;

name 'Tex';
description 'Typesetting answers';
source "Latex StackExchange"
icon_url "/i/tex.stackexchange.com.ico";
topics => 'special_interest';
categories => 'q/a';
primary_example_queries => 'matrix latex document';
secondary_example_queries => 'define macros lyx', 'resume template latex';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Tex/';
