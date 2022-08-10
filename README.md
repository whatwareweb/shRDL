# BashRDL
Cydia repo downloader/archiver written in Bash


### Syntax:
./bashrdl.sh [http(s)://apt.cydiarepo.url] [y/n] [y/n] [y/n]

1st y/n argument: whether or not to delete Packages file

2nd y/n argument: whether or not to delete deburllist.txt file

3rd y/n argument: whether or not to auto download all debs

### Bulk syntax:
./rdlbulk.sh [y/n] [y/n] [y/n]

Gets repo URLs from ./repos.txt

1st y/n argument: whether or not to delete Packages file

2nd y/n argument: whether or not to delete deburllist.txt file

3rd y/n argument: whether or not to auto download all debs

If arguments are unspecified, you will be prompted to answer


### Dependencies:
- GNU core utils
- bzip2
- curl
- wget
