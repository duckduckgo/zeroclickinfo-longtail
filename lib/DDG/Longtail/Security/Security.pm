package DDG::Longtail::Security;

use DDG::Meta::Information;
use DDG::Longtail;

name 'Security';
description 'Security answers';
source "Security StackExchange";
icon_url "/i/security.stackexchange.com.ico";
topics => 'programming';
categories => 'q/a';
primary_example_queries => 'asp.net security check list';
secondary_example_queries => 'security audit php', 'rails xss prevention';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Security/';
