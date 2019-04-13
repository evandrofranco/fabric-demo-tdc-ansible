#!/bin/bash

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

# Ask user for confirmation to proceed
function askProceed () {
  read -p "Continue (y/n)? " ans
  case "$ans" in
    y|Y )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}


# Generates Org certs using cryptogen tool
function generateCerts (){
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"
  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  cryptogen generate --config=./crypto-config-blk.yaml
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelArtifacts() {
  
  if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
  fi
  
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for BrinksMSP   ##########"
  echo "#################################################################"
  configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/BrinksMSPanchors.tx -channelID $CHANNEL_NAME -asOrg BrinksMSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for BrinksMSP..."
    exit 1
  fi
  echo

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for ProtegeMSP   ##########"
  echo "#################################################################"
  configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ProtegeMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ProtegeMSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for ProtegeMSP..."
    exit 1
  fi
  echo

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for ProsegurMSP   ##########"
  echo "#################################################################"
  configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ProsegurMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ProsegurMSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for ProsegurMSP..."
    exit 1
  fi
  echo
  
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
#default for delay
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"

EXPMODE="Generating certs and genesis block for"

# Announce what was requested

echo "${EXPMODE} with channel '${CHANNEL_NAME}' and CLI timeout of '${CLI_TIMEOUT}'"

# ask for confirmation to proceed
askProceed

# generate crypto-material
generateCerts
generateChannelArtifacts
