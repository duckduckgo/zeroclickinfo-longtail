# Yoga Asanas Processor

## Synopsis

Run

    process.pl


    *******************************************************************
        USAGE: process.pl [-data path/to/data] [-no_*] [-v]

        -data: (optional) path to the download directory
        -no_*: (optional) turn off download of a site:
          ayi: ashtanga.info 
           yc: yoga.com
           yp: theyogaposts.com 
        -v: (optional) Turn on some parse warnings
        -h: (optional) print this usage

    *******************************************************************

## Description

Processes yoga asana information from multiple websites:

* ashtanga.info
* yoga.com
* theyogaposes.com

Sites can be toggled on/off and additional sites can easily be added.

Generates an XML file containing items with the following data:

1. Name of asana
2. English translation of asana
3. Link to image of the asana
4. Series in which the asana appears, if known
5. Position of asana in series, if known

Source files are archived and will not be re-downloaded if they exist.

## Dependencies 

* WWW::Mechanize
* File::Path
* File::Slurp
* YAML::XS
* HTML::TableExtract
* Text::Autoformat

## Contributing

<https://github.com/duckduckgo/zeroclickinfo-longtail>

## Reporting Issues

<https://github.com/duckduckgo/zeroclickinfo-longtail/issues>

## Author

Zach Thompson <zach@duckduckgo.com>
