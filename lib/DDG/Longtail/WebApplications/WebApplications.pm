package DDG::Longtail::WebApplications;

use DDG::Meta::Information;
use DDG::Longtail;

name 'WebApplications';
description 'Web application discussion';
source "WebApplication StackExchange";
icon_url "/i/webapps.stackexchange.com.ico";
topics 'programming';
category 'q/a';
primary_example_queries 'delete my facebook account';
secondary_example_queries 'facebook detects gmail', 'forward multiple emails gmail';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/WebApplications/';
