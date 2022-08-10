#!/bin/bash

# bulk cydia repo downloader
# dependencies: gnu stuff, bzip2, curl, wget, ./bashrdl.sh
# only for bash

bulkDeletePackages="$1"
bulkDeleteURLlist="$2"
bulkDownloadDebs="$3"

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
  echo "saves deb package urls of cydia repos in bulk from repos.txt"
  echo "Usage: ./rdlbulk.sh [y/n] [y/n] [y/n]"
  echo
  echo "./bashrdl.sh must be in the same directory as ./rdlbulk.sh!"
  echo "Lines in repos.txt must follow the url syntax of ./bashrdl.sh"
  echo
  echo "1st y/n argument: whether or not to delete Packages file"
  echo "2nd y/n argument: whether or not to delete deburllist.txt file"
  echo "3rd y/n argument: whether or not to auto download all debs"
  echo
  echo "If arguments are unspecified, you will be prompted to answer"
  echo
  echo "written by whatware (and hopefully other contributors) with barely any"
  echo "care or attention to detail and lots of stolen code from stackoverflow"
  exit 0
fi

# check for repos.txt
if ! [ -f ./repos.txt ]; then
  echo "The repos.txt file does not exist."
  echo "Please create this file with a list of all repos to download."
  echo "If you want to only download 1 repo, please use ./bashrdl.sh."
  echo "Would you like this file to be automatically created? [y/n]"
  read createFile
  if [[ "$createFile" == "y" ]]; then
    touch ./repos.txt
    echo "File created."
  fi
  echo "Exiting"
  exit 1
fi

# check for dependencies
if ! [ -f ./bashrdl.sh ]; then
  echo "./bashrdl.sh not found, please put it in the same directory"
  exit 1
fi
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

# prompts
if [[ "$bulkDeletePackages" != "y" ]] && [[ "$bulkDeletePackages" != "n" ]]; then
  echo "Delete Packages file? This file has dependencies, might be useful for archival."
  echo "[y/n]"
  read bulkDeletePackages
fi

if [[ "$bulkDeleteURLlist" != "y" ]] && [[ "$bulkDeleteURLlist" != "n" ]]; then
  echo "Delete deburllist.txt file? This file has tweak URLs, might be useful for archival."
  echo "[y/n]"
  read bulkDeleteURLlist
fi

if [[ "$bulkDownloadDebs" != "y" ]] && [[ "$bulkDownloadDebs" != "n" ]]; then
  echo "Download all deb files into folders named by repo?"
  echo "[y/n]"
  read bulkDownloadDebs
fi

if ! [[ $bulkDeletePackages == y ]]; then
  if ! [ -f ./packages ]; then
    mkdir ./packages
  fi
fi
if ! [[ $bulkDeleteURLlist == y ]]; then
  if ! [ -f ./urllists  ]; then
    mkdir ./urllists
  fi
fi

file=./repos.txt
while read -r line; do
  # call bashrdl with arguments
  ./bashrdl.sh $line $bulkDeletePackages $bulkDeleteURLlist $bulkDownloadDebs

  # isolate domain from url
  repoURL=$line
  if [[ "$repoURL" == "http://"* ]]; then
    repoDomain=$(echo "$repoURL" | sed 's\http://\\')
  elif [[ "$repoURL" == "https://"* ]]; then
    repoDomain=$(echo "$repoURL" | sed 's\https://\\')
  fi
  repoDomain=$(echo "$repoDomain" | cut -f1 -d"/")

  # check arguments for files to rename/move
  if ! [[ $bulkDeletePackages == y ]]; then
    mv ./Packages "./packages/""$repoDomain"".txt"
  fi
  if ! [[ $bulkDeleteURLlist == y ]]; then
    mv ./deburllist.txt "./urllists/""$repoDomain"".txt"
  fi
  if [[ $bulkDownloadDebs == y ]]; then
    mv debs "$repoDomain"
  fi
done <$file
