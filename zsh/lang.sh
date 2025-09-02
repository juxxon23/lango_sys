#! /bin/zsh

VERSION="0.1.0"
SCR_NAME=$(basename "$0")
BIN_MARIADB=$(which mariadb)
DB_USER="langoadm"
DB_NAME="lango_db"
Q0="USE ${DB_NAME};"

function _printUsage() {
    echo -n "${SCR_NAME} [OPTION]...

Manage Language table.
Version $VERSION

    Options:
        -c, --create      Create new language
        -si, --showid     Display language id of the given name
        -h, --help        Display this help and exit
        -v, --version     Output version information and exit

    Examples:
        ${SCR_NAME} --help
"
    exit 1
}

function checkExists() {
  Q1="SELECT * FROM languages WHERE name = '${lang}'"
  Q2="EXISTS (${Q1})"
  Q3="SELECT IF (${Q2}, 1, 0) as RESULT;"
  echo "${Q0}${Q3}" > check_exists.sql
  $BIN_MARIADB -u $DB_USER -p < check_exists.sql > RESULT_CHECK
  result=$(sed -n "2p" RESULT_CHECK)
}

function insertNew() {
  checkExists
  if [ $result -eq 1 ]; then
    echo "The language ${lang} already exists"
    exit 1
  fi
  Q1="INSERT INTO languages (name) VALUES ('${lang}');"
  echo "${Q0}${Q1}" > create_lang.sql
  $BIN_MARIADB -u $DB_USER -p < create_lang.sql
}

function getLangId() {
  checkExists
  if  [ $result -eq 0 ]; then
    echo "The language ${lang} is not stored"
    exit 1
  fi
  Q1="SELECT lang_id FROM languages WHERE name = '${lang}'"
  echo "${Q0}${Q1}" > get_lang_id.sql
  $BIN_MARIADB -u $DB_USER -p < get_lang_id.sql > LANG_ID
  result=$(sed -n "2p" LANG_ID)
  echo "The id for ${lang} is: ${result}"
}

function processArgs() {
  case $1 in
    -c | --create)
      lang=$2
      insertNew
      ;;
    -si | --showid)
      lang=$2
      getLangId
      ;;
    -v | --version)
      echo $VERSION
      ;;
    -h | --help)
      _printUsage
      ;;
    *)
      _printUsage 
      ;;
  esac
}

#set -x
lang=

function  main() {
  processArgs "$@"
}

main "$@" 
#set +x

