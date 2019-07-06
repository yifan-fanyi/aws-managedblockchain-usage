# Alex
# 2019.06.30
# Install Basic blockchain dependence
# AWS managedblockchain on Amazon Linux EC2 instance

echo "=========== set up blockchain dependence ==========="
    sudo yum install pip

echo "================== updating awscli ================="
    sudo -H pip install awscli --upgrade --ignore-installed six
echo "================== awscli updated =================="
echo ""

echo "================= installing docker ================"
    sudo yum update -y
    sudo yum install -y telnet
    sudo yum -y install emacs
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
echo "================= docker installed ================="
echo ""

echo "=================== check docker ==================="
    sudo docker version
echo ""

echo "============ installing docker-compose ============="
    sudo curl -L https://github.com/docker/compose/releases/download/1.20.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    sudo chmod a+x /usr/local/bin/docker-compose
    sudo yum install libtool -y
echo "============ docker-compose inastalled ============="
echo ""

echo "=============== check docker-compose ==============="
    sudo /usr/local/bin/docker-compose version
echo ""

echo "==================== install go ===================="
    wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
    tar -xzf go1.10.3.linux-amd64.tar.gz
    sudo mv go /usr/local
    sudo yum install libtool-ltdl-devel -y
    sudo yum install git -y
    rm go1.10.3.linux-amd64.tar.gz
echo "=================== go installed ==================="
echo ""

echo "===================== check go ====================="
    go version
echo ""

echo "============= export environment path =============="
    echo 'PATH=$PATH:$HOME/.local/bin:$HOME/bin' >> ~/.bashrc
    echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$GOROOT/bin:$PATH' >> ~/.bashrc
    echo 'export PATH=$PATH:/home/ec2-user/go/src/github.com/hyperledger/fabric-ca/bin' >> ~/.bashrc
    source ~/.bashrc

echo "================ installing fabric-ca =============="
    go get -u github.com/hyperledger/fabric-ca/cmd/...
    cd /home/ec2-user/go/src/github.com/hyperledger/fabric-ca
    git fetch
    git checkout release-1.2
    make fabric-ca-client
echo "================ fabric-ca installed ==============="
echo ""

echo "============== cloning fabric-samples =============="
    cd /home/ec2-user
    git clone https://github.com/hyperledger/fabric-samples.git --branch release-1.2
echo "=============== fabric-samples cloned =============="
echo ""

echo "================= get docker images ================"
    sudo /usr/local/bin/docker-compose -f docker-compose-cli.yaml up -d
echo "================= docker images got ================"
echo ""

echo "============ create the certificate file ==========="
    aws s3 cp s3://us-east-1.managedblockchain/etc/managedblockchain-tls-chain.pem  /home/ec2-user/managedblockchain-tls-chain.pem
    openssl x509 -noout -text -in /home/ec2-user/managedblockchain-tls-chain.pem
echo "============= certificate file created ============="
echo ""

echo "Next step is to enroll as admin user (Step 4.2 in AWS BC totural: https://docs.aws.amazon.com/managed-blockchain/latest/managementguide/managed-blockchain-mgmt.pdf) using:"
echo '  fabric-ca-client enroll \'
echo '      -u https://AdminUsername:AdminPassword@SampleCAEndpointAndPort \'
echo '      --tls.certfiles /home/ec2-user/managedblockchain-tls-chain.pem \'
echo '      -M /home/ec2-user/admin-msp'
echo '  cp -r admin-msp/signcerts admin-msp/admincerts'