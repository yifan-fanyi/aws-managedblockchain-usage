# 2019.07.08
# enviroment varible needed for install.sh

# network
export NETWORKID=<network ID (n-)>
export ORDERER=<orderer ID (orderer-)>

# org1
export ORGNAME=<member ID (m-)>
export ADMIN=<admin name>
export ADMINPASS=<admin password>
export FABCA=<peer client address begin with (ca-)>
export PEER=<peer endpoin (n-)>

export MSP=$ORG
###########################################################################
# channel config
###########################################################################
# channel profile to be install
export PROFILENAME=<name of channel profile>
# name of new channel
export CHANNEL=<channel name>
###########################################################################
# chaincode config
###########################################################################
# chaincode version
export VERSION=<version>
# chaincode name
export NAME=<installed chaincode name>
# name of code folder in ~/fabric-samples/chaincode/
export CODE=<code folder name>
###########################################################################
# things generally do not need to change
###########################################################################
# admin pem path
export MSP_PATH=/opt/home/$ORGNAME-msp
# chaincode location .go
export CODEFOLDER=github.com/$CODE/go
# chaincode location .js
export CODEFOLDERN=/opt/gopath/src/github.com/$CODE/node
# client pem
export ORDERER_CA=/opt/home/managedblockchain-tls-chain.pem
