#!/bin/bash
# this function imports the json profile data and then structures
# it into the specific array profile needed by the file encryption functions
declare -a profile_keys_indexed_array=()
declare -A profile_key_value_assoc_array=()
declare -A user_question_assoc_array=()
chosen_profile_id=

function import_file_encryption_configuration () 
{
	echo "config_file_fullpath set to $config_file_fullpath"

	# NOTES ON THE jq PROGRAM:
	#==================  
	# the -r option returns unquoted, line-separated string
	# the -j option gives unquoted and no newline
	# no option gives quoted, line-separated strings

	# values that are returned by jq as 'concatenated strings to be arrayed' get an IFS.
	# single string values don't. 
	# conveniently, the same sed command is applied to both (all) cases though!
	# therefore, for consistent handling, everything is single-quoted.

	
	# IMPORT PROFILE KEY ATTRIBUTES FROM JSON AS A SINGLE IFS STRING:
	#=========================================

	profile_id_string=$(cat "$config_file_fullpath" | \
	jq -r '.[] | .profileID' \
	) 
	echo "profile_id_string:"
	echo -e "$profile_id_string"
	echo && echo

	# we'll put these keys into and indexed array, then loop over \
    # it to filter for each profile.
	profile_id_array=( $profile_id_string )
	echo "profile_id_array:"
	echo "${profile_id_array[@]}"
	echo && echo
	echo "profile_id_array size:"
	echo "${#profile_id_array[@]}"
	echo && echo

	for profile_id in "${profile_id_array[@]}"
	do
		echo "profile_id: $profile_id" && echo && echo
		store_profiles "$profile_id"
	done

	# get user preset profile choice | direct parameter input (implement later)
	get_user_profile_choice
	assign_chosen_profile_values 

}

##########################################################
# 
# store each retrieved profile as structured data in memory.
# this avoids going back to read from storage.
# use an indexed array to iterate and an assoc array for data var => value.
# need to contrive a "composite key" across these two arrays.
# indexed array:
#=========
#                   PK
# 0	=>	"1^^profile_name"
# 1	=>	"1^^profile_description"
# 2	=>	"1^^encryption_system"
#...
# 7	=>	"2^^profile_name"
# associative array:
#===========
#       FK
# "1^^profile_name"		 	 =>			"local admin"	
# "1^^profile_description"	=>			"local administration"
# "1^^encryption_system" =>			"public key"
#...
# "2^^profile_name"		 	 =>			"cloud partners"
function store_profiles()
{
	local id="$1"	
	# the unique profile identifier (aka profile_id)
	#id="${id}"
	echo -e "unique id to filter from JSON: $id"

	profile_name_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.profileName' \
	) 
	echo "profile_name_string:"
	echo -e "$profile_name_string"
	echo && echo

	primary_key_string="${id}^^profile_name"
	profile_keys_indexed_array+=( "${primary_key_string}" )
	profile_key_value_assoc_array["$primary_key_string"]="$profile_name_string"

    # While we're here, since we'll soon be asking the user
    # to select a profile_name, which we must then match with a
    # profileID, we should associate the two now.

    user_question_assoc_array["$profile_name_string"]="$id"

	###

	profile_description_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.profileDescription' \
	) 
	echo "profile_description_string:"
	echo -e "$profile_description_string"
	echo && echo

	primary_key_string="${id}^^profile_description"
	profile_keys_indexed_array+=( "${primary_key_string}" )
	profile_key_value_assoc_array["$primary_key_string"]="$profile_description_string"

	###

	encryption_system_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.encryptionSystem' \
	) 
	echo "encryption_system_string:"
	echo -e "$encryption_system_string"
	echo && echo

	primary_key_string="${id}^^encryption_system"
	profile_keys_indexed_array+=( "${primary_key_string}" )
	profile_key_value_assoc_array["$primary_key_string"]="$encryption_system_string"

	###

	output_file_format_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.outputFileFormat' \
	) 
	echo "output_file_format_string:"
	echo -e "$output_file_format_string"
	echo && echo

	primary_key_string="${id}^^output_file_format"
	profile_keys_indexed_array+=( "${primary_key_string}" )
	profile_key_value_assoc_array["$primary_key_string"]="$output_file_format_string"

	###

	sender_uid_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.senderUID' \
	) 
	echo "sender_uid_string:"
	echo -e "$sender_uid_string"
	echo && echo

	primary_key_string="${id}^^sender_uid"
	profile_keys_indexed_array+=( "${primary_key_string}" )
	profile_key_value_assoc_array["$primary_key_string"]="$sender_uid_string"

	###

	recipient_uid_list_string=$(cat "$config_file_fullpath" | \
	jq -j --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.recipientUIDList[]' | \
	sed "s/''/|/g" | sed "s/^'//" | sed "s/'$//" \
	) 
	echo "recipient_uid_list_string:"
	echo -e "$recipient_uid_list_string"
	echo && echo

	primary_key_string="${id}^^recipient_uid_list"
	profile_keys_indexed_array+=( "${primary_key_string}" )
	profile_key_value_assoc_array["$primary_key_string"]="$recipient_uid_list_string"

	###

}

##########################################################
function get_user_profile_choice()
{
    # First need to create an IFS separated string of responses to send to controller function
    # The response are the profile name values.
    for key in "${!user_question_assoc_array[@]}"
    do
        echo $key
        echo "${user_question_assoc_array[$key]}" # configured value in profile
        responses_string+="${key}|"
    done

    # remove the trailing IFS
    responses_string="${responses_string%'|'}"
    echo "$responses_string"



	#echo -e "\033[33mWHICH PROFILE TO RUN?\033[0m"  && echo
	#echo -e "\033[33mCHOOSE A PROFILE ID [1-"${#profile_id_array[@]}"].\033[0m" && echo

    # get users' decision on which of the profiles to use
    question_string='Which Profile to run? Choose an option'
	#responses_string='Yes, Download and Verify|No, Quit the Program'
    get_user_response "$question_string" "$responses_string"

    # the user_response_string now contains the value of one profileName field.
    echo "The user_response_string was set to: $user_response_string" && echo

    # we can now associate the string with an unique ProfileID using the user_question_assoc_array.
    # we set chosen_profile_id

    for key in "${!user_question_assoc_array[@]}"
    do
        if [ "$key" == "$user_response_string" ]
        then
            chosen_profile_id="${user_question_assoc_array[$key]}"
        fi
    done

    echo "The chosen_profile_id was set to: $chosen_profile_id" && echo

}

##########################################################
# indexed array:
#=========
#                   PK
# 0	=>	"1^^profile_name"
# 1	=>	"1^^profile_description"
# 2	=>	"1^^encryption_system"
#...
# 7	=>	"2^^profile_name"
# associative array:
#===========
#       FK
# "1^^profile_name"		 	 =>			"local admin"	
# "1^^profile_description"	=>			"local administration"
# "1^^encryption_system" =>			"public key"
#...
# "2^^profile_name"		 	 =>			"cloud partners"
#user_question_assoc_array["$profile_name_string"]="$id"
# use the  chosen_profile_id to assign profile property values to variables for the gpg encryption command
function assign_chosen_profile_values() 
{
    # so now we have the target profile id, we just need a jq filter
    # to get each property value of the object where :
    # profileID == chosen_profile_id



	# order of iteration is not important, so we just need the associative array.

	for key in "${!profile_key_value_assoc_array[@]}"
	do
		echo $key
		test_profile_id="${key%^^*}"
		echo "$test_profile_id"
		test_profile_property_name="${key#*^^}"
		echo "$test_profile_property_name"

		# test key for match with our chosen_profile_id
		if [ "$test_profile_id" -eq "$chosen_profile_id" ]
		then
			# assign values
			echo "MATCH, MATCH" && echo
			case $test_profile_property_name in
				'profile_name')		profile_name="${profile_key_value_assoc_array[$key]}"
					;;
				'profile_description')	profile_description="${profile_key_value_assoc_array[$key]}"
					;;
				'encryption_system')	encryption_system="${profile_key_value_assoc_array[$key]}"
					;;
				'output_file_format')	output_file_format="${profile_key_value_assoc_array[$key]}"
					;;
				'sender_uid')	sender_uid="${profile_key_value_assoc_array[$key]}"
					;;
		 		'recipient_uid_list')	OIFS=$IFS; IFS='|'
										recipient_uid_list=(
											${profile_key_value_assoc_array[$key]}
										)									
										IFS=$OIFS
					;;
				*) 		msg="Unrecognised profile property name. Exiting now..."
	  					lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
					;; 
			esac
		fi
	done
	
}