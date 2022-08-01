#!/bin/bash
# This is a helper script to help "the human" to interface appropriately
# with "the program". 

#########################
# GLOBAL VARIABLE DECLARATIONS:
#########################
program_title="gpg file encrypter"
original_author="damola adebayo"
declare -i max_expected_no_of_program_parameters=6 # arbitrary for now
declare -i min_expected_no_of_program_parameters=1
declare -ir actual_no_of_program_parameters=$#
all_the_parameters_string="$@"
declare -a incoming_array=( $all_the_parameters_string )
no_of_program_parameters=$#
declare -a working_array=()
declare -a validated_array=()

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
	verify_program_args
	[ $? -eq 0 ] || usage	
	validate_program_args
    [ $? -eq 0 ] && validated_array=("${working_array[@]}")	

}

# check whether program parameters meet our defined specification
# program expected either:
# - one or more absolute paths to plaintext files to be encrypted
# - help
function verify_program_args() {
	[ -z "$all_the_parameters_string" ] && return 1
	[ -n "$all_the_parameters_string" ] && [ $all_the_parameters_string = 'help' ] && return 1
	[ -n "$all_the_parameters_string" ] && return 0
}

# This function always exits program
function usage () {

	cat <<_EOF	
Usage:	$command_basename [help] | FILE...

GnuPG encrypt FILE(S)

FILE can be either a file basename of a file in the pwd
or the absolute path the a file.


# List the functionality of the program

# Describe some interesting things to know

help	Show this text.

_EOF

exit 0
}



############################################
# check program positional parameters are of correct form
# this function now does the file path tests on each of them...
# a code block with a failing test must exit the program immediately.
function validate_program_args() {
    echo "Number of arguments passed in = $no_of_program_parameters" && echo
    echo "incoming_array[@]: ${incoming_array[@]}"

    # program assumes user provided basename is meant to be in the current directory.
    # change these args by adding a leading ./ before tests.

    # if any of the args looks like a basename, mutate it in the incoming array.
	for incoming_arg in "${incoming_array[@]}"
	do
		echo "incoming argument is now: $incoming_arg"
		if [[ $incoming_arg =~ $FILE_BASENAME_LA_REGEX ]]
		then
			incoming_arg="./$incoming_arg"
            echo "incoming argument is now: $incoming_arg"
        else
            echo "NOT A BASENAME."    	
		fi

        working_array+=("$incoming_arg") 
	done


	# if any of the args is now not in the form of an absolute file path, \
    # exit program.
	for working_arg in "${working_array[@]}"
	do
		echo "working argument is now: $working_arg"
		lib10k_test_file_path_valid_form "$working_arg"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo $working_arg
			echo "VALID FORM TEST PASSED" && echo
		else
			msg="The valid form test FAILED and returned: $return_code. Exiting now..."
			lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
		fi
	done
	
	# if any of the args is not a readable, regular file, exit program
	for working_arg in "${working_array[@]}"
	do			
		lib10k_test_file_path_access "$working_arg"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "The full path to the plaintext file is: $working_arg"
			echo "REGULAR FILE READ TEST PASSED" && echo
		else
			msg="The file path access test FAILED and returned: $return_code. Exiting now..."
			lib10k_exit_with_error "$E_REQUIRED_FILE_NOT_FOUND" "$msg"
		fi
	done

	# if 
	for working_arg in "${working_array[@]}"
	do
		plaintext_dir_fullpath=$(dirname ${working_arg})
		lib10k_test_dir_path_access1 "$plaintext_dir_fullpath"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "The full path to the plaintext file holding directory is: $plaintext_dir_fullpath"
			echo "HOLDING DIRECTORY ACCESS READ TEST PASSED" && echo
		else
			msg="The directory path access test FAILED and returned: $return_code. Exiting now..."
			lib10k_exit_with_error "$E_REQUIRED_FILE_NOT_FOUND" "$msg"
		fi
	done

    return $?
}
