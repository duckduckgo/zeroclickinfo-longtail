package DDG::Longtail::Drupal;

use DDG::Meta::Information;
use DDG::Longtail;

name 'Drupal';
description 'Drupal answers';
source "Drupal StackExchange";
icon_url "/i/drupal.stackexchange.com.ico";
topics 'web_design';
category 'q/a';
primary_example_queries 'convert wordpress to drupal theme';
secondary_example_queries 'hook_preprocess_page', 'drupal_goto';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Drupal/';
