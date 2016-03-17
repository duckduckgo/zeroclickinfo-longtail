package DDG::Longtail::Lyrics;

use DDG::Longtail;

name 'CVE Summary';
description 'Displays a short summary of a Common Vulnerabilities and Exposures (CVE).';
source "https://cve.mitre.org";
icon_url "/i/cve.mitre.org.ico";
topics 'security';
category 'q/a';
primary_example_queries 'CVE-1999-0002';
#secondary_example_queries 'panama lyrics', 'lean on me lyrics';
code_url 'https://github.com/duckduckgo/zeroclickinfo-longtail/blob/master/lib/DDG/Longtail/Lyrics/';

1;
