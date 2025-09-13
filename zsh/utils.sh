#! /bin/zsh
VERSION="0.1.0"
SRC_NAME=$(basename "$0")
USR_DB="lango_db"
USR_NAME="langoadm"
USR_PASS=
lang_sel=
table_sel=
table_id=

function _printUsage() {
    echo -n "Utilities for Lango DB.\nVersion $VERSION
    
    SYNOPSIS:
        ${SRC_NAME} [OPERATION] [FILE_NAME] ...

    OPERATIONS:
        -gr, --generate-random -[w,p] [language] [n]
                Generate n words/phrases randomly
        -tc, --total-count -[w,p] [language]
                Show total count of words/phrases
        -h, --help
                Display this help and exit
        -v, --version
                Output version information and exit

    The function to generate random numbers can generate
    repeated values.

    EXAMPLES:
        ${SRC_NAME} --help
"
    exit 1
}

function setPass() {
  echo "Type ${USR_NAME}'s password"
  read -s USR_PASS
}

function sendToDB() {
  result_db=$(mariadb --user="$USR_NAME" --password="$USR_PASS" "$USR_DB" -e "$1")
  if [ "$?" -ne 0 ]; then
    exit 1
  fi
}

function getLangId() {
  Q0="SELECT lang_id FROM languages WHERE name = '${1}';"
  sendToDB "$Q0" 
  lang_sel=$(echo "$result_db" | sed "1d") # delete first line
}

function tableId() {
  case "$table_sel" in
    words)
      table_id="word_id"
    ;;
    phrases)
      table_id="phrases_id"
    ;;
  esac
}

function randList() {
  totalCount "$1"
  rand_list=()
  for i in {1.."$2"} 
  do
    rand_list+=($((RANDOM % res_count)))
  done
}

function genRand() {
  tableId
  randList "$1" "$2"
  for i in "${rand_list[@]}"
  do
    Q1="SELECT name FROM ${table_sel} WHERE ${table_id}='${i}'"
    sendToDB "$Q1"
    res_rand=$(echo "$result_db" | sed "1d") # delete first line
    echo "$res_rand"
  done
} 

function totalCount() {
  Q1="SELECT COUNT(*) FROM ${table_sel} WHERE lang_id='${lang_sel}'"
  sendToDB "$Q1"
  res_count=$(echo "$result_db" | sed "1d") # delete first line
  echo "The ${table_sel} table for ${1} language have ${res_count} elements"
}

function prcsTabs() {
  case "$1" in
    -w | --word)
      table_sel="words"
    ;;
    -p | --phrase)
      table_sel="phrases"
    ;;
  esac
}

function prcsArgs() {
  case "$1" in
    -gr | --generate-random)
      setPass
      prcsTabs "$2"
      getLangId "$3"
      genRand "$3" "$4"
    ;;
    -tc | --total-count)
      setPass
      prcsTabs "$2"
      getLangId "$3"
      totalCount "$3"
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
function main() {
  prcsArgs "$@"
}
#set +x
main "$@"
