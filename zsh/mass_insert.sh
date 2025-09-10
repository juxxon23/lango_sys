#! /bin/zsh

USR_DB="lango_db"
USR_NAME="langoadm"
USR_PASS=
lang_sel="1"
file_name="DATA"

function main() {
  while IFS=' ' read line
  do
    split_line=($(echo $line | tr ' ' '\n'))
    echo "INSERT INTO words (name, description, lang_id) VALUES ('${split_line[1]}','${split_line[2]}','${lang_sel}');" >> WQ
    split_tag=($(echo ${split_line[3]} | tr ',' '\n'))
    for tag in $split_tag
    do
      echo "INSERT INTO tags (name) VALUES ('${tag}');" >> TQ
    done
  done < $file_name
}

main "$@"
