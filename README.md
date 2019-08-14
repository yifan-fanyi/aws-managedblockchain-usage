### Alex
### 2019.07.05
according to https://docs.aws.amazon.com/managed-blockchain/latest/managementguide/managed-blockchain-mgmt.pdf
before using these you need to have:
    a blockchain network in AWS managedblockchain 
        either one or two member with one peer each with VPC endpoint created
    EC2 instances with elastic IP
         both instances using same security group and region as totural mentioned

### dependency.sh
step 3
install the basic dependency of fabric
it is better to run

    source ~/.bashrc
before next step,
then run step 4.1

    aws s3 cp s3://us-east-1.managedblockchain/etc/managedblockchain-tls-chain.pem \
        /home/ec2-user/managedblockchain-tls-chain.pem
    openssl x509 -noout -text -in /home/ec2-user/managedblockchain-tls-chain.pem
step 4.2 and 4.3   

    fabric-ca-client enroll \
        -u https://$ADMINUSER:$ADMINPASS@$FABCA \
        --tls.certfiles /home/ec2-user/managedblockchain-tls-chain.pem \
        -M /home/ec2-user/admin-msp
    cp -r admin-msp/signcerts admin-msp/admincerts
aws configure may need to be complete before proceed to step 4.2

### install.sh
step 6 
create and join channel using environment varibales provided in export.sh
install chaincode in either node or go version
update chaincode (environment varibale should be updated as well)
instantiate chaincode

### fabcar.sh
demo of using fabcar
before starting, edit it to give the another member peer's endpoint
