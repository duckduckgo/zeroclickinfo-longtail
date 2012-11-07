package DDG::Longtail::Unix;

use DDG::Meta::Information;
use DDG::Longtail;

name 'Unix';
description 'Unix answers';
source "Unix StackExchange";
icon_url "/i/unix.stackexchange.com.ico";
topics => 'sysadmin';
categories => 'q/a';
primary_example_queries => 'rc.local equivalent shutdown';
secondary_example_queries => 'sftp to scp', 'nano syntax highlighting';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Unix/';
