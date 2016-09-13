1. Clone ZeroClickInfo Longtail Repo
 ```
 git clone git@github.com:duckduckgo/zeroclickinfo-longtail.git
 ```

2. Install Pre-reqs
 ```
 apt-get -y install p7zip
 apt-get -y install moreutils
 ```

3. Create storage directory
 - Note: The mount where 7z files are extracted and processed should be very big, e.g. +75GB
 ```
 mkdir download && cd download
 ```

4. Mirror 7z files from https://archive.org/details/stackexchange
 ```
 mirror_stackexchange.pl -d download -v
 ```

5. Generate output file
 ```
 zeroclickinfo-longtail/lib/longtail/stackoverflow/extract.sh
 zeroclickinfo-longtail/lib/longtail/stackoverflow/posts.pl -d .
 ```

6. Bundle output files and upload to S3 (This is unnecessary if you're developing/testing)
 ```
 bzip2 -v pre-process*.txt
 upload via s3cmd
 ```
