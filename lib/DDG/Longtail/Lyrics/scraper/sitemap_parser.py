"""
Copyright (c) 2010, Dhruv Matani

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

import xml.dom.minidom
from datetime import datetime as date

testdoc = """\
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url>
        <loc>http://www.lyricsmode.com/lyrics/d/dropkick_murphys/revolt.html</loc>
        <lastmod>2007-07-21</lastmod>
        <changefreq>daily</changefreq>
</url>
<url>
        <loc>http://www.lyricsmode.com/lyrics/d/dropkick_murphys/irish_drinking_song_as_far_as_i_know.html</loc>
        <lastmod>2007-07-21</lastmod>
        <changefreq>daily</changefreq>
</url>
<url>
        <loc>http://www.lyricsmode.com/lyrics/d/dropkick_murphys/career_opportunities_live.html</loc>
        <lastmod>2007-07-21</lastmod>
        <changefreq>daily</changefreq>
</url>
<url>
        <loc>http://www.lyricsmode.com/lyrics/d/dropkick_murphys/a_pub_with_no_beer.html</loc>
        <lastmod>2007-07-21</lastmod>
        <changefreq>daily</changefreq>
</url>
<url>
        <loc>http://www.lyricsmode.com/lyrics/d/drop_n_harmony/when_you_love_someone_by_drop_n_harmony.html</loc>
        <lastmod>2007-07-21</lastmod>
        <changefreq>daily</changefreq>
</url>
<url>
        <loc>http://www.lyricsmode.com/lyrics/d/drop_n_harmony/when_you_love_someone.html</loc>
        <lastmod>2007-07-21</lastmod>
        <changefreq>daily</changefreq>
</url>
</urlset>
"""


def get_lyric_urls(document):
    dom = xml.dom.minidom.parseString(document)
    return handle_sitemap_DOM(dom)

def handle_sitemap_DOM(dom):
    urls     = map(lambda node: node.childNodes[0].data, dom.getElementsByTagName("loc"))
    lastmods = map(lambda node: date.strptime(node.childNodes[0].data, '%Y-%m-%d'),
                   dom.getElementsByTagName("lastmod"))
    if len(urls) != len(lastmods):
        raise RuntimeError("Number of URLs and last modified times does not match. Got %d and %d respectively" %\
                           (len(urls), len(lastmods)))
    return zip(urls, lastmods)


if __name__ == "__main__":
    print str(get_lyric_urls(testdoc))
