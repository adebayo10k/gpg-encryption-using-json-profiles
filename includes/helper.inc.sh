#!/bin/bash
# This is a helper script to help "the human" to interface appropriately
# with "the program". 

#########################
# GLOBAL VARIABLE DECLARATIONS:
#########################
program_title="gpg file encrypter"
original_author="damola adebayo"
all_the_parameters_string="$@"
declare -a working_array=()
declare -a validated_files_array=()

#########################
# FUNCTION DECLARATIONS:
#########################
#
function check_all_program_preconditions() {
    local program_dependencies=("jq" "shred" "gpg")
    # check program dependencies, exit 1 if can't even do that
	lib10k_check_program_dependencies "${program_dependencies[@]}" || exit 1
	verify_program_args "$all_the_parameters_string"
	[ $? -eq 0 ] || usage	
	validate_program_args "$all_the_parameters_string"
    [ $? -eq 0 ] && validated_files_array=("${working_array[@]}")
}

# check whether program parameters meet our defined specification
# program expected either:
# - one or more absolute paths to plaintext files to be encrypted
# - the string 'help'
function verify_program_args() {
    local all_the_parameters_string="$1"
	[ -z "$all_the_parameters_string" ] && return 1
    [ -n "$all_the_parameters_string" ] && [[ "$all_the_parameters_string" =~ ^[[:blank:]]+$ ]] && return 1
    [ -n "$all_the_parameters_string" ] && [[ ! $all_the_parameters_string =~ ^[A-Za-z0-9\ \.\/_\-]+$ ]] && return 1
	[ -n "$all_the_parameters_string" ] && [ "$all_the_parameters_string" == 'help' ] && return 1
	[ -n "$all_the_parameters_string" ] && return 0
}

# This function always exits program
function usage () {

	cat <<_EOF	
Usage:	$command_basename [help] | FILE...

GnuPG encrypt one or more FILE(s).
FILE can be either the basename or the absolute path to the file.
Simple file basename parameters are assumed to be
in the current working directory.

File globbing and expansion is not available, unfortunately.
Only valid filename characters are allowed in filenames.

Valid values for encryption profiles:
encryptionSystem    public_key|symmetric_key
outputFileFormat    ascii|binary


help	Show this text.

_EOF

exit 0
}


############################################
# check program positional parameters are of correct form.
# this function does the file path tests on each of them...
# a code block with a failing test must exit the program immediately.
function validate_program_args() {
    local all_the_parameters_string="$1"

    #1. catch the single blank character string that can bypass a for-loop
    # exit program
    if [ $# -eq 1 ] && [[ "$all_the_parameters_string" =~ ^[[:blank:]]+$ ]]
    then
        msg="There seemed to be only blank characters as parameter. Exiting now..."
		lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
    fi

    #2. the for-loop seems to treat spaces as IFSs and not parameters, 
    # and trim them if around other characters.
    # allocate what's left to a working array? or keep passing strings around as parameters?
    # if any of the args now contain illegal filename characters
    # exit program
    for incoming_arg in $all_the_parameters_string
    do
        if [[ ! $incoming_arg =~ ^[A-Za-z0-9\.\/_\-]+$ ]]
        then
            msg="A parameter seemed to contain illegal filename characters. Exiting now..."
			lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
        fi
    done

    # assume solitary file basename is located in current directory.
    # modifies these args by adding a leading ./ before tests.
    # if any of the args looks like a basename, mutate it in the working array.
	for incoming_arg in $all_the_parameters_string
	do
		if [[ $incoming_arg =~ $FILE_BASENAME_LA_REGEX ]]
		then
			incoming_arg="./$incoming_arg"
		fi
        working_array+=("$incoming_arg") 
	done

	# if any of the args is now not in the form of an absolute file path, \
    # exit program.
	for working_arg in "${working_array[@]}"
	do
		lib10k_test_file_path_valid_form "$working_arg"
		return_code=$?
		if [ $return_code -ne 0 ]
		then
			msg="The valid form test FAILED and returned: $return_code. Exiting now..."
			lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
		fi
	done
	
	# if any of the args is not a readable, regular file, exit program
	for working_arg in "${working_array[@]}"
	do			
		lib10k_test_file_path_access "$working_arg"
		return_code=$?
		if [ $return_code -ne 0 ]
		then
			msg="The file path access test FAILED and returned: $return_code. Exiting now..."
			lib10k_exit_with_error "$E_REQUIRED_FILE_NOT_FOUND" "$msg"
		fi
	done

	# if path is not cd-able, exit program
	for working_arg in "${working_array[@]}"
	do
		plaintext_dir_fullpath=$(dirname ${working_arg})
		lib10k_test_dir_path_access1 "$plaintext_dir_fullpath"
		return_code=$?
		if [ $return_code -ne 0 ]
		then
			msg="The directory path access test FAILED and returned: $return_code. Exiting now..."
			lib10k_exit_with_error "$E_REQUIRED_FILE_NOT_FOUND" "$msg"
		fi
	done

    return $?
}
