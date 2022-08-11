#!/bin/bash
case $1 in
    -v|--version)
        printf "shRDL 2.0\n"
        exit 0
    ;;

    http*)
        true
    ;;

    *)
        cat <<EOF
shRDL - Downloads deb packages from Cydia repositories

Usage:
    shrdl.sh [URL]

    -h, --help              Print this message
    -v, --version           Print version info
EOF
        exit 0
    ;;
esac

if ! command -v curl > /dev/null; then
    printf "curl not found, please install curl\n"
    exit 1
elif ! command -v gunzip > /dev/null; then
    printf "gunzip not found, please install gunzip\n"
    exit 1
elif ! command -v bunzip2 > /dev/null; then
    printf "bunzip2 not found, please install bunzip2\n"
    exit 1
elif ! command -v sed > /dev/null; then
    printf "sed not found, please install sed\n"
    exit 1
fi

rm -f Packages.gz
rm -f Packages.bz2
rm -f Packages
rm -f urllist.txt

case $1 in
    */)
        set "${1::length-1}"
    ;;
esac

gzcode=$(curl --write-out '%{http_code}' -L --silent --output /dev/null "$1""/Packages.gz" )
bz2code=$(curl --write-out '%{http_code}' -L --silent --output /dev/null "$1""/Packages.bz2" )

if [ "$gzcode" -eq 200 ]; then
    printf "Downloading Packages.gz\n"
    archive=gz
elif [ "$bz2code" -eq 200 ]; then
    printf "Downloading Packages.bz2\n"
    archive=bz2
fi

if [ "$gzcode" -ne 200 ] && [ "$bz2code" -ne 200 ]; then
    if [ "$gzcode" -eq 404 ] && [ "$bz2code" -eq 404 ]; then
        printf "No Packages file found. Exiting\n"
        exit 1
    else
        printf "Server returned %s for Packages.gz and %s for Packages.bz2" "$gzcode" "$bz2code"
        printf "Unknown error, exiting\n"
        exit 1
    fi
fi

curl -# -O "$1""/Packages.""$archive"

if [ "$archive" = "gz" ]; then
    gunzip ./Packages.gz
elif [ "$archive" = "bz2" ]; then
    bunzip2 ./Packages.bz2
fi

if [[ "$1" == "http://"* ]]; then
    repoDomain=$(echo "$1" | sed 's\http://\\')
elif [[ "$1" == https://* ]]; then
    repoDomain=$(echo "$1" | sed 's\https://\\')
fi

while read -r line; do
    if [[ "$line" == "Filename: "* ]]; then
        debURL=$(echo "$line" | sed 's\Filename: \\')
        if [[ "$debURL" == "./"* ]]; then
            remdotslash=$(echo "$debURL" | sed 's\./\\')
            echo "$1""/""$remdotslash" >> urllist.txt
        elif [[ "$debURL" != *"$repoDomain"* ]]; then
            echo "$1""/""$debURL" >> urllist.txt
        else
            echo "$debURL" >> urllist.txt
            echo "$debURL"" saved"
        fi
    fi
done < ./Packages

[ ! -d debs ] && mkdir debs; cd debs || exit 1
while read -r i; do
    printf "Downloading %s\n" "${i##*/}"
    curl -# -O "$i"
done < ../urllist.txt
cd ..

printf "Done!\n"
