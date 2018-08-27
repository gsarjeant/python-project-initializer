#! /bin/sh

SHORT_OPTS='dpltc'
LONG_OPTS='target-dir,python-version,pylint-version,pytest-version,coverage-version'
OPTS=$(getopt -o ${SHORT_OPTS}: --long ${LONG_OPTS}: -n 'parse-options' -- "$@")

echo $OPTS
