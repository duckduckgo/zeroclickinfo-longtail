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


import sitemap_parser as sp
import sys, re, os, logging
from os import path
from httplib import HTTPConnection as HttpClient
import urllib
import sqlite3
import subprocess
import time


"""
Set the variable below to ("host", port) if you want to use
that as the HTTP proxy. Else, set it to the empty tuple: ()
"""
# use_proxy = ("cae2", 4444)
use_proxy = ()

def makedirs(p):
    if not path.exists(p):
        os.makedirs(p)


def get_nonempty_url_parts(url):
    return filter(lambda x: len(x.strip()) > 0, url.split("/"))


def parse_arguments():
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option("-o", "--old", dest="old_sqlite3_path",
                      action="store", default="",
                      help="Path to existing sqlite3 db file (if it exists)", metavar="PATH")
    parser.add_option("-n", "--new", dest="new_sqlite3_path",
                      action="store", default="new.sqlite3",
                      help="Path to new sqlite3 db file (default: new.sqlite3)", metavar="PATH")
    parser.add_option("-f", "--html", dest="html_path",
                      action="store", default="",
                      help="Path to directory where downloaded files should be saved", metavar="PATH")
    parser.add_option("-l", "--logfile", dest="logfile_name",
                      action="store", default="incremental.log",
                      help="The name of the log file", metavar="FILE")
    parser.add_option("-p", "--proxy", dest="use_proxy",
                      action="store", default="",
                      help="The HTTP proxy to use. Format: host:port (eg: proxy1:8080)")
    parser.add_option("-s", "--sleep", dest="sleep_ms",
                      action="store", default="0",
                      help="Number of ms to sleep between successive web requests (default: 0)")



    (options, args) = parser.parse_args()
    options.html_path = options.html_path.strip()
    options.old_sqlite3_path = options.old_sqlite3_path.strip()
    options.new_sqlite3_path = options.new_sqlite3_path.strip()
    options.logfile_name = options.logfile_name.strip()
    options.use_proxy = options.use_proxy.strip()
    options.sleep_ms = int(options.sleep_ms)
    return options


class WrappedResponse(object):
    """
    The WrappedResponse object is used to wrap a socket as well as
    file-system file object into a basic minimum response type so that
    clients need not worry about where the response came from
    """
    def __init__(self, handle, status=None):
        self.handle = handle
        if handle and hasattr(handle, "status"):
            self.status = handle.status
        else:
            self.status = status

    def read(self):
        if hasattr(self, "cached_read"):
            return self.cached_read
        self.cached_read = self.handle.read()
        return self.read()

    def close(self):
        if self.handle:
            self.handle.close()
            self.handle = None



def make_HTTP_request(host, port, method, url, params, headers = { }):
    """
    HTTP connection helper.

    Note: The connection is NOT closed at the end of the request since
    the response.read() method may want an open socket. The WrappedResponse
    object has a close which closes the underlying connection
    """
    try:
        if len(use_proxy) > 0:
            # print "UP: %s" % str(use_proxy)
            conn = HttpClient(*use_proxy)
            url = "http://%s:%d%s" % (host, port, url)
        else:
            conn = HttpClient(host, port)

        headers["Host"] = "%s:%d" % (host, port)
        params = urllib.urlencode(params)

        if method.lower() == "get":
            if len(params) > 0:
                url += ("?" + params)
            params = ""

        # print host, port, method, url, params, headers
        conn.request(method, url, params, headers)
        return conn.getresponse()
    except Exception, ex:
        logging.error("EXCEPTION (%s) downloading url: %s" % (str(ex), url))
        wr = WrappedResponse(None, 404)
        return wr


def fetch_all_song_urls(url_checker, sitemap_fetcher):
    # return sp.get_lyric_urls(sp.testdoc)

    headers = { #"Accept-Encoding": "compress, gzip",
                "User-Agent": "Mozilla/4.0",
    }
    sitemap_root = ("www.lyricsmode.com", 80, "GET", "/sitemap.xml", "", headers)
    response = make_HTTP_request(*sitemap_root)

    logging.info("Status for GET (%s): %d" % (sitemap_root[3], response.status))
    if response.status != 200:
        raise RuntimeError("Error downloading the sitemap root. Got status: %s" % str(response.status))

    sitemap_xml = response.read()
    # logging.info("Sitemap XML:\n" + sitemap_xml)
    url_sitemaps = sp.get_lyric_urls(sitemap_xml)

    all_song_urls = [ ]
    sm_pat = re.compile(r"http://(www.lyricsmode.com)(/sitemap_[\S]+.xml)")

    for url in url_sitemaps: # [5:]:
        logging.info("Processing URL: %s" % url[0])
        m = sm_pat.match(url[0])
        if not m:
            logging.error("Error matching sitemap URL: %s" % url[0])
            continue

        response = sitemap_fetcher.fetch(host=m.group(1),
                                         resource=m.group(2),
                                         headers=headers)

        if response.status != 200:
            logging.error("Error downloading URL: %s" % url[0])
            continue

        xmlDoc = response.read()
        response.close()
        # xmlDoc = open("sitemap_part5.xml", "r").read()
        # print "Length of xmlDoc: %d" % len(xmlDoc)

        # print xmlDoc
        urls = filter(lambda x: url_checker(x[0]), sp.get_lyric_urls(xmlDoc))
        # urls = sp.get_lyric_urls(xmlDoc)
        # print "Length if URLs: %d" % len(urls)
        all_song_urls.extend(urls)

        # Caution: Uncocomment this to process all the sitemap files
        # return all_song_urls

    return all_song_urls



class SitemapFetcher(object):
    """
    Simple Fetcher for the sitemap_part*.xml files
    """
    def __init__(self, cache_dir):
        self.cache_dir = path.sep.join( [ cache_dir, ".sitemap_cache" ] )
        makedirs(self.cache_dir)
        self.smpat = re.compile(r"sitemap_part[0-9]+.xml")


    def fetch(self, host, resource, query = "",
              port = 80, method = "GET",
              headers = { }):
        # All the caching logic goes here
        logging.debug("Trying to fetch: %s:%d%s" % (host, port, resource))
        m = self.smpat.search(resource)
        cached_file_path = None

        # If the resource matches something that we are capable of cache
        # then go ahead
        if m:
            cached_file_path = path.sep.join( [ self.cache_dir, m.group(0) ] )

        # The file containing the cached data MUST exist and be non-empty
        if cached_file_path and path.exists(cached_file_path) and path.getsize(cached_file_path) > 0:
            fh = open(cached_file_path, "r")
            wr = WrappedResponse(fh, 200)
            logging.debug("Returning cached file for: %s:%d%s" % (host, port, resource))
            return wr

        logging.debug("Fetching (%s:%d%s) from the web" % (host, port, resource))
        request = (host, port, method, resource, query, headers)
        response = make_HTTP_request(*request)
        wr = WrappedResponse(response)

        # We arrived here because we couldn't locate a valid cache file for
        # the requested resource. Try to cache it if we can
        if cached_file_path:
            sitemap_contents = wr.read()
            fh = open(cached_file_path, "w")
            fh.write(sitemap_contents)
            fh.close()

        return wr



class LyricsUpdater(object):
    def __init__(self, master_db, new_db, staging_directory, request_headers):
        self.master_db = master_db
        self.new_db = new_db
        self.staging_directory = staging_directory
        self.headers = request_headers
        self.prepared_master = False
        self.url_pat = re.compile(r"(www.lyricsmode.com)(/[\S\s]+\.html)")

        self.master_conn = None
        if path.exists(self.master_db):
            self.master_conn = sqlite3.connect(self.master_db)
            self.master_conn.isolation_level = None

        c = self.master_conn.cursor()
        # Please remember to keep this in sync with the other CREATE TABLE statement
        c.execute("""CREATE TABLE IF NOT EXISTS LYRICS(title VARCHAR(300) NOT NULL,
            artist VARCHAR(200) NOT NULL,
            album VARCHAR(200) NOT NULL,
            url VARCHAR(2000) NOT NULL,
            lyric_text TEXT NOT NULL)""")



    def prepare_master_for_querying(self):
        if not self.master_conn:
            return

        c = self.master_conn.cursor()
        q = "CREATE UNIQUE INDEX IF NOT EXISTS uniq_urls ON LYRICS (url)"
        c.execure(q)
        self.master_conn.commit()


    def is_lyrics_present_for_URL(self, url):
        logging.debug("is_lyrics_present_for_URL(%s)" % url)
        if not self.prepare_master_for_querying:
            self.prepare_master_for_querying()
            self.prepared_master = True

        c = self.master_conn.cursor()
        q = r"SELECT COUNT(*) FROM LYRICS WHERE url = ?"
        res = c.execute(q, (url, ))
        if res.fetchone()[0] > 0:
            logging.debug("TRUE1")
            return True
        else:
            m = self.url_pat.search(url)
            staging_file = path.sep.join([ self.staging_directory, m.group(1) ] + \
                                         get_nonempty_url_parts(m.group(2)))
            # print "Staging file: " + staging_file
            if path.exists(staging_file) and path.getsize(staging_file) > 0:
                logging.debug("TRUE2")
                return True
            else:
                logging.debug("FALSE")
                return False


    def is_url_valid(self, url):
        return (self.url_pat.search(url) is not None)

    def download_and_save_URL(self, url):
        m = self.url_pat.search(url)
        if not m:
            # ERROR: did not match!!
            logging.warn("URL (%s) did not match pattern" % (url))
            return

        request = (m.group(1), 80, "GET", m.group(2), "", self.headers)
        response  = make_HTTP_request(*request)
        if response.status != 200:
            # ERROR
            logging.error("Error fetching lyrics for URL: %s" % url)
            return

        components = [self.staging_directory, m.group(1)] + \
            get_nonempty_url_parts(m.group(2))
        dir_path  = path.sep.join(components[:-1])
        file_path = path.sep.join(components)

        makedirs(dir_path)

        fh = None
        try:
            document = response.read()
            fh = open(file_path, "w")
            fh.write(document)
        except Exception, ex:
            logging.debug("ERROR (%s) reading response for URL: %s" % (str(ex), m.group(2)))

        if fh:
            fh.close()




    def update_new_db_with_new_files(self):
        args = ["python", "extractor.py", "-s", self.staging_directory, "-d", self.new_db]
        logging.info("Command for starting the extractor: " + str(args))
        extractor = subprocess.Popen(args)
        extractor.wait()



def main(argc, argv):
    global use_proxy
    options = parse_arguments()
    if len(options.html_path) == 0 or not path.exists(options.html_path):
        sys.stderr.write("Please specify a valid path to save the downloaded HTML files")
        return 1

    if len(options.new_sqlite3_path) == 0:
        sys.stderr.write("Please specify a valid path to the new SQLITE3 database file")
        return 1

    if len(options.use_proxy) > 0:
        use_proxy = options.use_proxy.split(":")
        if len(use_proxy) != 2:
            sys.stderr.write("Please specify a valid host:port pair for the HTTP proxy")
            return 1

        print "Using Proxy: %s" % options.use_proxy
        use_proxy[1] = int(use_proxy[1])

    logging.basicConfig(filename=options.logfile_name, level=logging.DEBUG)

    lu = LyricsUpdater(options.old_sqlite3_path,
                       options.new_sqlite3_path,
                       options.html_path, { })

    sf = SitemapFetcher(options.html_path)

    def should_URL_be_downloaded(url):
        return lu.is_url_valid(url) and not lu.is_lyrics_present_for_URL(url)


    all_song_urls = fetch_all_song_urls(should_URL_be_downloaded, sf)
    logging.info("Number of URLs fetched: %d" % len(all_song_urls))

    for url in all_song_urls:
        logging.info("Downloading and saving URL: %s" % url[0])
        lu.download_and_save_URL(url[0])
        if options.sleep_ms:
            time.sleep(options.sleep_ms / 1000.0)

    # Reduce the memory pressure a bit ;)
    all_song_urls = [ ]

    lu.update_new_db_with_new_files()



if __name__ == "__main__":
    sys.exit(main(len(sys.argv), sys.argv))
