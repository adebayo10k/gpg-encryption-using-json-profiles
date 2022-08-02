#!/bin/bash
# This is a helper script to help "the human" to interface appropriately
# with "the program". 

#########################
# GLOBAL VARIABLE DECLARATIONS:
#########################
program_title="gpg file encrypter"
original_author="damola adebayo"
declare -i max_expected_no_of_program_parameters=99 # arbitrary for now
declare -i min_expected_no_of_program_parameters=1
declare -ir actual_no_of_program_parameters=$#
all_the_parameters_string="$@"
declare -a incoming_array=( $all_the_parameters_string )
no_of_program_parameters=$#
declare -a working_array=()
declare -a validated_files_array=()

#########################
# FUNCTION DECLARATIONS:
#########################
#
function check_all_program_preconditions() {
    local program_dependencies=("jq" "shred" "gpg")
    ## Display a program header
	lib10k_display_program_header "$program_title" "$original_author"
    # check program dependencies, exit 1 if can't even do that
	lib10k_check_program_dependencies "${program_dependencies[@]}" || exit 1
    # check the number of parameters to this program
	lib10k_check_no_of_program_args
	verify_program_args "$all_the_parameters_string"
	[ $? -eq 0 ] || usage	
	validate_program_args
    [ $? -eq 0 ] && validated_files_array=("${working_array[@]}")	

}

# check whether program parameters meet our defined specification
# program expected either:
# - one or more absolute paths to plaintext files to be encrypted
# - the string 'help'
function verify_program_args() {
	[ -z "$all_the_parameters_string" ] && return 1
	[ -n "$all_the_parameters_string" ] && [ "$all_the_parameters_string" == 'help' ] && return 1
	[ -n "$all_the_parameters_string" ] && return 0
}

# This function always exits program
function usage () {

	cat <<_EOF	
Usage:	$command_basename [help] | FILE...

GnuPG encrypt one or more FILE(s).
FILE can be either the basename of a file in the pwd,
or the absolute path to the file.
Simple file basename parameters are assumed to be
in the current working directory.

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
    # assume solitary file basename is located in current directory.
    # modifies these args by adding a leading ./ before tests.
    # if any of the args looks like a basename, mutate it in the working array.
	for incoming_arg in "${incoming_array[@]}"
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
