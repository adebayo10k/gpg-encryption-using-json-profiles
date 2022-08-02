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
    exit 0 #debug

	create_generic_command_string

    # encrypt 

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
function create_generic_command_string() {


	if [ $output_file_format == 'ascii' ]
	then
		output_file_extension=".asc" #default
	elif [ $output_file_format == 'binary' ]
	then
		output_file_extension='.gpg'
	else
		msg="Fail. Exiting now..."
		lib10k_exit_with_error "$E_OUT_OF_BOUNDS_BRANCH_ENTERED" "$msg"
	fi	




	if [ $encryption_system == 'public_key' ]
	then
		echo "encrytion_system is set to public-key"
		encryption_system_option='--encrypt'

		create_generic_pub_key_encryption_command_string

	elif [ $encryption_system == 'symmetric_key' ]
	then
		echo "encrytion_system is set to symmetric-key"
		encryption_system_option='--symmetric'

		create_generic_symmetric_key_encryption_command_string

	else
		msg="FAIL. Exiting now..."
		lib10k_exit_with_error "$E_OUT_OF_BOUNDS_BRANCH_ENTERED" "$msg"
	fi

}



##############################
# this function called if encryption_system="public_key"
function create_generic_pub_key_encryption_command_string() {

	# THIS IS THE FORM:
	# $ gpg --armor --output "$plaintext_file_fullpath.ENCRYPTED.asc" \
	# --local-user <uid> --recipient <uid> --encrypt "$plaintext_file_fullpath"

	generic_command=

	generic_command+="${gpg_command} "

	if [ $output_file_format == 'ascii' ]
	then
		generic_command+="${armor_option} "
		generic_command+="${output_option} ${file_path_placeholder}.ENCRYPTED"
		generic_command+="${output_file_extension} "
	fi

	generic_command+="${sender_option} "
	generic_command+="${sender_uid} "

	for recipient in ${recipient_uid_list[@]}
	do
		generic_command+="${recipient_option} ${recipient} "
	done

	generic_command+="${encryption_system_option} ${file_path_placeholder}"

	echo "$generic_command"

}


##############################
# this function called if encryption_system="symmetric"
function create_generic_symmetric_key_encryption_command_string() {

	# COMMAND FORM:
	# $ gpg --armor --output "$plaintext_file_fullpath.ENCRYPTED.asc" --symmetric "$plaintext_file_fullpath"

	generic_command=

	generic_command+="${gpg_command} "

	if [ $output_file_format == 'ascii' ]
	then
		generic_command+="${armor_option} "
		generic_command+="${output_option} ${file_path_placeholder}.ENCRYPTED"
		generic_command+="${output_file_extension} "
	fi

	generic_command+="${encryption_system_option} ${file_path_placeholder}"

	echo "$generic_command"

}


##############################
function gpg_encrypt_files() {

	# sets the generic_command global
	# create a generic file encryption command string for either public key or symmetric key encryption:


	#create, then execute each file specific encryption command, then shred plaintext file:
	for valid_path in "${validated_files_array[@]}"
	do
		echo "about to execute on file: $valid_path"
		execute_file_specific_encryption_command "$valid_path" #

		# check that expected output file now exists, is accessible and has expected encypted file properties
		verify_file_encryption_results "${valid_path}"
		encrypt_result=$?
		if [ $encrypt_result -eq 0 ]
		then
			echo && echo "SUCCESSFUL VERIFICATON OF ENCRYPTION. encrypt_result: $encrypt_result"
		else
			msg="FAILURE REPORT. Unexpected encrypt_result: $encrypt_result. Exiting now..."
			lib10k_exit_with_error "$E_UNKNOWN_ERROR" "$msg"
		fi	
	done

	# 6. SHRED THE PLAINTEXT FILES, NOW THAT ENCRYPTED VERSION HAVE BEEN MADE

    shred_plaintext_files
	verify_file_shred_results

	#return $encrypt_result # resulting from the last successful encryption only! So what use is that?

}

##############################
# the absolute path to the plaintext file is passed in
#
function execute_file_specific_encryption_command() {

	valid_path="$1"

	# using [,] delimiter to avoid interference with file path [/]
	file_specific_command=$(echo "$generic_command" | sed 's,'$file_path_placeholder','$valid_path',' \
	| sed 's,'$file_path_placeholder','$valid_path',')

	echo "$file_specific_command"

	# get user confirmation before executing file_specific_command
	# [call a function for this, which can abort the whole encryption process if there's a problem at this point]
	echo && echo "Command look OK? Press ENTER to confirm"
	read	# just pause here for now

	# execute file_specific_command if return code from user confirmation = 0
	# execute [here] using bash -c ...
	bash -c "$file_specific_command"

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
