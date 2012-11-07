package DDG::Longtail::StackOverflow;

use DDG::Meta::Information;
use DDG::Longtail;

name 'StackOverflow';
description 'Programming answers';
source "Stack Overflow";
icon_url "/i/www.stackoverflow.com.ico";
topics 'programming';
category 'q/a';
primary_example_queries 'apache nginx';
secondary_example_queries 'sorting numbers in ram', 'BerkeleyDB Concurrency';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/StackOverflow/';
