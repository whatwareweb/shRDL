#!/bin/bash

# cydia repo downloader
# dependencies: gnu stuff, bzip2, curl, wget
# only for bash

repoURL="$1"

# check for correct syntax
if [[ "$repoURL" == '-h' ]] || [[ "$repoURL" == '--help' ]]; then
  echo "saves deb package urls of cydia repos"
  echo "Usage: ./bashrdl.sh [http(s)://apt.cydiarepo.url] [y/n] [y/n] [y/n]"
  echo "You must put the http:// or https:// part of the URL!"
  echo "1st y/n argument: whether or not to delete Packages file"
  echo "2nd y/n argument: whether or not to delete deburllist.txt file"
  echo "3rd y/n argument: whether or not to auto download all debs"
  echo "written by whatware (and hopefully other contributors) with barely any"
  echo "care or attention to detail and lots of stolen code from stackoverflow"
  exit 0
fi
if [[ "$repoURL" == '' ]] || [[ ! $repoURL =~ .*"http://".* ]] && [[ ! $repoURL =~ .*"https://".* ]]; then
  echo "please enter repo url as an argument"
  echo "Usage: ./bashrdl.sh [http(s)://apt.cydiarepo.url] [-y]"
  echo "You must put the http:// or https:// part!"
  echo "use -h for help"
  exit 1
fi

# check for dependencies
if ! command -v curl &> /dev/null; then
  echo "curl not found, please install curl"
  exit 1
fi
if ! command -v wget &> /dev/null; then
  echo "wget not found, please install wget"
  exit 1
fi
if ! command -v gunzip &> /dev/null; then
  echo "gunzip not found, please install gunzip"
  exit 1
fi
if ! command -v bunzip2 &> /dev/null; then
  echo "bunzip2 not found, please install bunzip2"
  exit 1
fi

# check for existing packages file, otherwise it will be overwritten
if [ -f ./Packages.gz ] || [ -f ./Packages.bz2 ]; then
  echo "The packages archive already exists."
  echo "This could be caused by the script being interrupted/erroring last time."
  echo "Do you want to continue and overwrite the file? [y/n]"
  read overwrite
fi
if [ -f ./Packages ]; then
  echo "The packages file already exists."
  echo "This could be caused by the script being interrupted/erroring last time."
  echo "Do you want to continue and overwrite the file? [y/n]"
  read overwrite
fi
if [ -f ./Packages.gz ] || [ -f ./Packages.bz2 ] || [ -f ./Packages ] && [[ "$overwrite" == "y" ]]; then
  echo "Overwriting Packages file."
  rm ./Packages &> /dev/null
  rm ./Packages.gz &> /dev/null
  rm ./Packages.bz2 &> /dev/null
elif [ -f ./Packages.gz ] || [ -f ./Packages.bz2 ] || [ -f ./Packages ]; then
  echo "Packages file found and not being overwritten. Exiting."
  exit 0
fi

# check for extra slash after repo name and remove
if [[ "$repoURL" == */ ]]; then
  repoURL=$(echo ${repoURL::length-1})
fi

# debug
echo "$repoURL"

# check repo for correct packages filename
responsegz=$(curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "Telesphoreo APT-HTTP/1.0.999" --write-out '%{http_code}' -L --silent --output /dev/null "$repoURL""/Packages.gz" )
responsebz2=$(curl -H "X-Machine: iPod4,1" -H "X-Unique-ID: 0000000000000000000000000000000000000000" -H "X-Firmware: 6.1" -H "Telesphoreo APT-HTTP/1.0.999" --write-out '%{http_code}' -L --silent --output /dev/null "$repoURL""/Packages.bz2" )

# debug
echo "$responsegz"
echo "$responsebz2"

# set archive type
if [[ "$responsegz" == "200" ]]; then
  echo "Success finding packages file"
  archive=gz
fi
if [[ "$responsebz2" == "200" ]]; then
  echo "Success finding packages file"
  archive=bz2
fi

# check for errors
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

# debug
echo "Using archive type ""$archive"

# download archive
curl -O -L "$repoURL""/Packages.""$archive"

# extract based on archive type
if [[ "$archive" == "gz" ]]; then
  gunzip ./Packages.gz
fi
if [[ "$archive" == "bz2" ]]; then
  bunzip2 ./Packages.bz2
fi

# isolate domain from url
if [[ "$repoURL" == "http://"* ]]; then
  repoDomain=$(echo "$repoURL" | sed 's\http://\\')
elif [[ "$repoURL" == https://* ]]; then
  repoDomain=$(echo "$repoURL" | sed 's\https://\\')
fi

# debug
echo "$repoDomain"

# save all deb urls to file
file=./Packages
while read -r line; do
  if [[ "$line" == "Filename: "* ]]; then # get all the lines that start with 'Filename: '
    debURL=$(echo "$line" | sed 's\Filename: \\') # remove leading string to get deb url
    if [[ "$debURL" == "./"* ]]; then # check if deb url starts with ./ instead of domain
      remdotslash=$(echo "$debURL" | sed 's\./\\') # remove leading ./
      # save now independent url
      echo "$repoURL""/""$remdotslash" >> deburllist.txt
      echo "$repoURL""/""$remdotslash"" saved"
    elif [[ "$debURL" != *"$repoDomain"* ]]; then # check if deb url doesnt have domain
      echo "$repoURL""/""$debURL" >> deburllist.txt
      echo "$repoURL""/""$debURL"" saved"
    else
      # otherwise just save original url
      echo "$debURL" >> deburllist.txt
      echo "$debURL"" saved"
    fi
  fi
done <$file

# file deletion / auto downloading
deletePackages="$2"
deleteURLlist="$3"
downloadDebs="$4"

echo

if [[ "$deletePackages" != "y" ]] && [[ "$deletePackages" != "n" ]]; then
  echo "Delete Packages file? This file has dependencies, might be useful for archival."
  echo "[y/n]"
  read deletePackages
fi

if [[ "$deleteURLlist" != "y" ]] && [[ "$deleteURLlist" != "n" ]]; then
  echo "Delete deburllist.txt file? This file has tweak URLs, might be useful for archival."
  echo "[y/n]"
  read deleteURLlist
fi

if [[ "$downloadDebs" != "y" ]] && [[ "$downloadDebs" != "n" ]]; then
  echo "Download all deb files into ./debs?"
  echo "[y/n]"
  read downloadDebs
fi
if [[ $downloadDebs == y ]]; then
  wget -P ./debs/ -i ./deburllist.txt
fi

echo "Cleaning up..."
if [[ $deleteURLlist == y ]]; then
  rm ./deburllist.txt &> /dev/null
fi
if [[ $deletePackages == y ]]; then
  rm ./Packages &> /dev/null
fi

echo Done!
