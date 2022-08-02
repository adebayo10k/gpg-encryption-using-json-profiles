#!/bin/bash
# these functions import the json profile data and then structures
# it into the specific array profile needed by program file encryption functions
profile_name=
profile_description=
encryption_system= # public_key | symmetric_key
output_file_format= # ascii | binary
sender_uid=    
declare -a recipient_uid_list=()
declare -A user_question_assoc_array=()
chosen_profile_id=

function import_file_encryption_configuration () 
{
	#echo "config_file_fullpath set to $config_file_fullpath"

	# NOTES ON THE jq PROGRAM:
	#==================  
	# the -r option returns unquoted, line-separated string
	# the -j option gives unquoted and no newline
	# no option gives quoted, line-separated strings

	# values that are returned by jq as 'concatenated strings to be arrayed' get an IFS.
	# single string values don't. 
	# conveniently, the same sed command is applied to both (all) cases though!
	# therefore, for consistent handling, everything is single-quoted.

	#=========================================

    # First, we just filter for the unique profileID value of each profile object.
	profile_id_string=$(cat "$config_file_fullpath" | \
	jq -r '.[] | .profileID' \
	) 

	# we'll put these keys into and indexed array,
    # then loop over it to filter for each profile object,
    # then each profileName.
	profile_id_array=( $profile_id_string )    	
    for profile_id in "${profile_id_array[@]}"
	do
		bind_name_to_id "$profile_id"
	done

	# get user preset profile choice
	get_user_profile_choice
    # assign json property values to program variables
	assign_profile_values_to_variables "$chosen_profile_id"
}

##########################################################
# for each profileID, bind the user-question-friendly profileName
#create the user_question_assoc_array
function bind_name_to_id() {
	local id="$1"	
	profile_name_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$id" '.[] |
	select(.profileID==$profile_id) |
	.profileName' \
	) 

    user_question_assoc_array["$profile_name_string"]="$id"
}

##########################################################
# calls a controller function to get the user response.
function get_user_profile_choice() {
    # First need to create an IFS separated string of responses to send to controller function
    # The response are the profileName values.
    for key in "${!user_question_assoc_array[@]}"
    do
        # use pipe operator for string separation
        responses_string+="${key}|"
    done

    # remove the trailing IFS
    responses_string="${responses_string%'|'}"

    # get users' decision on which of the profiles to use
    question_string='Which JSON Profile to use for the encryption? Choose an option'
    get_user_response "$question_string" "$responses_string"

    # the user_response_string now contains the value of one profileName field.
    # we can now associate the user_response_string with an unique ProfileID
    # using the user_question_assoc_array.
    for key in "${!user_question_assoc_array[@]}"
    do
        if [ "$key" == "$user_response_string" ]
        then
            chosen_profile_id="${user_question_assoc_array[$key]}"
        fi
    done
}

##########################################################
# use the  chosen_profile_id to assign all profile property values to variables for the gpg encryption command
function assign_profile_values_to_variables() {
    local id="$chosen_profile_id"	
    # so now we have the 'target' profile id, we just need jq filters
    # to get each property value of the object where :
    # profileID == chosen_profile_id

    profile_name_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$chosen_profile_id" '.[] |
	select(.profileID==$profile_id) |
	.profileName' \
	) 

	profile_description_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$chosen_profile_id" '.[] |
	select(.profileID==$profile_id) |
	.profileDescription' \
	) 

	encryption_system_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$chosen_profile_id" '.[] |
	select(.profileID==$profile_id) |
	.encryptionSystem' \
	) 

	output_file_format_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$chosen_profile_id" '.[] |
	select(.profileID==$profile_id) |
	.outputFileFormat' \
	) 

	sender_uid_string=$(cat "$config_file_fullpath" | \
	jq -r --arg profile_id "$chosen_profile_id" '.[] |
	select(.profileID==$profile_id) |
	.senderUID' \
	) 

	recipient_uid_list_string=$(cat "$config_file_fullpath" | \
	jq -j --arg profile_id "$chosen_profile_id" '.[] |
	select(.profileID==$profile_id) |
	.recipientUIDList[]' | \
	sed "s/''/|/g" | sed "s/^'//" | sed "s/'$//" \
	) 

    # Finally, assign JSON values to the appropriate program variable.
    profile_name="$profile_name_string"
    profile_description="$profile_description_string"
    encryption_system="$encryption_system_string"
    output_file_format="$output_file_format_string"
    sender_uid="$sender_uid_string"
    #OIFS=$IFS; IFS='|'
    #recipient_uid_list=( $recipient_uid_list_string )
    #IFS=$OIFS
	recipient_uid_list="$recipient_uid_list_string"
	
}

