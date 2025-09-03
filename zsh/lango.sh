#! /bin/zsh

VERSION="0.1.0"
SCR_NAME=$(basename "$0")
BIN_MARIADB=$(which mariadb)
DB_USER="langoadm"
DB_NAME="lango_db"
Q0="USE ${DB_NAME};"
COL0=("name")
COL1=("name," "description")
COL2=("name," "description," "lang_id")

function _printUsage() {
    echo -n "${SCR_NAME} [OPTION]...

Manage Language table.
Version $VERSION

    Options:
        -c, --create      Create new language
        -si, --showid     Display language id of the given name
        -u, --update      Update language name from its previous name
        -d, --delete      Delete a row
        -h, --help        Display this help and exit
        -v, --version     Output version information and exit

    Examples:
        ${SCR_NAME} --help
"
    exit 1
}

function checkExists() {
  Q1="SELECT * FROM languages WHERE name = '${1}'"
  Q2="EXISTS (${Q1})"
  Q3="SELECT IF (${Q2}, 1, 0) as RESULT;"
  echo "${Q0}${Q3}" > check_exists.sql
  $BIN_MARIADB -u $DB_USER -p < check_exists.sql > RESULT_CHECK
  if [ $? -eq 1 ]; then
    rm check_exists.sql
    rm RESULT_CHECK
    exit 1
  fi

  result_check=$(sed -n "2p" RESULT_CHECK)
  rm check_exists.sql
  rm RESULT_CHECK
}

function writeQuery() {
  file_name=
  case $table in
    languages)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL0}) VALUES ('${2}');"
          file_name="create_el.sql"
        ;;
        si)  
          Q1="SELECT lang_id FROM ${table} WHERE name = '${2}';"
          file_name="get_id.sql"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
          file_name="delete_el.sql"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE lang_id = ${result_id};"
          file_name="update_el.sql"
        ;;
      esac
    ;;
    words)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL2}) VALUES ('${2}', '${3}', '${4}');"
          file_name="create_el.sql"
        ;;
        si)  
          Q1="SELECT word_id FROM ${table} WHERE name = '${2}';"
          file_name="get_id.sql"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
          file_name="delete_el.sql"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE word_id = ${result_id};"
          file_name="update_el.sql"
        ;;
      esac
    ;;
    phrases)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL2}) VALUES ('${2}', '${3}', '${4}');"
          file_name="create_el.sql"
        ;;
        si)  
          Q1="SELECT phrase_id FROM ${table} WHERE name = '${2}';"
          file_name="get_id.sql"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
          file_name="delete_el.sql"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE phrase_id = ${result_id};"
          file_name="update_el.sql"
        ;;
      esac
    ;;
    tags)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL1}) VALUES ('${2}', '${3}');"
          file_name="create_el.sql"
        ;;
        si)  
          Q1="SELECT tag_id FROM ${table} WHERE name = '${2}';"
          file_name="get_id.sql"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
          file_name="delete_el.sql"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE tag_id = ${result_id};"
          file_name="update_el.sql"
        ;;
      esac
    ;;
  esac

  echo "${Q0}${Q1}" > file_name
}

function insert() {
  checkExists $1
  if [ $result_check -eq 1 ]; then
    echo "The element ${1} already exists"
    exit 1
  fi
  
  writeQuery c $1 $2 $3
  $BIN_MARIADB -u $DB_USER -p < create_el.sql
  if [ $? -eq 1 ]; then
    rm create_el.sql
    exit 1
  fi

  echo "The element ${1} was created"
  rm create_el.sql
}

function getId() {
  checkExists $1
  if  [ $result_check -eq 0 ]; then
    echo "The element ${1} is not stored"
    return 1
  fi

  writeQuery si $1
  $BIN_MARIADB -u $DB_USER -p < get_id.sql > ID_EL
  if [ $? -eq 1 ]; then
    rm get_id.sql
    rm ID_EL
    exit 1
  fi

  result_id=$(sed -n "2p" ID_EL)
  echo "The id for ${1} is: ${result_id}"
  rm get_id.sql
  rm ID_EL
}

function delete() {
  checkExists $1
  if  [ $result_check -eq 0 ]; then
    echo "The element ${1} is not stored"
    exit 1
  fi
  
  writeQuery d $1
  $BIN_MARIADB -u $DB_USER -p < delete_el.sql
  if [ $? -eq 1 ]; then
    rm delete_el.sql
    exit 1
  fi

  echo "The element ${1} was deleted"
  rm delete_el.sql
}

function update() {
  getId $1
  writeQuery u $2 $3
  $BIN_MARIADB -u $DB_USER -p < update_el.sql
  if [ $? -eq 1 ]; then
    rm update_el.sql
    exit 1
  fi

  echo "The element was updated, before: ${1} --> now: ${3}"
  rm update_el.sql
}

function processOperations() {
  case $1 in
    -c | --create)
      insertNew $2 $3 $4
      ;;
    -u | --update)
      updateRow $2 $3 $4
      ;;
    -d | --delete)
      delRow $2 $3
      ;;
    -si | --showid)
      getLangId $2 $3
      ;;
    *)
      _printUsage 
      ;;
  esac
}

function processArgs() {
  case $1 in
    -l | --language)
      table="languages"
      processOperations $2 $3 $4
      ;;
    -w | --word)
      table="words"
      processOperations $2 $3 $4 $5
      ;;
    -p | --phrase)
      table="phrases"
      processOperations $2 $3 $4 $5
      ;;
    -t | --tag)
      table="tags"
      processOperations $2 $3 $4
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
table=

function  main() {
  processArgs "$@"
}

main "$@" 
#set +x

