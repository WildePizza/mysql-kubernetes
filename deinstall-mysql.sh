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
  echo "Executing: $@"
  if ! "$@"
  then
    echo "$(printf "Failed during: %s" "$(shell_join "$@")")"
    exit 1
  fi
}

execute "kubectl delete secret mysql-secret"
execute "kubectl delete pv mysql-pv-volume"
execute "kubectl delete pvc mysql-pv-claim"
execute "kubectl delete deployment mysql"
execute "kubectl delete service mysql-service"
execute "kubectl delete deployment phpmyadmin-deployment"
execute "kubectl delete service phpmyadmin-service"
