package DDG::Longtail::ProWebmasters;

use DDG::Meta::Information;
use DDG::Longtail;

name 'ProWebmasters';
description 'Webmaster answers';
source "ProWebmasters StackExchange";
icon_url "/i/webmasters.stackexchange.com.ico";
topics => 'sysadmin';
categories => 'q/a';
primary_example_queries => 'robots.txt configuration';
secondary_example_queries => 'sitemaps html', 'css reduction';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/ProWebmasters/';
