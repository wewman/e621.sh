#!/bin/bash

################### USAGE #################
##                                       ##
##   sh e621.sh tag1 tag2 -tag3 ...      ##
##                                       ##
###########################################

################### NOTES #################
##                                       ##
##            Note the -tag3.            ##
##                                       ##
##  This is if you want to exclude a tag ##
##                                       ##
##    For safety, you have to exclude    ##
##             more tags                 ##
##                                       ##
###########################################

################# EXAMPLE #################
##                                       ##
## sh e621.sh touhou -hat yellow_hair    ##
##                                       ##
##    This will download touhous with    ##
##        no hats and yellow hair        ##
##                                       ##
##      in the directory:                ##
##         touhou+-hat+yellow_hair       ##
##                                       ##
###########################################

############## POOL EXAMPLE ###############
##                                       ##
##      sh e621.sh <URL OF POOL>         ##
##                                       ##
##   This will create a directory with   ##
##       The name of the pool and        ##
##       download all the images in it.  ##
##                                       ##
##       TODO Name the images in order.  ##
##                                       ##
###########################################

# init clean
$(rm -f image_*)


# Take every parameter
input="$@"

url="$1"

# TODO Fix the naming issue with the pool comic downloads.
#       As they are not in order.

pool=$(echo "$url" | awk -F '/' '{print $4}')
if [[ "$pool" == "pool" ]]; then
    poolid=$(echo "$url" | awk -F '/' '{print $6}')
    poolname=$(curl -s "https://e621.net/pool/show.json?id=$poolid" \
        | jq ".name" \
        | cut -c2- \
        | rev \
        | cut -c2- \
        | rev
    )
    echo "$url"
    echo "$poolid"
    echo "$poolname"
    mkdir -p "$poolname"
else
    # Replace spaces with + to fit the URL
    tags="${input// /+}"

    # Appropriate directory
    #   though, if you put the tags in
    #   a different way, it will probably
    #   re-download the same stuff but in
    #   a different directory
    mkdir -p "$tags"
fi



echo Leeching everything with: "$tags"
echo Prepare yourself.

# Page number
pid=1

# Loop forever until break
while true; do

    # Display current page number
    #   but will get lost due to wget output
    echo -n "$pid" ' '

    # What it does:
    #  1 Gets the XML document with the given tags
    #  2 Greps out the line with file_url with its random
    #     numbers and directories so there are no duplicates
    #  3 Cuts the file_url=" from the beginning of every line
    #  4 Appends https: in the beginning of every line
    #  5 Put everything to a file so wget can download them
    #     NOTE Every file has 100 links
    #       due to Gelbooru's max limit being 100
    #       so, every 10 files is 1000 images downloaded

    if [[ "$pool" ]]; then
        get=$(curl -s "https://e621.net/pool/show.json?id=$poolid&page=$pid" \
            | jq ".posts[]? | .file_url" \
            | cut -c2- \
            | rev \
            | cut -c2- \
            | rev \
            | tee image_$pid.files
            )
    else
        get=$(curl -s "https://e621.net/post/index.json?tags=$tags&limit=325&page=$pid" \
            | jq ".[] | .file_url" \
            | cut -c2- \
            | rev \
            | cut -c2- \
            | rev \
            | tee image_$pid.files
            )
    fi

    # Check if the output is alive.
    if [[ ! ${get} ]]; then
        # If the output is empty (empty string)
        #   it will clean and break
        echo \nDone, no more files
        echo Cleaning...
        rm image_*
        break;
    else
        # Downloads the files to an appropriate directory
        if [[ "$pool" ]]; then
            wget -nc -P $poolname/ -c -i image_$pid.files
        else
            wget -nc -P $tags/ -c -i image_$pid.files
        fi

        # Increment and continue
        (( pid++ ))
        continue;
    fi

done
