#!/bin/bash

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
  echo "Executing command: '$command'"
  $command
  if [[ $? -ne 0 ]]; then
    echo "Error: '$command' failed with exit code: $?."
  else
    echo "Successfully executed command: '$command'"
  fi
}

execute "kubectl delete secret mysql-root-password"
execute "kubectl delete pv mysql-pv-volume"
execute "kubectl delete pvc mysql-pv-claim"
execute "kubectl delete deployment mysql"
execute "kubectl delete service mysql"
execute "kubectl delete deployment phpmyadmin"
execute "kubectl delete service phpmyadmin"
