#!/bin/bash

allfiles_path="/tmp/jarfiles.txt"

read -p "Enter repository name (for example fc-releases): " repo_name
read -p "Enter group id (for example com.worldapp.fc): " group_id
read -p "Enter artifact id (for example api): " artifact_id
read -p "Enter extension of file (jar, war, etc..): " extension_id
read -p "Specify ('true' or 'false') do you need to generate the .pom file: " pom_need
read -p "Enter username for connection: " usrname
read -sp "Password for connection: " usrpasswd

base_path="/data/sonatype-work/nexus/storage"
addpath=$(echo "$group_id" | sed 's/\./\//g')
searchpath="$base_path""/""$repo_name""/""$addpath""/""$artifact_id"
host_trgt="https://nexus.ssstest.com/nexus"


echo "Target host is ""$host_trgt"
echo
echo "Searching files in "$searchpath" ..."

find "$searchpath" -name "*.$extension_id" > /tmp/jarfiles.txt

while IFS= read -r item
do

    IFS='/' read -r -a allfile_path_arr <<< "$item"
    version_id="${allfile_path_arr[${#allfile_path_arr[@]}-2]}"
    file_name="$item"

    curl -v -u "$usrname":"$usrpasswd" -F maven2.groupId="$group_id" -F maven2.artifactId="$artifact_id" -F maven2.version="$version_id" -F maven2.asset1=@"$file_name" -F maven2.asset1.extension="$extension_id" -F maven2.generate-pom="$pom_need" "$host_trgt""/service/rest/v1/components?repository=""$repo_name"

done < "$allfiles_path"
