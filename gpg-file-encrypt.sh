#!/bin/bash
#: Title		:gpg-file-encrypt.sh
#: Date			:2019-11-14
#: Author		:adebayo10k
#: Version		:
#: Description	:This script provides file encryption both to other scripts  
#: Description	:and to the command-line user.  
#: Description	:To gpg encrypt one or more files passed in as program arguments.

command_fullpath="$(readlink -f $0)" 
command_basename="$(basename $command_fullpath)"
command_dirname="$(dirname $command_fullpath)"

# verify existence of library dependencies...
# where this project is a submodule, contents of its' library submodule directory \
# are NOT populated, so it uses those of the main project.
if [ -d "${command_dirname}/shared-functions-library" ] && \
[ -n "$(ls ${command_dirname}/shared-functions-library | grep  'shared-bash-')" ]
then
	for file in "${command_dirname}/shared-functions-library"/shared-bash-*
	do
		source "$file"
	done
elif [ -d "${command_dirname}/../shared-functions-library" ] && \
[ -n "$(ls ${command_dirname}/../shared-functions-library | grep  'shared-bash-')" ]
then
    for file in "${command_dirname}/../shared-functions-library"/shared-bash-*
	do
		source "$file"
	done
else
	# return a non-zero exit code with native exit
	echo "Required file not found. Returning non-zero exit code. Exiting now..."
	exit 1
fi

### Library functions have now been read-in ###

# verify existence of included dependencies
if [ -d "${command_dirname}/includes" ] && \
[ -n "$(ls ${command_dirname}/includes)" ]
then
	for file in "${command_dirname}/includes"/*
	do
		source "$file"
	done
else
	msg="Required file not found. Returning non-zero exit code. Exiting now..."
	lib10k_exit_with_error "$E_REQUIRED_FILE_NOT_FOUND" "$msg"
fi

### Included file functions have now been read-in ###

# CALLS TO FUNCTIONS DECLARED IN includes/helper.inc.sh
#==========================
check_all_program_preconditions

function main() {
	##############################
	# GLOBAL VARIABLE DECLARATIONS:
	##############################
	encryption_system_option= # --encrypt | --symmetric
	output_file_extension= # .asc | .gpg
	armor_option='--armor'
	sender_option='--local-user'
	recipient_option='--recipient'	
	gpg_command='gpg'
	output_option='--output'
	file_path_placeholder='<filepath_placeholder>'
	generic_command=
	file_specific_command=

	##############################
	# FUNCTION CALLS:
	##############################

    # CALLS TO FUNCTIONS DECLARED IN includes/gpg-encrypt-profile-build.inc.sh
    #==========================
	import_file_encryption_configuration

    # debug output:
	echo "profile_name: $profile_name"
	echo "profile_description: $profile_description"
	echo "output_file_format: $output_file_format"
	echo "encryption_system: $encryption_system"
	echo "sender_uid: $sender_uid"
	echo "recipient_uid_list: $recipient_uid_list" # an IFS | separated string
    #echo "recipient_uid_list: ${recipient_uid_list[@]}"	
	#echo "recipient_uid_list size: ${#recipient_uid_list[@]}"
	echo 
	
    
    validate_output_format "$output_file_format"    
    validate_encryption_system "$encryption_system"    
    test_uid_keys "$sender_uid" "$recipient_uid_list"
	create_generic_command_string "$output_file_format" "$encryption_system"
    
    gpg_encrypt_files
    exit 0 #debug

    # verify encrypt

    # shred

    # verify shred
	
} ## end main


##############################
####  FUNCTION DECLARATIONS  
##############################
function validate_output_format() {
    local output_file_format="$1"
    [ "$output_file_format" == 'ascii' ] || [ "$output_file_format" == 'binary' ] || usage
}

##############################
# test validity of values for encryption_system and output_file_format || exit
function validate_encryption_system() {
    local encryption_system="$1"
    [ "$encryption_system" == 'public_key' ] || [ "$encryption_system" == 'symmetric_key' ] || usage
}

##############################
# # test uids against gpg keyring.
function test_uid_keys() {
	local sender_uid="$1"    
    local recipient_uid_list="$2"
        
    # no keys or uids needed for symmetric key encryption.
    [ "$encryption_system" == 'symmetric_key' ] && return 0

    # test sender uid
	if (gpg --fingerprint "$sender_uid" >/dev/null 2>&1) && \
    (gpg --list-key "$sender_uid" >/dev/null 2>&1) && \
    (gpg --list-secret-keys "$sender_uid" >/dev/null 2>&1)
    then
        echo -e "Keypair identified for sender $sender_uid OK"
    else
        msg="Failed to identify a Keypair for sender $sender_uid. Exiting now..."
		lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
    fi

    # test recipient uids
    OIFS=$IFS; IFS='|'
    for uid in $recipient_uid_list
    do
        if (gpg --fingerprint "$uid" >/dev/null 2>&1) && \
        (gpg --list-key "$uid" >/dev/null 2>&1)
        then
            echo -e "Keypair identified for recipient $uid OK"
        else
            msg="Failed to identify a Keypair for recipient $uid. Exiting now..."
		    lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
        fi
    done
    IFS=$OIFS
}

##############################
# sets the generic_command global.
# create a generic file encryption command string for either public key or symmetric key encryption.
function create_generic_command_string() {
    local output_file_format="$1"
    local encryption_system="$2"

	[ $output_file_format == 'ascii' ] && output_file_extension=".asc"
	[ $output_file_format == 'binary' ] && output_file_extension='.gpg'
	[ $encryption_system == 'public_key' ] && encryption_system_option='--encrypt'
    [ $encryption_system == 'symmetric_key' ] && encryption_system_option='--symmetric'
    [ $encryption_system == 'public_key' ] && \
    create_generic_public_key_encryption_command_string "$output_file_format" "$encryption_system"
    [ $encryption_system == 'symmetric_key' ] && \
    create_generic_symmetric_key_encryption_command_string "$output_file_format" "$encryption_system"
}

##############################
# this function called if encryption_system=="public_key"
function create_generic_public_key_encryption_command_string() {
    local output_file_format="$1"
    local encryption_system="$2"
	# THIS IS THE FORM:
	# $ gpg [--armor] --output "$plaintext_file_fullpath.ENCRYPTED[.asc|.gpg]" \
	# --local-user <uid> --recipient <uid> --encrypt "$plaintext_file_fullpath"
	generic_command=''
	generic_command+="${gpg_command} "
    [ $output_file_format == 'ascii' ] && generic_command+="${armor_option} "
	generic_command+="${output_option} ${file_path_placeholder}.ENCRYPTED"
	generic_command+="${output_file_extension} "
	generic_command+="${sender_option} "
	generic_command+="${sender_uid} "
    OIFS=$IFS; IFS='|'
	for recipient in $recipient_uid_list
	do
		generic_command+="${recipient_option} ${recipient} "
	done
    IFS=$OIFS
	generic_command+="${encryption_system_option} ${file_path_placeholder}"
    echo && echo "===generic command string===:" # debug
	echo && echo "$generic_command" && echo # debug
}

##############################
# this function called if encryption_system=="symmetric_key"
function create_generic_symmetric_key_encryption_command_string() {
	# COMMAND FORM:
	# $ gpg [--armor] --output "$plaintext_file_fullpath.ENCRYPTED[.asc]" --symmetric "$plaintext_file_fullpath"
	generic_command=''
	generic_command+="${gpg_command} "
    [ $output_file_format == 'ascii' ] && generic_command+="${armor_option} "
    generic_command+="${output_option} ${file_path_placeholder}.ENCRYPTED"
	generic_command+="${output_file_extension} "
	generic_command+="${encryption_system_option} ${file_path_placeholder}"
    echo && echo -e "\033[0;34m===generic command string===\033[0m"  # debug
	echo && echo "$generic_command" && echo # debug
}


##############################
#create, then execute each file specific encryption command.
function gpg_encrypt_files() {

    # command execution may fail if an invalid combination of parameters has been used to create the command string. Make sure we capture this an fail gracefully.

    # from here on, we'll have to go though the whole encrypt-verify-delete process for each file, one at a time.

    for valid_path in "${validated_files_array[@]}"
    do
        echo "valid path : $valid_path"
        create_file_specific_encryption_command "$valid_path"
        check_file_specific_encryption_command "$valid_path"

        execute_file_specific_encryption_command "$valid_path"
       	
        #echo "about to execute on file: $valid_path"
       	#execute_file_specific_encryption_command "$valid_path" #

    done




	#create, then execute each file specific encryption command, then shred plaintext file:
	#for valid_path in "${validated_files_array[@]}"
	#do
	#	echo "about to execute on file: $valid_path"
	#	execute_file_specific_encryption_command "$valid_path" #
#
	#	# check that expected output file now exists, is accessible and has expected encypted file properties
	#	verify_file_encryption_results "${valid_path}"
	#	encrypt_result=$?
	#	if [ $encrypt_result -eq 0 ]
	#	then
	#		echo && echo "SUCCESSFUL VERIFICATON OF ENCRYPTION. encrypt_result: $encrypt_result"
	#	else
	#		msg="FAILURE REPORT. Unexpected encrypt_result: $encrypt_result. Exiting now..."
	#		lib10k_exit_with_error "$E_UNKNOWN_ERROR" "$msg"
	#	fi	
	#done
#
	## 6. SHRED THE PLAINTEXT FILES, NOW THAT ENCRYPTED VERSION HAVE BEEN MADE
#
    #shred_plaintext_files
	#verify_file_shred_results
#
	#return $encrypt_result # resulting from the last successful encryption only! So what use is that?

}

##############################
# the absolute path to the plaintext file is passed in
function create_file_specific_encryption_command() {
	local valid_path="$1"
    # using [,] sed delimiter to avoid interference with file path [/]
	file_specific_command=$(echo "$generic_command" | \
    sed -e 's,'$file_path_placeholder','$valid_path',g' \
    )    
}

##############################
# get user confirmation before executing the file_specific_command
# the absolute path to the plaintext file is passed in.
# user does visual check of the command string.
function check_file_specific_encryption_command() {
	valid_path="$1"
    echo && echo -e "\033[1;34m===specific command string===\033[0m" 
	echo && echo "$file_specific_command" && echo
    responses_string='Yes, looks good. Encrypt it.|No, Quit the Program'
    # get user decision whether command is good.
    question_string='Does that command look good? OK to encrypt? Choose an option'
    get_user_response "$question_string" "$responses_string"
    # 1: yes, 2: no
    user_response_code="$?"
	# affirmative case
	if [ "$user_response_code" -eq 1 ]; then
		echo && echo -e "\e[32mEncrypting file...\e[m" && echo
	else
		# negative case || unexpected case
		exit 0
	fi	
}

##############################
# the absolute path to the plaintext file is passed in
function execute_file_specific_encryption_command() {
	valid_path="$1"


}












##############################
# test for encrypted file type
# test for read access to file 
# 
function verify_file_encryption_results() {

	valid_path="$1"

	# TODO: FIND SOME BETTER TESTS FOR A GPG ENCRYPTED FILE
	result=$(file "${valid_path}.ENCRYPTED${output_file_extension}" | grep 'PGP') # &2>/dev/null)

	if [ $? -eq 0 ] && [ "$encryption_system" == "public_key" ]
	#if [ $result -eq 0 ]
	then
		echo "PUBLIC KEY ENCRYPTED FILE CREATED SUCCESSFULLY AS:"
		echo "${valid_path}.ENCRYPTED${output_file_extension}"
	elif [ $? -eq 0 ] && [ "$encryption_system" == "symmetric_key" ]
	then
		echo "SYMMETRIC KEY ENCRYPTED FILE CREATED SUCCESSFULLY AS:"
		echo "${valid_path}.ENCRYPTED${output_file_extension}"
	else
		return $E_INCORRECT_FILE_TYPE #		
	fi

	
	# test encrypted file for expected file type (regular) and read permission
	# TODO: THIS SHOULD BE ONE FOR THE lib10k_test_file_path_access FUNCTION
	if [ -f "${valid_path}.ENCRYPTED${output_file_extension}" ] \
	&& [ -r "${valid_path}.ENCRYPTED${output_file_extension}" ]
	then
		# encrypted file found and accessible
		echo "Encrypted file found to be readable" && echo
	else
		# -> exit due to failure of any of the above tests:
		echo "Returning from function ${FUNCNAME[0]} in script $(basename $0)"
		return $E_REQUIRED_FILE_NOT_FOUND
	fi


	return 0
}


##############################
# standard procedure once encrypted versions exits: remove the plaintext versions!
function shred_plaintext_files() {
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	echo "OK TO SHRED THE FOLLOWING PLAINTEXT FILE(S)?..." && echo

	# list the encrypted files:
	for valid_path in "${validated_files_array[@]}"
	do
		echo "${valid_path}"	
	done

	# for now, confirmation by pressing enter
	read

	# shred the plaintext file and verify its' removal
	for valid_path in "${validated_files_array[@]}"
	do
		shred -n 1 -ufv "${valid_path}"	
	done

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo
}

##############################
# test for removal of plaintext file(s)
# 
function verify_file_shred_results() {
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# :
	for valid_path in "${validated_files_array[@]}"
	do
		if [ -f "${valid_path}" ]
		then
			# failure of shred
			echo "FAILED TO CONFIRM THE SHRED REMOVAL OF FILE:"
			echo "${valid_path}" && echo
		else
			# success of shred
			echo "SUCCESSFUL SHRED REMOVAL OF FILE:"
			echo "${valid_path}" && echo

		fi
	done

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo
}



main "$@"; exit
