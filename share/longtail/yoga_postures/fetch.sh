#!/bin/bash
mkdir -p download
cd download

AYI=http://www.ashtangayoga.info/practice
#surya-namaskara-a-sun-salutation \
#         surya-namaskara-b-sun-salutation-b \
#         basic-sequence-fundamental-positions \
#         the-finishing-sequence \
#         primary-series-yoga-chikitsa \
#         intermediate-series-nadi-shodhana \
#         advanced-a-series-sthira-bhaga;
for i in primary-series-yoga-chikitsa; 
do
	#wget -r --accept-regex $AYI/$i/item/[^/]+asana[^/]*/index.html $AYI/$i/
	wget -r --accept-regex $AYI/$i/item/*/*/* $AYI/$i/
done

#wget -O download/yoga_asana.json --no-check-certificate 'https://yoga.com/api/content/feed/?format=json&type=pose&offset=0&limit=500'
