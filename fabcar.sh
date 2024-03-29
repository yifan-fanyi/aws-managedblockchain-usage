# Alex
# 2019.06.26
# fabcar usage


###########################################################################
# network config
###########################################################################
# member id
export MSP=node id (org1)
# peer node endpoint
export PEER=peer endpoint (org1)
# orderer
export ORDERER=ordering service endpoint
# peer end point of another org
export PEERO=peer endpoint (org2)
###########################################################################
# channel config
###########################################################################
# name of new channel
export CHANNEL=channel name
###########################################################################
# chaincode config
###########################################################################
# chaincode name
export NAME=chaincode name
###########################################################################
# things generally do not need to change
###########################################################################
# admin pem path
export MSP_PATH=/opt/home/admin-msp
# client pem
export ORDERER_CA=/opt/home/managedblockchain-tls-chain.pem

function printHelp(){
    echo ""
    echo "This is a demo of using fabcar."
    echo "Using the following command on fabcar demo:"
    echo "  initial ledger:"
    echo "      initLedger"
    echo "  query all cars:"
    echo "      queryAllCars"
    echo "  to create a new car: "
    echo "      '{\"Args\":[\"createCar\",\"<key>\",\"<maker>\",\"<model>\",\"<color>\",\"<owner>\"]}'"
    echo "  to change the car owner:"
    echo "      '{\"Args\":[\"changeCarOwner\",\"<key>\",\"<newowner>\"]}'"
    echo ""
}

###########################################################################
# fabcar usage
###########################################################################
function initLedger(){    
    echo "======= init ledger on channel: $CHANNEL, chaincode: $NAME"
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer chaincode invoke \
            -C $CHANNEL \
            -n $NAME \
            -c '{"Args":["initLedger"]}' \
            --peerAddresses $PEER \
            --tlsRootCertFiles $ORDERER_CA \
            --peerAddresses $PEERO \
            --tlsRootCertFiles $ORDERER_CA \
            -o $ORDERER \
            --cafile $ORDERER_CA \
            --tls
}

function queryAllCars(){
    echo "======= query all cars on channel: $CHANNEL, chaincode: $NAME"
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer chaincode query \
            -C $CHANNEL \
            -n $NAME \
            -c '{"Args":["queryAllCars"]}'
}

function createCar(){
    echo "======= create new car on channel: $CHANNEL, chaincode: $NAME"
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer chaincode invoke \
            -C $CHANNEL \
            -n $NAME \
            -c $COMMAND \
            --peerAddresses $PEER \
            --tlsRootCertFiles $ORDERER_CA \
            --peerAddresses $PEERO \
            --tlsRootCertFiles $ORDERER_CA \
            -o $ORDERER \
            --cafile $ORDERER_CA \
            --tls
}

function changeCarOwner(){
    echo "======= change car owner on channel: $CHANNEL, chaincode: $NAME"
    docker exec \
        -e "CORE_PEER_TLS_ENABLED=true" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
        -e "CORE_PEER_ADDRESS=$PEER" \
        -e "CORE_PEER_LOCALMSPID=$MSP" \
        -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
        cli peer chaincode invoke \
            -C $CHANNEL \
            -n $NAME \
            -c $COMMAND \
            --peerAddresses $PEER \
            --tlsRootCertFiles $ORDERER_CA \
            --peerAddresses $PEERO \
            --tlsRootCertFiles $ORDERER_CA \
            -o $ORDERER \
            --cafile $ORDERER_CA \
            --tls
}

###########################################################################
COMMAND=$2
if [ "$1" == "initLedger" ]
then
    initLedger
elif [ "$1" == "queryAllCars" ]
then
    queryAllCars        
elif [ "$1" == "createCar" ]
then
    createCar
elif [ "$1" == "changeCarOwner" ]
then
    changeCarOwner
else
    echo "ERROE in using fabcar: no function named <$1>"
    printHelp
fi
###########################################################################