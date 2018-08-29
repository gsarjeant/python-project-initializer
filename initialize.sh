#! /bin/bash

# NiOTE - I'm just using 1 as a universal nonzero return here for convenience.
#         I can put in more robust failure state reporting if needed later.

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
    # We'll assume target dir is valid until something fails
    TARGET_DIR_VALID=0

    # First, see if targetdir was passed in (i.e. TARGET_DIR is set)
    # If it wasn't, then set it to the current directory
    if [[ -z "$TARGET_DIR" ]] ; then
        echo "Target dir not set. Setting to current directory"
        TARGET_DIR=$PWD
    fi

    # Check whether TARGET_DIR exists after setting
    # If it doesn't, print a message and set the return value to 1
    if [[ ! -d "$TARGET_DIR" ]] ; then
        TARGET_DIR_VALID=1
        echo "ERROR: Target directory (${TARGET_DIR}) does not exist."
    fi	

    # Make sure that TARGET_DIR is not this script's parent directory
    # Get the directory of this script
    MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

    if [[ "$TARGET_DIR" == "$MY_DIR" ]] ; then
	TARGET_DIR_VALID=1
        echo "ERROR: Target directory is this script's directory"
    fi

    return $TARGET_DIR_VALID
}

# If no python version was specified, make sure there is a version of python installed
# If a specific version was specified, make sure that version exists.
validate-python(){
    if [[ -z "$PYTHON_VERSION" ]] ; then
        # No python version was specified.
	# Try to find the system python (`which python`) and use it if it exists.
        echo "No python version specified. Using system python."
	PYTHON_VERSION=$( which python )
	PYTHON_INSTALLED=$?

	if (( $PYTHON_INSTALLED != 0 )) ; then
            # `which python` returned an error. Python is not installed (or at least isn't on the PATH).
	    # Print an error message and return non-zero
            echo "ERROR: python could not be found. Please ensure that python is installed and is in the PATH."
	    return 1
	fi
    else
        # The user requested a specific python.
	# Verify that it exists.
	if [[ ! -f "$PYTHON_VERSION" ]] ; then
	    # The requested version of python doesn't exist.
	    # Print an error message and exit
	    echo "ERROR: The specified version of python could not be found."
	    echo "       ${PYTHON_VERSION}"
	    return 1
	fi
    fi
}

# Ensure that pip is installed
validate-pip(){
  # Nothing fancy here. We can just call "which virtualenv" and piggyback off the return code.
  which pip >/dev/null
}

# Ensure that virtualenv is installed
validate-virtualenv(){
  # Nothing fancy here. We can just call "pip show virtualenv" and piggyback off the return code.
  pip show virtualenv >/dev/null
}

# Ensure that git is installed
validate-git(){
  # Nothing fancy here. We can just call "which git" and piggyback off the return code.
  which git >/dev/null
}

# Call the individual functions to validate that all prereqs are met.
# Return 0 on success and 1 if there are any failures
validate-prereqs(){

    # validate-targetdir and validate-python will print messages on failure
    # So we don't need to print anything extra here.
    # Just capture the return values

    validate-targetdir
    TARGETDIR_RESULT=$?
    
    validate-python
    PYTHON_RESULT=$?

    # The functions below will not print messages on failure
    # So we need to print error messages here if they fail

    validate-pip
    PIP_RESULT=$?
    if (( PIP_RESULT != 0 )); then
        echo "ERROR: pip was not found. Please install pip before proceeding."
    fi

    validate-virtualenv
    VIRTUALENV_RESULT=$?
    if (( VIRTUALENV_RESULT != 0 )); then
        echo "ERROR: virtualenv was not found. Please install virtualenv before proceeding."
    fi

    validate-git
    GIT_RESULT=$?
    if (( GIT_RESULT != 0 )) ; then
        echo "ERROR: git was not found. Please install git before proceeding."
    fi

    # Add up all the return values and return the result.
    return $(( TARGETDIR_RESULT + 
               PYTHON_RESULT +
	       PIP_RESULT +
	       VIRTUALENV_RESULT +
	       GIT_RESULT
	     ))
}

function initialize-virtualenv(){
    echo "Creating python virtualenv in ${TARGET_DIR}."
    echo "Using python at ${PYTHON_VERSION}."

    # Create a virtualenv in ${TARGET_DIR}/.env
    # I won't redirect the output for now so we can see it.
    # The function will return the return value of the virtualenv command
    # (so we can test for errors).

    # NOTE: This command works with python2.
    #       I'll generalize for python3 later, but python2 is my current concern
    $PYTHON_VERSION -m virtualenv "${TARGET_DIR}/.env"
}

# Install required test framework modules in the virtualenv
function initialize-modules(){
    echo "Activating virtualenv"
    source "${TARGET_DIR}/.env/bin/activate"

    echo "Installing test framework modules in the virtualenv with pip."
    pip install pylint
    pip install git-pylint-commit-hook
    pip install pytest
    pip install coverage
}

# Copy the pre-commit hook into place and set it executable.
# For now, being lazy and assuming TARGET_DIR:
#     - is a git repo
#     - doesn't already have a pre-commit hook
#
# Cleanup to come.
function copy-pre-commit-hook(){
    echo "Moving pre-commit hook into place."
    MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
    cp "${MY_DIR}/pre-commit" "${TARGET_DIR}/.git/hooks"
    chmod 0700 "${TARGET_DIR}/.git/hooks"
}
######################################################################################
# Script execution
######################################################################################

# The script allows short and long arguments, but use getopts to parse arguments.
# getoprt only deals with short arguments, 
# so convert any long arguments to short arguments before evaluating

# Create an array to hold args
args=()

# loop through the input arguments and convert long args to short args
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

# parse input arguments with getopts.
while getopts "hd:p:l:t:c:" OPTION; do
    : "$OPTION" "$OPTARG"

    case $OPTION in
        h) usage; exit 0;;
	d) TARGET_DIR="$OPTARG";;
	p) PYTHON_VERSION="$OPTARG";;
	l) PYLINT_VERSION="$OPTARG";;
	t) PYTEST_VERSION="$OPTARG";;
	c) COVERAGE_VERSION="$OPTARG";;
	*) echo "Unexpected argument ${OPTION}" ; usage ; exit 1;;
    esac
done

# remove all arguments that were handled by getopts from $@
shift $((OPTIND - 1))

# Validate prerequisites
validate-prereqs
VALIDATION_RESULT=$?

# If all prereqs are met, then initialize this directory as a python project
if (( VALIDATION_RESULT == 0 )) ; then
    # Just print out the input arguments for now.
    echo "Target dir: ${TARGET_DIR}"
    echo "Python version: ${PYTHON_VERSION}"
    echo "Pylint version: ${PYLINT_VERSION}"
    echo "Pytest version: ${PYTEST_VERSION}"
    echo "Coverage version: ${COVERAGE_VERSION}"

    # Initialize the directory as a python project.

    # Create a virtualenv
    initialize-virtualenv
    VIRTUALENV_RESULT=$?
    if (( VIRTUALENV_RESULT != 0 )) ; then
        # Something went wrong creating the virtualenv.
	# Print an error message and exit nonzer`o.
        echo "ERROR: Failed to create virtualenv."
        exit 1
    fi

    # Install the test modules in the virtualenv
    initialize-modules
    
    # Move the pre-commit hook into place
    copy-pre-commit-hook
else
    # Print out a generic error message and quit
    echo "ERROR: Validation errors detected. Please correct before proceeding."
    exit 1
fi
