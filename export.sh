# Alex
# 2019.07.02
# export config for easy usage

###########################################################################
# network config
###########################################################################

# member id
echo 'export MSP=m-3JY7DW6NJZHFDC224IW5PMKQ2Q' >> ~/.bashrc

# peer node endpoint
echo 'export PEER=nd-whsha5e3ingixilyoialfxvicu.m-3jy7dw6njzhfdc224iw5pmkq2q.n-s7rkvp6y5jbh3lalkcewnqip4i.managedblockchain.us-east-1.amazonaws.com:30003' >> ~/.bashrc

# orderer
echo 'export ORDERER=orderer.n-s7rkvp6y5jbh3lalkcewnqip4i.managedblockchain.us-east-1.amazonaws.com:30001' >> ~/.bashrc

###########################################################################
# channel config
###########################################################################
# channel profile to be install
echo 'export PROFILENAME=TwoOrgChannel' >> ~/.bashrc

# name of new channel
echo 'export CHANNEL=c0702' >> ~/.bashrc

###########################################################################
# chaincode config
###########################################################################

# chaincode version
echo 'export VERSION=v0' >> ~/.bashrc

# chaincode name
echo 'export NAME=marb0702' >> ~/.bashrc

# name of code folder
echo 'echo CODE=marbles02_private' >> ~/.bashrc

###########################################################################
# things generally do not need to change
###########################################################################
# admin pem path
echo 'export MSP_PATH=/opt/home/admin-msp' >> ~/.bashrc

# chaincode location .go
echo 'export CODEFOLDER=github.com/$CODE/go' >> ~/.bashrc

# chaincode location .js
echo 'export CODEFOLDERN=/opt/gopath/src/github.com/$CODE/node' >> ~/.bashrc

# client pem
echo 'export ORDERER_CA=/opt/home/managedblockchain-tls-chain.pem' >>~/.bashrc

source ~/.bashrc