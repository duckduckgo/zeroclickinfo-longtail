1. Install Pre-reqs
 ```
 sudo apt-get -y install rtorrent
 apt-get -y install p7zip
 apt-get -y install moreutils
 ```

2. Create storage directory
 - Note: The mount where 7z files are extracted and processed should be very big, e.g. +75GB
 ```
 mkdir download && cd download
 ```

3. Download archive torrent from https://archive.org/details/stackexchange
 ```
 rtorrent https://archive.org/download/stackexchange/stackexchange_archive.torrent
 cd stackexchange
 rm meta*.7z stackoverflow.com-Badges.7z stackoverflow.com-Comments.7z stackoverflow.com-Comments.7z stackoverflow.com-Tags.7z stackoverflow.com-Votes.7z
 ```

4. Clone ZeroClickInfo Longtail Repo
  ```
  git clone git@github.com:duckduckgo/zeroclickinfo-longtail.git
  zeroclickinfo-longtail/lib/longtail/stackoverflow/extract.sh
  zeroclickinfo-longtail/lib/longtail/stackoverflow/posts.pl -d .
  ```

5. Bundle output files and upload to S3 (This is unnecessary if you're developing/testing)
  ```
  bzip2 -v pre-process*.txt
  upload via s3cmd
  ```
