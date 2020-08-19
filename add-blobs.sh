#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DOWNLOAD_FOLDER="$THIS_SCRIPT_DIR/.downloads"
ES_VERSION=7.9.0

plugin_blob_url_list=(\
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/analysis-kuromoji/analysis-kuromoji-${ES_VERSION}.zip \
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-s3/repository-s3-${ES_VERSION}.zip \
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-gcs/repository-gcs-${ES_VERSION}.zip \
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-azure/repository-azure-${ES_VERSION}.zip \
)

mkdir -p $DOWNLOAD_FOLDER/elasticsearch

pushd "$DOWNLOAD_FOLDER" 
    pushd elasticsearch
        curl -L -J https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}-no-jdk-linux-x86_64.tar.gz -o elasticsearch-${ES_VERSION}.tar.gz
    popd
    
    for blob_url in "${plugin_blob_url_list[@]}"; do
        filename=${blob_url##*/}
        folder_name=${filename%-*}
        
        mkdir -p "$folder_name"
        pushd "$folder_name"
            curl -L -J "$blob_url" -o "$folder_name-${ES_VERSION}.zip"
        popd
    done
    
    for file in $(find . -type f); do
        bosh add-blob --dir="$THIS_SCRIPT_DIR" ${file} ${file##\./}
    done
popd
