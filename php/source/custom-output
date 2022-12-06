#!/bin/sh
set -e

error () {
  printf "\033[1;31m%s\033[0m\n" "$1"
}

info () {
  printf "\033[1m%s\033[0m\n" "$1"
}

success () {
  printf "\033[1;32m%s\033[0m\n" "$1"
}

case "$1" in
  error)
    shift 1
    error "$@"
    ;;
  info)
    shift 1
    info "$@"
    ;;
  success)
    shift 1
    success "$@"
    ;;
  *)
    echo "Undefied!"
    exit 1
esac

exit 0
