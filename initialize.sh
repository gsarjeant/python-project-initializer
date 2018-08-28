#! /bin/bash

######################################################################################
# Function definition
######################################################################################

# Print out usage information.
# Called if a user passes -h or --help.
usage(){
    echo "\
    $(basename "$0") [OPTION VALUE OPTION VALUE ...]
    -d, --target-dir; The directory to initialize as a python project.
                    ; default: current directory
    -p, --python-version; The version of python to use in the project's virtualenv.
                        ; default: system python
    -l, --pylint-version; The version of pylint to install with pip.
                        ; default: Latest version
    -t, --pytest-version; The version of pytest to install with pip.
                        ; default: Latest version
    -c, --coverage-version; The version of coverage to install with pip.
                          ; default: Latest version
    -h, --help; Print this message and exit.
    " | column -t -s ";"
}

# The target directory must:
#    - exist
#    - not be this project's root directory
validate-targetdir(){
# First, see if targetdir was passed in (i.e. TARGET_DIR is set)
    # If it wasn't, then set it to the current directory
    if [ -n ${TARGET_DIR+x} ] ; then
        echo "Target dir not set. Setting to current directory"
        TARGET_DIR=$PWD
    fi

    echo "Target dir set to ${TARGET_DIR}"

    # Check whether TARGET_DIR exists after setting it and return the result
    # (true if TAARGET_DIR exists, false otherwise)
    [ -d "${TARGET_DIR}" ]

    # Make sure that TARGET_DIR is not this script's parent directory
}
######################################################################################
# Script execution
######################################################################################

# Create an array to hold args
args=()

#replace long arguments with their short versions
for arg; do
    case "$arg" in
        --help)              args+=( -h ) ;;
        --target-dir)        args+=( -d ) ;;
        --python-version)    args+=( -p ) ;;
        --pylint-version)    args+=( -l ) ;;
        --pytest-version)    args+=( -t ) ;;
        --coverage-version)  args+=( -c ) ;;
        *)                   args+=( "$arg" ) ;;
    esac
done

# Update the input arguments ($@) with the revised (short-arg-only) version
#printf 'args before update : '; printf '%q ' "$@"; echo
set -- "${args[@]}"
#printf 'args after update  : '; printf '%q ' "$@"; echo

while getopts "hd:p:l:t:c:" OPTION; do
    : "$OPTION" "$OPTARG"
    #echo "optarg: ${OPTARG}"

    case $OPTION in
        h) usage; exit 0;;
	d) TARGET_DIR="$OPTARG";;
	p) PYTHON_VERSION="$OPTARG";;
	l) PYLINT_VERSION="$OPTARG";;
	t) PYTEST_VERSION="$OPTARG";;
	c) COVERAGE_VERSION="$OPTARG";;
	:) echo "Invalid option: ${OPTION} requires an argument" 1>&2 ; exit 1;; 
	*) echo "Unexpected argument ${OPTION}" ; usage ; exit 1;;
    esac
done

# remove all arguments that were handled by getopts from $@
shift $((OPTIND - 1))

validate-targetdir

echo "Target dir: ${TARGET_DIR}"
echo "Python version: ${PYTHON_VERSION}"
echo "Pylint version: ${PYLINT_VERSION}"
echo "Pytest version: ${PYTEST_VERSION}"
echo "Coverage version: ${COVERAGE_VERSION}"


exit
