# Alex
# 2019.07.05

# before using these you need to have:
### a blockchain network in AWS managedblockchain 
###     either one or two member with one peer each with VPC endpoint created
### EC2 instances with elastic IP
###     both instances using same security group and region as totural mentioned

# dependency.sh
### install the basic dependency of fabric
### it includes step 3.1 to step 4.1 in https://docs.aws.amazon.com/managed-blockchain/latest/managementguide/managed-blockchain-mgmt.pdf

# aws configure may need to be complete before proceed to step 4.2

# export.sh
### export some environment variables about network or chaincode
### member id or orderer can be derived either from CLI or managedblockchain console
### edit it before create a channel

# install.sh
### create and join channel using environment varibales provided in export.sh
### install chaincode in either node or go version
### update chaincode (environment varibale should be updated as well)
### instantiate chaincode

# fabcar
### demo of using fabcar
### before starting, edit it to give the another member peer's endpoint