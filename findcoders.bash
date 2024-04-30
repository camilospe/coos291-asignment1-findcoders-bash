#!/bin/bash
###
#
#Coos291 Asignment 1
#
#Name: Camilo Silva G
#
#
#This program will display the information of each programmer of certain language in your system
#Will display the user information and number of lines they have inside of their directories recursevly
#will only count the lines in files of the correct extension

###
#This function will arrange gather the information of each user and display the table
#This function will skip the first 49 users on passwd (in my systems they were the defaults)
#This apprach was used in order to skip issues with permissions
show_users() {
    #Recieve the argunments
    local filter_user=$1
    local min_lines=$2
    local filter_ext=$3
    
    # get the user info in /etc/passwd    
    userInfo=$(tail -n +49 /etc/passwd | grep -o '^[^:]*')
    
    #if there is a filter, will use grip on the previous user info
    if [ -n "$filter_user" ]; then
        userInfo=$(echo "$userInfo" | grep "$filter_user")
    fi

    printf "%-20s %-20s %-20s %-20s\n" User Group Home Lines
    echo "----------------------------------------------------------------------"
    for user in $userInfo
    do
	#gather the elements for the table
        uid=$(grep "^$user:" /etc/passwd | cut -d: -f3)
        userUid="${user}(${uid})"
        home=$(grep "^$user:" /etc/passwd | cut -d: -f6)
        gid=$(grep "^$user:" /etc/passwd | cut -d: -f4)

	#gather the group info from the /etc/group using grep with the gid
        group=$(grep ":x:$gid:" /etc/group | cut -d: -f1)
	
	#count the number of lines using the function
        if [ -n "$filter_ext" ]; then
            lines=$(lines_in_directory "$home" "$filter_ext")
        else
            lines=$(lines_in_directory "$home")
        fi
	
	#only display the users with the line count according to the minimum
        if [ "$lines" -ge "$min_lines" ]; then
            printf "%-20s %-20s %-20s %-20s\n" "$userUid" "$group" "$home" "$lines"
        fi
    done
}

###
#This function will count the lines in a file
#Later I learnt about the command wc....
#that's life I guess
lines_in_file() {
    local lines=0
    local filepath="$1"

    if [ -r "$filepath" ]; then
        while IFS= read -r line; do
            ((lines++))
        done < "$filepath"
    else
        echo 0
        return
    fi

    echo "$lines"
}

###
#this function will count the total number of lines in a directory and in the subdirectories
#it will filter the files according to the extension
#by default it checks for the .java extension
#user may ask for a different one using -e option
lines_in_directory() {
    local directory=$1 #the directory path
    local ext=$2  # The file extension to filter by
    local total_lines=0

    if [ -d "$directory" ] && [ -r "$directory" ]; then
        local list_files
	#gather the list of files in the directory with the correct extension 
        list_files=$(find "$directory" -type f -name "*$ext" 2>/dev/null)
	
	#for each valid file count the number of line and add it up
        for filepath in $list_files; do
            if [ -f "$filepath" ] && [ -r "$filepath" ]; then
                total_lines=$((total_lines + $(lines_in_file "$filepath")))
            fi
        done
    fi
    echo "$total_lines"  # Output the total number of lines
}


#default argument which can be altered by the user with options
userArg=""
minLines=1
extArg=".java"

while getopts ":hk:u:m:e:" opt; do
    case $opt in
        h)
	    echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h           Display this help message and exit."
            echo "  -u USERNAME  Filter the output by USERNAME."
            echo "  -m MIN_LINES Set a minimum line count for filtering users. Default is 1."
            echo "  -e EXTENSION Filter files by the given EXTENSION. Default is '.java'."
            echo "               Include the dot '.' in the EXTENSION if needed. But should work without"
            exit 0
            ;;
        k)
            echo "Option -k with argument '$OPTARG'"
            ;;
        u)
            userArg="$OPTARG"
            ;;
        m)
            minLines=$OPTARG
            ;;
        e)
            extArg="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument. please call -h for more information" 
            exit 1
            ;;
    esac
done

#call the show user function with the parameters after being altered
show_users "$userArg" "$minLines" "$extArg"

shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
    echo "Non-option arguments: $*"
fi

