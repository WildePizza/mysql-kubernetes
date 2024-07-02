#!/bin/bash

log=$1

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

execute() {
  command="$@"
  if [ "$log" = false ]; then
    void=$($command >&2)
  else
    $command
    if [[ $? -ne 0 ]]; then
      echo "Error: '$command' failed with exit code: $?."
    fi
  fi
}

execute "kubectl delete secret mysql-root-pass --grace-period=0 --force"
execute "kubectl delete secret mysql-user-pass --grace-period=0 --force"
execute "kubectl delete deployment mysql --grace-period=0 --force"
execute "kubectl delete service mysql --grace-period=0 --force"
execute "kubectl delete deployment phpmyadmin --grace-period=0 --force"
execute "kubectl delete service phpmyadmin --grace-period=0 --force"
execute "kubectl delete pv mysql-pv --grace-period=0 --force"
execute "kubectl delete pvc mysql-pv-claim --grace-period=0 --force"
