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
    echo "curl not found, please install curl"
    exit 1
elif ! command -v gunzip > /dev/null; then
    echo "gunzip not found, please install gunzip"
    exit 1
elif ! command -v bunzip2 > /dev/null; then
    echo "bunzip2 not found, please install bunzip2"
    exit 1
fi

rm -f Packages.gz
rm -f Packages.bz2
rm -f Packages
rm -f urllist.txt

if [[ "$1" == */ ]]; then
    set "${1::length-1}"
fi

responsegz=$(curl --write-out '%{http_code}' -L --silent --output /dev/null "$1""/Packages.gz" )
responsebz2=$(curl --write-out '%{http_code}' -L --silent --output /dev/null "$1""/Packages.bz2" )

if [[ "$responsegz" == "200" ]]; then
    printf "Downloading Packages.gz\n"
    archive=gz
elif [[ "$responsebz2" == "200" ]]; then
    printf "Downloading Packages.bz2\n"
    archive=bz2
fi

if [[ "$responsegz" != "200" ]] && [[ "$responsebz2" != "200" ]]; then
    if [[ "$responsegz" == "404" ]] && [[ "$responsebz2" == "404" ]]; then
        echo "No Packages file found. Exiting"
        exit 1
    else
        echo "Server returned ""$responsegz"" for Packages.gz and ""$responsebz2"" for Packages.bz2"
        echo "Unknown error, exiting"
        exit 1
    fi
fi

curl -# -O "$1""/Packages.""$archive"

if [[ "$archive" == "gz" ]]; then
    gunzip ./Packages.gz
elif [[ "$archive" == "bz2" ]]; then
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
    curl -# -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -O "$i"
done < ../urllist.txt
cd ..

echo Done!
