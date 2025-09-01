#! /bin/zsh

VERSION="0.1.0"
SCR_NAME=$(basename "$0")


function _printUsage() {
    echo -n "$SCR_NAME [OPTION]...

Manage Language table.
Version $VERSION

    Options:
        -c, --create      Create new language
        -h, --help        Display this help and exit
        -v, --version     Output version information and exit

    Examples:
        $SCR_NAME --help
"
    exit 1
}


lang=""

function  main() {
  case $1 in
    -c | --create)
      lang=$2
      echo "USE lango_db;\nINSERT INTO languages (name) VALUES ('$lang');" > ins_lang.sql
      mariadb -u langoadm -p < ins_lang.sql
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
  echo $lang
}

main "$@" 



