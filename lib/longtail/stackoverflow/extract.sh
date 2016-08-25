#!/usr/bin/env sh
# run from directory containing stackoverflow source archives
# ensure that the main stackoverflow archive is combined into 1 .7z file before running

ls *.7z | while read LINE; do
        file_name=$(echo $LINE | sed 's/.7z//g')
        /usr/bin/7z e $LINE -o$file_name
done
