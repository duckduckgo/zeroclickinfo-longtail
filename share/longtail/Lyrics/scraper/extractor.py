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


from lyricsmode import LyricsExtractor
from lyricsmode import file_name_matcher as matcher
# from file_writer import LyricWriter
from sqlite_writer import LyricWriter
import sys
import logging
from datetime import datetime
from os import path


# le = LyricsExtractor(LyricWriter(sys.stdout))
le = None



def path_walker(basedir, dirname, fname):
    # print "path_walker:",basedir, dirname, fname
    for f in fname:
        try:
            p = path.sep.join([dirname, f])
            p = "/".join(p.split(path.sep))
            if matcher(p):
                le(p, open(p).read())
        except Exception, e:
            logging.error("Caught exception: " + str(e))


def parse_arguments():
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option("-d", "--sqlite", dest="sqlite3_path",
                      action="store", default="lyricsmode.sqlite3",
                      help="Path to (new) sqlite3 db file", metavar="PATH")
    parser.add_option("-s", "--src", dest="html_path",
                      action="store", default="",
                      help="Path to HTML files to extract lyrics from", metavar="PATH")
    parser.add_option("-l", "--logfile", dest="logfile_name",
                      action="store", default="lyricsmode.log",
                      help="The name of the log file", metavar="FILE")


    (options, args) = parser.parse_args()
    options.html_path = options.html_path.strip()
    options.sqlite3_path = options.sqlite3_path.strip()
    options.logfile_name = options.logfile_name.strip()
    return options


def run_extractor(html_path, sqlite3_path):
    global le
    le = LyricsExtractor(LyricWriter(sqlite3_path))
    path.walk(html_path, path_walker, None)


def main(argv):
    options = parse_arguments()


    if len(options.html_path) == 0 or not path.exists(options.html_path):
        print "Please supply a valid base path for the lyrics folder"
        return 1

    if len(options.sqlite3_path) == 0:
        print "Please enter a non-empty path to the SQLITE3 db"
        return 1

    logging.basicConfig(filename=options.logfile_name, level=logging.DEBUG)
    prefix_str = "Extractor Started at: " + str(datetime.now())
    logging.info("\n\n" + prefix_str + "\n")
    logging.info(("-" * len(prefix_str)) + "\n\n")

    run_extractor(options.html_path, options.sqlite3_path)
    return 0



if __name__ == "__main__":
    sys.exit(main(sys.argv))

