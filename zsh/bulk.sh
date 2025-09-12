#! /bin/zsh
VERSION="0.1.0"
SRC_NAME=$(basename "$0")
USR_DB="lango_db"
USR_NAME="langoadm"
USR_PASS=
lang_sel=
file_name=

function _printUsage() {
    echo -n "Bulk operations in Lango DB.\nVersion $VERSION
    
    SYNOPSIS:
        ${SRC_NAME} [OPERATION] [FILE_NAME] ...

    OPERATIONS:
        -i, --insert [file_name] [language]
                Insert words
        -r, --relation [file_name]
                Insert relationships between words and tags
        -h, --help
                Display this help and exit
        -v, --version
                Output version information and exit

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
  result_lid=$(echo "$result_db" | sed "1d") # delete first line
}

function getWordId() {
  Q0="SELECT word_id FROM words WHERE name = '${1}';"
  sendToDB "$Q0" 
  result_wid=$(echo "$result_db" | sed "1d")
}

function getTagId() {
  Q0="SELECT tag_id FROM tags WHERE name = '${1}';"
  sendToDB "$Q0" 
  result_tid=$(echo "$result_db" | sed "1d")
}

function insert() {
  echo "Insert operation in process"
  Q1="INSERT INTO words (name, description, lang_id)\nVALUES\n"
  while IFS= read -r line
  do
    split_line=("${(@f)$(tr '-' '\n' <<< "$line")}") # split lines by '-' and '\n'
    Q1+="('${split_line[1]}','${split_line[2]}','${lang_sel}'),\n"
  done < "$file_name"
  Q1="${Q1%,*};" # delete last ',' and add ';'
  sendToDB $Q1
  echo "Operation completed"
}

function relation() {
  echo "Relation operation in process"
  Q1="INSERT INTO words_tags (word_id, tag_id)\nVALUES\n"
  while IFS= read -r line
  do
    split_lines=($(echo $line | tr ' ' '\n'))
    getWordId "${split_lines[1]}"
    split_tags=($(echo ${split_lines[2]} | tr ',' '\n')) # split tags by ','
    for tag in "${split_tags[@]}"
    do
      getTagId "$tag"
      Q1+="('${result_wid}','${result_tid}'),\n" 
    done
  done < "$file_name"
  Q1="${Q1%,*};"
  sendToDB $Q1
  echo "Operation completed"
}

function prcsArgs() {
  file_name="$2"
  case "$1" in
    -i | --insert)
      setPass
      getLangId "$3"
      lang_sel="$result_lid"
      insert
    ;;
    -r | --relation)
      setPass
      relation
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
