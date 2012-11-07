package DDG::Longtail::AskUbuntu;

use DDG::Meta::Information;
use DDG::Longtail;

name 'AskUbuntu';
description 'Ubuntu answers';
source "Ubuntu StackExchange";
icon_url "/i/askubuntu.com.ico";
topics 'sysadmin';
category 'q/a';
primary_example_queries 'battery life ubuntu kubuntu';
secondary_example_queries 'gedit split pane', 'reset keyboard layout';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/AskUbuntu/';
