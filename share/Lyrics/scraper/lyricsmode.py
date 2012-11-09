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


from BeautifulSoup import BeautifulSoup as bs
import re
import logging
from os import path

def strip_trailing_string(s, suffix, ignore_case = False):
    origs = s
    if ignore_case:
        s = s.lower()
        suffix = suffix.lower()
    ls = len(s)
    lsuffix = len(suffix)
    fpos = s.rfind(suffix)
    if fpos != -1 and fpos + lsuffix == ls:
        s = origs[:-lsuffix]
    return s


class LyricsExtractor(object):
    """
    Custom extractor to parse lyricmode.com .html files
    """
    def __init__(self, writer):
        self.camopat = re.compile(r"&#([0-9]+)")
        self.digpat  = re.compile(r"^[0-9]+$")
        self.writer = writer
        self.url_pat = re.compile(r"(www.lyricsmode.com/[\S\s]+\.html)")

    def __call__(self, ppath, page):
        """
        ppath: The path at which the page resides on the file system.
               This should contain the DOMAIN NAME of the site.
        page: The actual page contents as a string.
        """
        logging.debug("PAGE PATH: " + ppath.lower())

        def to_ascii(ordinal):
            """
            Some extended ascii characters mentioned here: http://ascii-code.com/
            are not printable or enterable via the keyboard in a normal
            circumstance. We replace them by their more well known counterparts
            """
            try:
                return {
                    145: 39,
                    146: 39,
                    147: 34,
                    148: 34 }[ordinal]
            except:
                return ordinal

        # If the file name is "index.html" then skip it
        if ppath.lower().rfind("index.html") != -1:
            return

        upath = ppath
        if path.sep != '/':
            upath = upath.replace(path.sep, "/")

        soup = bs(page)
        lyric_tag = soup.find(attrs = {"id": "songlyrics_h"} )
        if not lyric_tag:
            raise RuntimeError("Could not find lyric text for the song at path: " + ppath)
            # Skip if coulen't find the lyrics
            return

        lyric_tag = lyric_tag.contents

        # Replace all <br /> tags with an empty string
        lyric_text = u"".join(map(lambda x: "" if str(x)=="<br />" else x, lyric_tag))
        camoflaged = self.camopat.findall(lyric_text)

        # Check if characters have been entered in &#NUMBER; encoded form
        if len(camoflaged) >= 8:
            camoflaged = lyric_text.replace("\n", "&#10;")
            # If so, then decode them
            evident = map(lambda x: chr(to_ascii(int(x))), self.camopat.findall(camoflaged))
            lyric_text = u"".join(evident)

        # Strip lyric text of leading and trailing whitespaces
        lyric_text = lyric_text.strip()

        # Fetch the song's title and artist
        song_meta = map(lambda x: x.strip(), soup.find("title").contents[0].split("-"))

        # print "SONG META-1: " + str(song_meta)

        if len(song_meta) > 2:
            song_meta[0] = "-".join(song_meta[:-1])
            song_meta[1] = song_meta[-1]

        # print "SONG META-2: " + str(song_meta)

        artist = song_meta[0].strip()
        title = song_meta[1].strip()

        if artist.lower().find("lyrics") != -1:
            # The order seems to be mismatched. Swap the two.
            # Lyricsmode likes to do funny things like this
            artist, title = title, artist

        title = strip_trailing_string(title, "lyrics", True).strip()

        # Exit if artist is only digits (this is a questionable move)
        if self.digpat.match(artist):
            raise RuntimeError("Artist name (%s) has only digits" % artist)

        # Exit if len(artist) <= 1 (this is a questionable move)
        if len(artist) <= 1:
            raise RuntimeError("Artist name (%s) is less than 2 characters" % artist)

        # Fetch the URL of the song (this is the same as the path name
        # of the file if you use wget to crawl the site)
        url = self.url_pat.findall(upath)
        if len(url) != 1:
            # Couldn't get the song URL
            raise RuntimeError("Could not get the URL for the song: " + title)
        url = "http://" + url[0]

        # TODO: Get the Album info (if it exists)
        song_meta = soup.find(attrs = {"class": "s_field"} ).findAll(attrs = {"class": "ssm"} )
        lsm = len(song_meta)
        album = ""
        if lsm >= 2:
            _album = "".join(song_meta[-2].contents).strip()
            _album = strip_trailing_string(_album, "lyrics", True).strip()
            # print "_album: " + str(_album) + " " + str(len(_album))
            if _album.lower() != artist.lower():
                album = _album

        # print (title, artist, url)
        self.writer.write_lyric(title, artist, album, url, lyric_text)



from common import FilePathMatcher as MatcherBase
file_name_matcher = MatcherBase(["[\s\S]*/lyrics/[a-z]/[^/]+/[^\.]+.html"])
