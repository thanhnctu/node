#!/bin/bash
set -e

# Import utilities.
source ./scripts/utils.sh

# Common variables.
INITIALIZED_FLAG=/shared/initialized.txt
BEDROCK_JWT_PATH=/shared/jwt.txt
GETH_DATA_DIR=$BEDROCK_DATADIR
TORRENTS_DIR=/torrents/$NETWORK_NAME
BEDROCK_TAR_PATH=/downloads/bedrock.tar
BEDROCK_TMP_PATH=/bedrock-tmp

# Exit early if we've already initialized.
if [ -e "$INITIALIZED_FLAG" ]; then
  echo "Bedrock node already initialized"
  exit 0
fi

echo "Bedrock node needs to be initialized..."
echo "Initializing via download..."

# Fix OP link with hardcoded official OP snapshot
echo "Fetching download link..."

if [ "$NODE_TYPE" = "archive" ]; then
  if [ "$NETWORK_NAME" = "ink-sepolia" ]; then
    SNAPSHOT_FILENAME=$(curl -s https://storage.googleapis.com/raas-op-geth-snapshots-d2a56/datadir-archive/latest)
    BEDROCK_TAR_DOWNLOAD="https://storage.googleapis.com/raas-op-geth-snapshots-d2a56/datadir-archive/$SNAPSHOT_FILENAME"
    echo "Using snapshot file: $SNAPSHOT_FILENAME"
  elif [ "$NETWORK_NAME" = "ink-mainnet" ]; then
    SNAPSHOT_FILENAME=$(curl https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/latest)
    BEDROCK_TAR_DOWNLOAD="https://storage.googleapis.com/raas-op-geth-snapshots-e2025/datadir-archive/$SNAPSHOT_FILENAME"
    echo "Using snapshot file: $SNAPSHOT_FILENAME"
  fi
fi

if [ -n "$BEDROCK_TAR_DOWNLOAD" ]; then
  if [[ "$BEDROCK_TAR_DOWNLOAD" == *.zst ]]; then
    BEDROCK_TAR_PATH+=".zst"
  elif [[ "$BEDROCK_TAR_DOWNLOAD" == *.lz4 ]]; then
    BEDROCK_TAR_PATH+=".lz4"
  fi

  echo "Downloading bedrock.tar..."
  download $BEDROCK_TAR_DOWNLOAD $BEDROCK_TAR_PATH

  echo "Extracting bedrock.tar..."
  if [[ "$BEDROCK_TAR_DOWNLOAD" == *.zst ]]; then
    extractzst $BEDROCK_TAR_PATH $GETH_DATA_DIR
  elif [[ "$BEDROCK_TAR_DOWNLOAD" == *.lz4 ]]; then
    extractlz4 $BEDROCK_TAR_PATH $GETH_DATA_DIR
  else
    extract $BEDROCK_TAR_PATH $GETH_DATA_DIR
  fi

  # Remove tar file to save disk space
  rm $BEDROCK_TAR_PATH
fi

echo "Creating JWT..."
mkdir -p $(dirname $BEDROCK_JWT_PATH)
openssl rand -hex 32 > $BEDROCK_JWT_PATH

echo "Creating Bedrock flag..."
touch $INITIALIZED_FLAG
