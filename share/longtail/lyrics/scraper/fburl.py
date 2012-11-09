from httplib import HTTPConnection
from urllib import urlencode
import simplejson as json
import sqlite3
import time
import sys

sconn = sqlite3.connect('./lyrics.sqlite3')
hconn = HTTPConnection('api.facebook.com', 80)

c = sconn.cursor()

def fetch_url_metadata(url):
  query = "select total_count, comment_count, like_count, share_count, click_count from link_stat where url='%s'" % url

  try:
    path = '/method/fql.query?' + urlencode({
      "query": query, 
      "format": "json"
    })
    # print "path:", path
    hconn.request('GET', path, headers={
      "User-Agent": "Wget/1.10"
    })

    response = hconn.getresponse()
    return json.loads(response.read())
  except Exception, ex:
    print "Caught Exception: " + str(ex)
    # hconn.connect()
    sys.exit(1)
    return None



def process_chunk():
  num_processed = 0
  c.execute("""SELECT url from URL_popularity WHERE done=0 LIMIT 3000""")
  all = c.fetchall()

  for row in all:
    # print row[0]
    metadata = fetch_url_metadata(row[0])

    if not metadata:
      continue

    print "URL: %s" % row[0]
    print metadata
    metadata = metadata[0]
    metadata['url'] = row[0]

    c.execute("""UPDATE URL_popularity SET total_count=:total_count, 
                 comment_count=:comment_count, like_count=:like_count, 
		 share_count=:share_count, done=1 WHERE
		 url=:url""", metadata)

    sconn.commit()
    time.sleep(0.6)

  return num_processed



while process_chunk() > 0:
  pass
