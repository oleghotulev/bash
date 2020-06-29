#!/bin/bash

################### VARIABLES #########################

logs="/tmp/upgrade.log"
jm_root_dir="/var/videoconf"
jm_url="https://gl.gigacloud.ua/Serdiuk/jm/-/archive/master/jm-master.zip"
zip_name=$(echo "$jm_url" | awk -F "/" '{print $NF}')
jm_dir=$(echo "$jm_url" | awk -F "/" '{print $NF}' | sed 's/\.[^.]*$//')
jm_cfg_dir="$jm_root_dir/.jitsi-meet-cfg"
jm_env_file="$jm_root_dir/$jm_dir/.env"
http_proto="https"

read -p "Specify your domain name please: " domain_name
read -p "Specify admin email please: " admin_email
read -p "Do you want to enable HTTPS. Strongly recommended (yes/no): " https_enable

################### FUNCTIONS ########################

docker_install() {
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
}

docker_compose_install() {
    if [ ! -f /usr/local/bin/docker-compose ]; then
        curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
        chmod +x /usr/local/bin/docker-compose
        ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
}

jitsi_install() {
    if [ ! -d "$jm_root_dir" ]; then
        mkdir "$jm_root_dir"
        cd "$jm_root_dir" && wget -q "$jm_url" && unzip -o -q "$zip_name" && cd "$jm_dir"
        cp env.example .env
    fi

    if [ ! -d "$jm_cfg_dir" ]; then
        mkdir -p "$jm_cfg_dir"/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
    fi

    if [ "$https_enable" == "yes" ]; then
        echo "Encrypted"
        sed -i "s|CONFIG=.*|CONFIG=${jm_cfg_dir}|g" "$jm_env_file"
        sed -i "s|8000|80|g" "$jm_env_file"
##        sed -i "s|8443|443|g" "$jm_env_file"
        sed -i "s|.PUBLIC_URL=.*|PUBLIC_URL=https://${domain_name}|g" "$jm_env_file"
        sed -i "s|.LETSENCRYPT_DOMAIN=.*|LETSENCRYPT_DOMAIN=${domain_name}|g" "$jm_env_file"
        sed -i "s|.ENABLE_LETSENCRYPT=.*|ENABLE_LETSENCRYPT=1|g" "$jm_env_file"
        sed -i "s|.LETSENCRYPT_EMAIL=.*|${admin_email}|g" "$jm_env_file"
##        sed -i "s|.ENABLE_HTTP_REDIRECT=.*|ENABLE_HTTP_REDIRECT=1|g" "$jm_env_file"
    else
        sed -i "s|CONFIG=.*|CONFIG=${jm_cfg_dir}|g" "$jm_env_file"
        sed -i "s|8000|80|g" "$jm_env_file"
##        sed -i "s|8443|443|g" "$jm_env_file"
        sed -i "s|.PUBLIC_URL=.*|PUBLIC_URL=http://${domain_name}|g" "$jm_env_file"
    fi

    if [ "$?" -eq 0 ]; then
        cd "$jm_root_dir/$jm_dir"
        ./gen-passwords.sh
        docker-compose up -d

    else
        echo "Error with Jitsi installation occeured finish"
        exit 1
    fi
}

################### DOCKER INSTALL #####################

apt-get update && apt-get upgrade -y ##&& apt-get remove docker docker-engine docker.io containerd runc

if [ "$?" -eq 0 ]; then
    docker_install
    if [ "$?" -eq 0 ]; then
        docker_compose_install
    else
        echo "Cant install docker-compose because of docker not installed"
        exit 1
    fi
else
    echo "Error with Jitsi installation occured part1"
    exit 1
fi

################### JITSI INSTALL ######################

docker -v
if [ "$?" -eq 0 ]; then
    jitsi_install
else
    echo "Error with docker installation occured"
    exit 1
fi
