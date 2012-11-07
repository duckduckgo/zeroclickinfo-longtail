package DDG::Longtail::WordPress;

use DDG::Meta::Information;
use DDG::Longtail;

name 'WordPress';
description 'WordPress discussion';
source "WordPress StackExchange";
icon_url "/i/wordpress.stackexchange.com.ico";
topics 'special_interest';
category 'q/a';
primary_example_queries 'wpdb separate database';
secondary_example_queries 'wordpress locate_template', 'wordpress core files';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/WordPress/';
