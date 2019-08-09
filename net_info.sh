# 2019.07.08
# enviroment varible needed for install.sh

# network
export NETWORKID=n-BH7I4RPOFZFHTE2YMWCMCXBDAY
export ORDERER=orderer.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30001

# ECS
export ECS=m-6D7DAUJX3ZB7PDRGPN7H4DQKUM
export ECSADMIN=ECS
export ECSADMINPASS=ECSadmin11
export ECSFABRICCA=ca.m-6d7daujx3zb7pdrgpn7h4dqkum.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30002
export ECSPEERA=nd-3o7cypddvvg73le7hz7b663r5y.m-6d7daujx3zb7pdrgpn7h4dqkum.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30005
#export ECSPEERB=nd-o3likaipjvgqpdbc33pgx4wcum.m-ykxeau5agze2dp35rxq4e6czxm.n-wizerkk7qbdirbcednaz3d2tzy.managedblockchain.us-east-1.amazonaws.com:30012

# CIS
export CIS=m-VO6B4BAF2BG5JC3FREEHMH22P4
export CISADMIN=CIS
export CISADMINPASS=CISadmin11
export CISFABRICCA=ca.m-vo6b4baf2bg5jc3freehmh22p4.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30003
export CISPEERA=nd-nmghh3xfmza7jbyklcncvpe73a.m-vo6b4baf2bg5jc3freehmh22p4.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30007
#export CISPEERB=nd-keidhslqkjfxjfrputmeaguiwe.m-ghqq3mstave7zd7wi72f4nafhy.n-wizerkk7qbdirbcednaz3d2tzy.managedblockchain.us-east-1.amazonaws.com:30007

# DAlab
export DAlab=m-MAZSHE6U7ZFNJMYV2MNTPQC46Q
export DAlabADMIN=CIS
export DAlabADMIN=CISadmin11
export DAlabFABRICCA=ca.m-mazshe6u7zfnjmyv2mntpqc46q.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30004
export DAlabPEERA=nd-bn6jib3vbngzze5itxevek3wxu.m-mazshe6u7zfnjmyv2mntpqc46q.n-bh7i4rpofzfhte2ymwcmcxbday.managedblockchain.us-east-1.amazonaws.com:30009
#export DAlabPEERB=nd-72utbl56orgltoyxhvd5onz364.m-zu3yggvaazhg3njjduzu4aluyu.n-wizerkk7qbdirbcednaz3d2tzy.managedblockchain.us-east-1.amazonaws.com:30016
###########################################################################
# network config
###########################################################################
export ORGNAME=CIS
# member id
export MSP=$CIS
# peer node endpoint
export PEERA=$CISPEERA
export PEERB=$CISPEERB
# fabric cert endpoint
export FABCA=$CISFRABRICCA
###########################################################################
# channel config
###########################################################################
# channel profile to be install
export PROFILENAMEA=CommonChannel
export PROFILENAMEB=ECSnCISChannel
export PROFILENAMEC=CISnDAChannel
# name of new channel
export CHANNELA=ecsncisnda
export CHANNELB=ecsncis
export CHANNELC=cisnda
###########################################################################
# chaincode config
###########################################################################
# chaincode version
export VERSION=v0
# chaincode name
export NAME=fabcar_3
# name of code folder
export CODE=fabcar
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

export PROFILENAME=$PROFILENAMEA
export PEER=$PEERA
export CHANNEL=$CHANNELA