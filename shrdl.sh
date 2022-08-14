#!/bin/sh
case $1 in
    -v|--version)
        printf "shRDL 2.0\n"
        exit 0
    ;;

    http://*|https://*)
        set "${1%/}"
        repodomain=${1#*//}
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

for cmd in curl gunzip bunzip2 sed; do
    if ! command -v $cmd > /dev/null; then
        printf "%s not found, please install %s\n" "$cmd" "$cmd"
        exit 1
    fi
done

gzcode=$(curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" --write-out '%{http_code}' -L --silent --output /dev/null "$1/Packages.gz")
bz2code=$(curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" --write-out '%{http_code}' -L --silent --output /dev/null "$1/Packages.bz2")

if [ "$gzcode" -eq 200 ]; then
    printf "Downloading Packages.gz\n"
    archive=gz
elif [ "$bz2code" -eq 200 ]; then
    printf "Downloading Packages.bz2\n"
    archive=bz2
else
    printf "Couldn't find a Packages file. Exiting\n"
    exit 1
fi

[ ! -d "$repodomain" ] && mkdir -p "$repodomain"
cd "$repodomain" || exit 1
rm -f urllist.txt

curl -# -O "$1/Packages.$archive"

if [ "$archive" = "gz" ]; then
    gunzip ./Packages.gz
elif [ "$archive" = "bz2" ]; then
    bunzip2 ./Packages.bz2
fi

while read -r line; do
    case $line in
        Filename:*)
            deburl=${line#Filename: }
            case $deburl in
                ./*)
                    deburl=${deburl#./}
                ;;
            esac
            printf "%s/%s\n" "$1" "$deburl" >> urllist.txt
        ;;
    esac
done < ./Packages

[ ! -d debs ] && mkdir debs
cd debs || exit 1

while read -r i; do
    printf "Downloading %s\n" "${i##*/}"
    curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -g -L -# -O "$i"
done < ../urllist.txt
cd ../..

printf "Done!\n"
