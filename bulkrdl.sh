#!/bin/sh
if ! [ -f shrdl.sh ]; then
    printf "shrdl.sh not found.\n"
    printf "make sure to run this in the same directory as shrdl.sh.\n"
    exit 1
elif ! [ -f repolist.txt ]; then
    printf "repolist.txt file not found.\n"
    printf "Create a file in the current working directory called repolist.txt containing the URLs for repos you want to download"
    exit 1
fi

while read -r line; do
    printf "Downloading repo: %s\n" "$line"
    ./shrdl.sh "$line"
done < ./repolist.txt
