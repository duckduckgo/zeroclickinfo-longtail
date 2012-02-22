# Quora Crawler

### Simple Usage

Run
```
$ node crawl.js
```
and sit back and relax

### Make the Crawl Better

Add more URLs to crawl.js::seedLinks to ensure that BFS works well

### Notes:

1. We make **1 req/sec** (amortized)
2. Peak is **20 req/sec**
3. Data is saved in **quora.sqlite3**
4. All downloaded and parsed files are stored in **archive.tar** to reduce the load on the file system

### TODO

1. Update DB schema
2. Save answer text from pages
