#!/bin/bash

function die() {
    [ -z "$1" ] || echo "$1"
    exit 255
}

#BASE_URL="$@"

#
# !!! Измени эти переменные !!!
# Слеш в конце url ОБЯЗАТЕЛЕН
# Курл не умеет энкодить спецсимволы, поэтому имена папок дб без спецсимволов
#
BASE_URL="ftp://192.168.2.254/bkp/a/"
LOGIN="ЛОГИН"
PASSWORD="ПАРОЛЬ"
#
#


IFS="
"

function process_file() {
    curl -s -f -u "$LOGIN:$PASSWORD" "$1" -O || die "Can't download $1"
}

function process_dir() {
    URL="$1"

    DATA=($(curl -s -f -u "$LOGIN:$PASSWORD" "$URL")) || die "Can't download $URL"
    for f in "${DATA[@]}"
    do
      Q=$(echo "$f" | sed -rn 's/(^[-d])([rwx]{3}){3}([\t ]+[^\t ]+){7}[\t ](.*)$/\1=\4/p' | grep -vE '^d=(\.|\.\.)$')
      case "$Q" in
        d=*)
            NEW_DIR=${Q#d=}
            mkdir -p "$NEW_DIR"
            echo "Process dir: '$URL$NEW_DIR/'"
            ( cd "$NEW_DIR" ; process_dir "$URL$NEW_DIR/" )
        ;;
        -=*)
            NEW_FILE=${Q#-=}
            echo "Process file: '$URL$NEW_FILE'"
            process_file "$URL$NEW_FILE"
        ;;
      esac
    done
}

process_dir "$BASE_URL"
