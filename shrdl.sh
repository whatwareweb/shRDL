#!/bin/sh
case $1 in
    http://*|https://*) set "${1%/}" && repodomain=${1#*//} ;;
    *) printf "Usage: %s <repo url> [--single-threaded]\n" "${0##*/}" ; exit 0 ;;
esac

for dep in curl gzip bzip2; do
    if ! command -v $dep > /dev/null; then
        printf "%s not found, please install %s\n" "$dep" "$dep"
        exit 1
    fi
done

if [ "$(curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -w '%{http_code}' -L -s -o /dev/null "$1/Packages.bz2")" -eq 200 ]; then
    archive=bz2
elif [ "$(curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -w '%{http_code}' -L -s -o /dev/null "$1/Packages.gz")" -eq 200 ]; then
    archive=gz
else
    printf "Couldn't find a Packages file. Exiting\n"
    exit 1
fi

printf "Downloading Packages.%s\n" "$archive"

[ ! -d "$repodomain" ] && mkdir -p "$repodomain"
cd "$repodomain" || exit 1
rm -f urllist.txt

curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -L -# -O "$1/Packages.$archive"

if [ "$archive" = "bz2" ]; then
    bzip2 -d ./Packages.bz2
elif [ "$archive" = "gz" ]; then
    gzip -d ./Packages.gz
fi

while read -r line; do
    case $line in
        Filename:*)
            deburl=${line#Filename: }
            case $deburl in
                ./*) deburl=${deburl#./} ;;
            esac
            printf "%s/%s\n" "$1" "$deburl" >> urllist.txt
        ;;
    esac
done < ./Packages

[ ! -d debs ] && mkdir debs
cd debs || exit 1

case "$*" in
    *--single-threaded*) noparallel=1 ;;
esac

command -v pgrep > /dev/null || noparallel=1

printf "Downloading debs\n"
if [ "$noparallel" = "1" ]; then
    while read -r i; do
        curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -g -L -s -O "$i"
    done < ../urllist.txt
else
    [ -z "$JOBS" ] && JOBS=16
    while read -r i; do
        while [ "$(pgrep -c curl)" -ge "$JOBS" ]; do
            sleep 1
        done
        curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "User-Agent: Telesphoreo APT-HTTP/1.0.999" -g -L -s -O "$i" &
    done < ../urllist.txt
    wait
fi
printf "Done!\n"
