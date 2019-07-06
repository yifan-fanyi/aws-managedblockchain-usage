# Alex
# 2019.06.27
# create, join channel
# install chaincode

function printHelp(){
    echo ""
    echo "Using the following command:"
    echo "  operation on channel:"
    echo "      channelList"
    echo "      chainCodeInstalledList"
    echo "      chainCodeInstantiatedList"
    echo "      createChannel"
    echo "      fetchBlock"
    echo "      joinChannel"
    echo "  quick create and join channel: <$CHANNEL> (org1 is channal creator):"
    echo "      org1"
    echo "      org2"
    echo "  operation on chaincode:"
    echo "      installChainCodeGo"
    echo "      upgradeChainCodeGo"
    echo "      installChainCodeNode"
    echo "      upgradeChainCodeNode"
    echo "      instantiateChainCode"
    echo ""
}

function run(){
    if [ "$1" == "createChannel" ]
    then
        createChannel
    elif [ "$1" == "fetchBlock" ]
    then
        fetchBlock
    elif [ "$1" == "joinChannel" ]
    then
        joinChannel
    elif [ "$1" == "channelList" ]
    then
        channelList
    elif [ "$1" == "chainCodeInstantiatedList" ]
    then
        chainCodeInstantiatedList
    elif [ "$1" == "chainCodeInstalledList" ]
    then
    chainCodeInstalledList
    elif [ "$1" == "installChainCodeGo" ]
    then
        installChainCodeGo
    elif [ "$1" == "upgradeChainCodeGo" ]
    then
        upgradeChainCodeGo
    elif [ "$1" == "installChainCodeNode" ]
    then
        installChainCodeNode
    elif [ "$1" == "upgradeChainCodeNode" ]
    then
        updateChainCodeGo
    elif [ "$1" == "instantiateChainCode" ]
    then
        instantiateChainCode
    elif [ "$1" == "org1" ]
    then
        org1
    elif [ "$1" == "org2" ]
    then
        org2
    else
        echo "ERROE: no function named <$1>"
        printHelp
    fi
}

###########################################################################
# channel
###########################################################################
function createChannel(){
    docker exec cli configtxgen \
        -outputCreateChannelTx /opt/home/"$CHANNEL".pb \
        -profile $PROFILENAME \
        -channelID $CHANNEL \
        --configPath /opt/home/
    echo "======= create $CHANNEL.pb"
    echo ""
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer channel create \
            -c $CHANNEL \
            -f /opt/home/"$CHANNEL".pb \
            -o $ORDERER \
            --cafile $ORDERER_CA \
            --tls
    echo "======= created channel: $CHANNEL using profile: $PROFILENAME"
    echo ""
}

function fetchBlock(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer channel fetch oldest /opt/home/"$CHANNEL".block \
            -c $CHANNEL \
            -o $ORDERER \
            --cafile $ORDERER_CA \
            --tls
    echo "======= fetched $CHANNEL.block"
    echo ""
}

function joinChannel(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer channel join \
            -b /opt/home/"$CHANNEL".block \
            -o $ORDERER \
            --cafile $ORDERER_CA \
            --tls
    echo "======= channel: $CHANNEL joined"
    echo ""
}

function channelList(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer channel list
}

function org1(){
    createChannel
    fetchBlock
    joinChannel
}

function org2(){
    fetchBlock
    joinChannel
}

###########################################################################
# chaincode
###########################################################################
function installChainCodeGo(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        cli peer chaincode install \
            -n $NAME \
            -v $VERSION \
            -p "$CODEFOLDER"
    echo "======= chaincode: $NAME version: $VERSION installed"
    echo ""
}

function upgradeChainCodeGo(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        cli peer chaincode upgrade \
            -o $ORDERER \
            -n $NAME \
            -C $CHANNEL \
            -c '{"Args":["init"]}' \
            -v $VERSION \
            -p "$CODEFOLDER"
            --tls \
            --cafile $ORDERER_CA
    echo "======= chaincode $NAME in channel: $CHANNEL upgraded"
    echo ""
}

function installChainCodeNode(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        cli peer chaincode install \
            -n $NAME \
            -v $VERSION \
            -l node \
            -p "$CODEFOLDERN"
    echo "======= chaincode: $NAME version: $VERSION installed"
    echo ""
}

function upgradeChainCodeNode(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        cli peer chaincode upgrade \
            -o $ORDERER \
            -n $NAME \
            -C $CHANNEL \
            -c '{"Args":["init"]}' \
            -l node \
            -v $VERSION \
            -p "$CODEFOLDERN"
            --tls \
            --cafile $ORDERER_CA
    echo "======= chaincode $NAME in channel: $CHANNEL upgraded"
    echo ""
}

function instantiateChainCode(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        cli peer chaincode instantiate \
            -o $ORDERER \
            -C $CHANNEL \
            -n $NAME \
            -v $VERSION \
            -c '{"Args":["init"]}' \
            --cafile $ORDERER_CA \
            --tls
    echo "======= chaincode $NAME version: $VERSION in channel: $CHANNEL instantiated"
    echo ""
}

function chainCodeInstalledList(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer chaincode list \
            --installed
    echo ""
}

function chainCodeInstantiatedList(){
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer chaincode list \
            --instantiated \
            -C $CHANNEL
    echo ""
}

###########################################################################
run
###########################################################################