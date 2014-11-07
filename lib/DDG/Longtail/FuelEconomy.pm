package DDG::Longtail::FuelEconomy;

use DDG::Longtail;

primary_example_queries '2014 Honda Fit fuel economy', '2014 Prius v mpg';
secondary_example_queries 'fuel economy 2012 Nissan Leaf', 'mpg 2011 Infiniti M37x';
description "EPA Fuel Economy data";
name "Fuel Economy";
icon_url 'http://www.fueleconomy.gov/favicon.ico';
source 'FuelEconomy.gov';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/tree/master/share/longtail/fuel_economy';
topics 'special_interest';
category 'reference';
attribution
    github => ['zachthompson', 'Zach Thompson'];

1;
