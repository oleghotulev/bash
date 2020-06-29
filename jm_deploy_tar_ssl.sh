#!/bin/bash

################### VARIABLES #########################

logs="/tmp/jm_deploy.log"
jm_root_dir="/var/videoconf"
jm_url="https://gl.gigacloud.ua/Serdiuk/jm/-/archive/master/jm-master.tar"
tar_name=$(echo "$jm_url" | awk -F "/" '{print $NF}')
jm_dir=$(echo "$jm_url" | awk -F "/" '{print $NF}' | sed 's/\.[^.]*$//')
jm_cfg_dir="$jm_root_dir/.jitsi-meet-cfg"
jm_env_file="$jm_root_dir/$jm_dir/.env"
domain_name="$1"
admin_email="$2"

################### FUNCTIONS ########################

jitsi_install() {
    if [ ! -d "$jm_root_dir" ]; then
        mkdir "$jm_root_dir"
        cd "$jm_root_dir" && wget -q "$jm_url" && tar -xf "$tar_name" && cd "$jm_dir"
        cp env.example .env
    fi

    if [ ! -d "$jm_cfg_dir" ]; then
        mkdir -p "$jm_cfg_dir"/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
    fi


######################### HTTPS ########################
    sed -i "s|CONFIG=.*|CONFIG=${jm_cfg_dir}|g" "$jm_env_file"
    sed -i "s|8000|80|g" "$jm_env_file"
    sed -i "s|8443|443|g" "$jm_env_file"
    sed -i "s|.PUBLIC_URL=.*|PUBLIC_URL=https://${domain_name}|g" "$jm_env_file"
    sed -i "s|.LETSENCRYPT_DOMAIN=.*|LETSENCRYPT_DOMAIN=${domain_name}|g" "$jm_env_file"
    sed -i "s|.ENABLE_LETSENCRYPT=.*|ENABLE_LETSENCRYPT=1|g" "$jm_env_file"
    sed -i "s|.LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=${admin_email}|g" "$jm_env_file"
    sed -i "s|.ENABLE_HTTP_REDIRECT=.*|ENABLE_HTTP_REDIRECT=1|g" "$jm_env_file"


    if [ "$?" -eq 0 ]; then
        cd "$jm_root_dir/$jm_dir"
        ./gen-passwords.sh
        docker-compose up -d

    else
        echo "Error with Jitsi installation occeured finish"
        exit 1
    fi
}

################### JITSI INSTALL ######################

if [ -f "$logs" ]; then
    echo > "$logs"
else
    touch "$logs"
fi

docker -v > /dev/null

if [ "$?" -eq 0 ]; then
    jitsi_install
else
    echo "Error with gc-conf installation occured" >> logs
    exit 1
fi