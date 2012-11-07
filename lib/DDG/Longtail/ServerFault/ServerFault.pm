package DDG::Longtail::ServerFault;

use DDG::Meta::Information;
use DDG::Longtail;

name 'ServerFault';
description 'System Administration answers';
source "Server Fault";
icon_url "/i/www.serverfault.com.ico";
topics 'sysadmin';
category 'q/a';
primary_example_queries 'http compression windows server 2003';
secondary_example_queries 'mysql backup', 'ssh tunnel subversion proxy';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/ServerFault/';
