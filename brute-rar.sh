#!/bin/bash

# Brute-forcing password protected RAR file.
#

if [ $# -ne 2 ]; then
    echo "Usage: $0 file.rar dictionary"
    exit 1;
fi

RAR_FILE=$1
DICTIONARY=$2
FREQUENCY=200

if [ ! -f $RAR_FILE ]; then
    echo "Usage: $RAR_FILE doesn't exist!"
    exit 1;
fi

if [ ! -f $DICTIONARY ]; then
    echo "Usage: $DICTIONARY doesn't exist!"
    exit 1;
fi

DICTIONARY_SIZE=`wc -l $DICTIONARY | cut -d' ' -f 1`

# Process received signals
trap "echo \"[!] Aborted by the user.\"; exit 1" SIGHUP SIGINT SIGTERM

echo "[+] Bruteforcing password on $RAR_FILE"
echo -e "[+] Using dictionary ${DICTIONARY}\n"
echo "[*] Reporting once every $FREQUENCY password tries."
echo -e "[*] Use CTRL+C to kill it anytime.\n"
i=0;
TOTAL=0;

# Before attempting to bruteforce the password,
# try without password at all
unrar e -inul -y -p- $RAR_FILE
if [ $? -eq 0 ]; then
    echo "[+] SUCCESS with no password!"
    exit 0;
fi

while read password
do
    # Omit trying empty password (already tried before)
    if [ "$password" == "" ]; then
        continue;
    fi
    unrar e -inul -y -p"${password}" $RAR_FILE
    if [ $? -eq 0 ]; then
        echo "[+] SUCCESS with password '$password'!"
        exit 0;
    fi
    if [ $i -eq $FREQUENCY ]; then
        TOTAL=`expr $TOTAL + $i`
        i=0;
        PROGRESS=`echo "$TOTAL * 100 / $DICTIONARY_SIZE" | bc -l | cut -c1-6`
        echo -e "[*] Trying '$password'\t(${PROGRESS}% complete)"
    fi
    i=`expr $i + 1`
done < $DICTIONARY

echo -e "[!] No password found."
