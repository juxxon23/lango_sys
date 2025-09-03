#! /bin/zsh

VERSION="0.1.0"
SRC_NAME=$(basename "$0")
BIN_MARIADB=$(which mariadb)
DB_USER="langoadm"
DB_NAME="lango_db"
Q0="USE ${DB_NAME};"
COL0=("name")
COL1=("name," "description")
COL2=("name," "description," "lang_id")

function _printUsage() {
    echo -n "${SRC_NAME} [OPTION]...

Manage Lango DB.
Version $VERSION
    
    SYNOPSIS:
        ${SRC_NAME} [TABLE] [OPERATION] ...

    TABLES:
        Specifies table to use
        -l, --language    Select languages
        -w, --word        Select words
        -p, --phrase      Select phrases
        -t, --tags        Select tags

    OPERATIONS:
        -c, --create [name] ...
                Create new element
        -si, --showid [name]
                Displays element's id
        -u, --update [name] [column] [new_value]
                Updates a column of the element 
        -d, --delete [name]
                Delete a element
        -h, --help
                Display this help and exit
        -v, --version
                Output version information and exit

    Examples:
        ${SRC_NAME} --help
"
    exit 1
}

function checkExists() {
  Q1="SELECT * FROM ${table} WHERE name = '${1}'"
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
  case $table in
    languages)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL0}) VALUES ('${2}');"
        ;;
        si)  
          Q1="SELECT lang_id FROM ${table} WHERE name = '${2}';"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE lang_id = ${result_id};"
        ;;
      esac
    ;;
    words)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL2}) VALUES ('${2}', '${3}', '${4}');"
        ;;
        si)  
          Q1="SELECT word_id FROM ${table} WHERE name = '${2}';"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE word_id = ${result_id};"
        ;;
      esac
    ;;
    phrases)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL2}) VALUES ('${2}', '${3}', '${4}');"
        ;;
        si)  
          Q1="SELECT phrase_id FROM ${table} WHERE name = '${2}';"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE phrase_id = ${result_id};"
        ;;
      esac
    ;;
    tags)
      case $1 in
        c)  
          Q1="INSERT INTO ${table} (${COL1}) VALUES ('${2}', '${3}');"
        ;;
        si)  
          Q1="SELECT tag_id FROM ${table} WHERE name = '${2}';"
        ;;
        d)
          Q1="DELETE FROM ${table} WHERE name = '${2}';"
        ;;
        u)
          Q1="UPDATE ${table} SET ${2} = '${3}' WHERE tag_id = ${result_id};"
        ;;
      esac
    ;;
  esac

  echo $Q1
  echo "${Q0}${Q1}" > query.sql
}

function insert() {
  checkExists $1
  if [ $result_check -eq 1 ]; then
    echo "The element ${1} already exists"
    exit 1
  fi
  
  writeQuery c $1 $2 $3
  $BIN_MARIADB -u $DB_USER -p < query.sql
  if [ $? -eq 1 ]; then
    rm query.sql
    exit 1
  fi

  echo "The element ${1} was created"
  rm query.sql
}

function getId() {
  checkExists $1
  if  [ $result_check -eq 0 ]; then
    echo "The element ${1} is not stored"
    return 1
  fi

  writeQuery si $1
  $BIN_MARIADB -u $DB_USER -p < query.sql > ID_EL
  if [ $? -eq 1 ]; then
    rm query.sql
    rm ID_EL
    exit 1
  fi

  result_id=$(sed -n "2p" ID_EL)
  echo "The id for ${1} is: ${result_id}"
  rm query.sql
  rm ID_EL
}

function delete() {
  checkExists $1
  if  [ $result_check -eq 0 ]; then
    echo "The element ${1} is not stored"
    exit 1
  fi
  
  writeQuery d $1
  $BIN_MARIADB -u $DB_USER -p < query.sql
  if [ $? -eq 1 ]; then
    rm query.sql
    exit 1
  fi

  echo "The element ${1} was deleted"
  rm query.sql
}

function update() {
  getId $1
  writeQuery u $2 $3
  $BIN_MARIADB -u $DB_USER -p < query.sql
  if [ $? -eq 1 ]; then
    rm query.sql
    exit 1
  fi

  echo "The element ${1} was updated"
  rm query.sql
}

function processOperations() {
  case $1 in
    -c | --create)
      insert $2 $3 $4
      ;;
    -u | --update)
      update $2 $3 $4
      ;;
    -d | --delete)
      delete $2
      ;;
    -si | --showid)
      getId $2
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
      processOperations $2 $3 $4 $5
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
      processOperations $2 $3 $4 $5
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

