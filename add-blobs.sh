#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DOWNLOAD_FOLDER="$THIS_SCRIPT_DIR/.downloads"
ES_VERSION=7.5.0

plugin_blob_url_list=(\
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/analysis-kuromoji/analysis-kuromoji-${ES_VERSION}.zip \
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-s3/repository-s3-${ES_VERSION}.zip \
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-gcs/repository-gcs-${ES_VERSION}.zip \
    https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-azure/repository-azure-${ES_VERSION}.zip \
)

mkdir -p $DOWNLOAD_FOLDER/{elasticsearch,elasticsearch-plugins}

pushd "$DOWNLOAD_FOLDER" 
    pushd elasticsearch
        curl -L -O -J https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}-no-jdk-linux-x86_64.tar.gz
    popd
    pushd elasticsearch-plugins
        for blob_url in "${plugin_blob_url_list[@]}"; do
            curl -L -O -J "$blob_url"
        done
    popd
    for file in $(find . -type file); do
        bosh add-blob --dir="$THIS_SCRIPT_DIR" ${file} ${file##\./}
    done
popd
