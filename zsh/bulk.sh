#! /bin/zsh
VERSION="0.1.0"
SRC_NAME=$(basename "$0")
USR_DB="lango_db"
USR_NAME="langoadm"
USR_PASS=
lang_sel=
lang_tran=
file_name=

function _printUsage() {
    echo -n "Bulk operations in Lango DB.\nVersion $VERSION
    
    SYNOPSIS:
        ${SRC_NAME} [OPERATION] [FILE_NAME] ...

    OPERATIONS:
        -i, --insert [file_name] [language] [language_translation]
                Insert words with their translations
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

function insertTranslation() {
  echo "Translation operation in process"
  Q2="INSERT INTO words_translation (word_id, word_tran_id)\nVALUES\n"
  while IFS= read -r line
  do
    split_line=("${(@f)$(tr '-' '\n' <<< "$line")}") 
    getWordId "${split_line[1]}"
    word1="$result_wid"

    split_line2=("${(@f)$(tr ',' '\n' <<< "$split_line[2]")}")
    for line2 in "${split_line2[@]}"
    do
      getWordId "${line2}"
      word2="$result_wid"
      Q2+="('${word1}','${word2}'), \n"
    done
  done < "$file_name"
  Q2="${Q2%,*};"
  sendToDB $Q2
  echo "Operation completed"
}

function insert() {
  echo "Insert operation in process"
  Q1="INSERT INTO words (name, lang_id)\nVALUES\n"
  while IFS= read -r line
  do
    # Expansion especial en zsh
    # @ -> Expansión en array.
    # f -> Divide la cadena en elementos usando saltos de línea (\n) como delimitadores.
    split_line=("${(@f)$(tr '-' '\n' <<< "$line")}") # replace '-' with '\n' to split lines 
    Q1+="('${split_line[1]}','${lang_sel}'),\n"
    
    split_line2=("${(@f)$(tr ',' '\n' <<< "$split_line[2]")}")
    for line2 in "${split_line2[@]}"
    do
      Q1+="('${line2}','${lang_tran}'), \n"
    done
  done < "$file_name"
  Q1="${Q1%,*};" # delete last ',' and add ';'
  sendToDB $Q1
  echo "Operation completed"
  insertTranslation
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
      getLangId "$4"
      lang_tran="$result_lid"
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
