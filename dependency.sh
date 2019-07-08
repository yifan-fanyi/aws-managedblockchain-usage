# Alex
# 2019.06.30
# Install Basic blockchain dependence
# AWS managedblockchain on Amazon Linux EC2 instance

echo "=========== set up blockchain dependence ==========="
    sudo yum install pip

echo "================== updating awscli ================="
    sudo -H pip install awscli --upgrade --ignore-installed six
echo ""

echo "================= installing docker ================"
    sudo yum update -y
    sudo yum install -y telnet
    sudo yum -y install emacs
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
echo ""

echo "============ installing docker-compose ============="
    sudo curl -L https://github.com/docker/compose/releases/download/1.20.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    sudo chmod a+x /usr/local/bin/docker-compose
    sudo yum install libtool -y
echo ""

echo "==================== install go ===================="
    wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
    tar -xzf go1.10.3.linux-amd64.tar.gz
    sudo mv go /usr/local
    sudo yum install libtool-ltdl-devel -y
    sudo yum install git -y
    rm go1.10.3.linux-amd64.tar.gz
echo ""

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
echo ""

echo "============== cloning fabric-samples =============="
    cd /home/ec2-user
    git clone https://github.com/hyperledger/fabric-samples.git --branch release-1.2
echo ""

echo "================= get docker images ================"
    sudo /usr/local/bin/docker-compose -f docker-compose-cli.yaml up -d
echo ""

echo "Next step is Step 4 in AWS BC totural: https://docs.aws.amazon.com/managed-blockchain/latest/managementguide/managed-blockchain-mgmt.pdf"
