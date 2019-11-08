### last update 2019.08.19
# Current ChainCode and Data in experian account
Channel: `ecsncis`  
Chaincode: `experian`  
Version: `v0.2`  
Data:  
```
ApplicationId = “app1”
FurnisherId = “fur1” 
Pin start from “100000000” to “100001000” has about 1000 records (some may not exists)

ApplicationId = “app1”
FurnisherId = “fur2”
Pin start from  “110000000” to “110000500” has about 500 records (some may not exists)

ApplicationId = “app2”
FurnisherId = “fur1”
Pin start from  “110000500” to “110001000” has about 500 records (some may not exists)
```
Data example:
```
ApplicationId = 'app1'
FurnisherId = 'fur1'
Data:
{
    "ConsumerPii":{
        "Pin":"100000000",
        "Name":{
            "LastName":"Walker",
            "FirstName":"Edgar",
            "MiddleName":"Belinda",
            "GenerationCode":"XIII"
        },
        "Dob":"1990-01-27",
        "Ssn":"475115515",
        "CurrentAddress":{
            "Line1":"4154 Marlene Garden Suite 795",
            "Line2":"969",
            "City":"North Jeffrey",
            "State":"Minnesota",
            "ZipCode":"46320"
        }
    },
    "TradeStream":{
        "SubscriberCode":"650",
        "AccountNumber":"86495937353",
        "DateOpened":"2015-12-19",
        "AccountType":"checking",
        "AccountStatus":"activated",
        "AccountBalance":"-6945.798527382591",
        "StatusDate":"2017-10-29",
        "CreditorName":"Boyer-Moen Group",
        "PaymentHistory":[
            "2018-02-24-TxId-763747551",
            "2018-09-04-TxId-104811669",
            "2018-03-19-TxId-775447001",
            "2016-09-08-TxId-905190035",
            "2017-03-29-TxId-718227303",
            "2018-08-30-TxId-398763993",
            "2016-04-29-TxId-814091537",
            "2016-07-12-TxId-305511802",
            "2017-04-05-TxId-544286048",
            "2018-03-25-TxId-566300899",
            "2016-11-18-TxId-276101670",
            "2016-06-04-TxId-990069155",
            "2019-01-04-TxId-165485192",
            "2017-05-17-TxId-141501549",
            "2016-09-19-TxId-500516599",
            "2016-07-01-TxId-477455496"
            ]
        }
    }
}
```

# `experian.js`
Chain code for experian user case. This chaincode is for both private and public channel. Data filtering is based on organiztion and role of a user, which is defined in `hasPermission`, different role would give different query and invoke result. Chaincode based on Hyperledger fabric using Couchdb written in Node.js 8.10, keys for data reference in Couchdb is a composite key named `ECS-TS`, created by `stub.createCompositeKey` with `[Appliction ID, Furnisher ID, Pin, Subscriber Code]`.

Data stored on chain should have at least following structure:
```
{ ConsumerPii: {Pin: "must"}, TradeStream: {SubscriberCode: "must"} }
```

The `continuousToken` used in some chaincode function has the following structure:
```
{"attributes":[Appliction ID, Furnisher ID, Pin, Subscriber Code]}
```
export 
## Permission and filtering functions used in chaincode

### `hasPermission(org, role)`
Checks the org and role for specific requirements (can be customized).   
Defult: `admin` in `ECS` or `CIS` would have full access, while others can only quey for the non-pii data (except the Pin). 
```
org -> <string> organiztions the user belongs to  
role -> <string> role of this user  

return: <bool> (if has full access)
```

### `dateFiltering(data, startDate, endDate)`
Filtering data by data range return data in range `[startDate, endDate]`. Default: using `data.TradeStream.StatusDate` as reference (can be customized). If for querying all the data both startDate and endDate should be `"null"` which is a string. 
```
data -> <JSON object> consumer data (need to have <data.TradeStream.StatusDate> as default)  
startDate -> <string> start date  
endDate -> <string> end date  

return: <bool> (if data is in date range)  
```

### `PiiTrimFunction(org, role, data)`
Trim consumer data according to their role (can be customized). It will call `hasPermission` to check, if has permission, it would return whole data, otherwise it would only return pin and trade stream
```
org -> <string> organiztions the user belongs to  
role -> <string> role of this user  
data -> <string> consumer data 

return: <object> trimed data (if no full access) or raw data (if has full access) 
```

## Chaincode functions realized:
### `queryConsumerByFullKey(stub,  args)`
Query a consumer's information by full key. Result would be trimed based on org and role defined in `PiiTrimFunction`.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> pin  
args[5] -> <string> subscriber code  

return: <JSON string> consumer data
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByFullKey","ECS", "admin", "app1", "fur1", "pin1","sub1"]}'
```

### `queryConsumerByPin(stub,  args)`
Query a consumer's information from different subscriber. Result would be trimed based on org and role defined in `PiiTrimFunction`.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> pin  
args[5] -> <string> max records returns (if "null", using default 100)  
args[6] -> <JSON string or "null"> continuation token `{"attributes":[Appliction ID, Furnisher ID, Pin, Subscriber Code]}`. If "null", return all qualified records (may encounter exceed as a single query can only get 100 000 records).  
args[7] -> <string> start date (for query by date range), if not use "null".  
args[8] -> <string> end date (for query by date range), if not use "null".  

return: <JSON string> `{"data": query result, "continuationToken": continuation token}`, consumer data (would be trimed based on org and role and date range). If there data remaining "continuationToken" would contains key for next records (`[Appliction ID, Furnisher ID, Pin, Subscriber Code]`), else "null".
```
#### example usage from cli:
```
 docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByPin", "ECS", "admin", "app1", "fur1", "pin1","10","null", "2013-02-05", "2019-02-05"]}'

  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByPin", "ECS", "admin", "any", "any", "any", "10", "{\"attributes\":[\"app1\",\"fur1\",\"pin1\",\"any\"]}", \"null\", \"null\"]}'
```

### `changeConsumerPiiByFullKey(stub, args)`
Change an item in ConsumerPii to a new value. `Pin` cannot be modified.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> pin  
args[5] -> <string> subscriber ID  
args[6] -> <string> item to be changed  
args[7] -> <string> new value  

return: <JSON string> transaction success/fail message
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke \
      -C $CHANNEL \
      -n $NAME \
      --peerAddresses $PEER \
      --tlsRootCertFiles $ORDERER_CA \
      -o $ORDERER \
      --cafile $ORDERER_CA \
      --tls \
      -c '{"Args":["changeConsumerPiiByFullKey", "ECS", "admin", "app1", "fur1", "pin1", "sub1", "LastName", "NewName"]}'
```

### `createNewConsumerFromJson(stub,  args)`
Create a new consumer records on the blockchain with the composite key. Only the user from specific orgs and roles can execute this function. To view and modifiy permission, see `hasPermission`. If the same compoosite key exists on ledger, it would overwrite the corresponding data without given any warning. But you can use `queryHistoryByKey` to see the modification history for this key.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <JSON string> data  

return: <JSON string> transaction success/fail message
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke \
      -C $CHANNEL \
      -n $NAME \
      --peerAddresses $PEER \
      --tlsRootCertFiles $ORDERER_CA \
      -o $ORDERER \
      --cafile $ORDERER_CA \
      --tls \
      -c '{"Args":["createNewConsumerFromJson", "ECS", "admin", "app1", "fur1","{\"ConsumerPii\":{\"Pin\":\"pin3\"},\"TradeStream\":{\"SubscriberCode\":\"sub2\"}}"]}'
```

### `queryConsumerByFurnisherId(stub,  args)`
Query all consumer's information from one single funisher. Result would be trimed based on org and role defined in `PiiTrimFunction`.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> max records returns (if "null", using default 100)  
args[5] -> <JSON string or "null"> continuation token `{"attributes":[Appliction ID, Furnisher ID, Pin, Subscriber Code]}`. If "null", return all qualified records (may encounter exceed as a single query can only get 100 000 records).  
args[6] -> <string> start date (for query by date range), if not use "null".  
args[7] -> <string> end date (for query by date range), if not use "null".  

return: <JSON string> `{"data": query result, "continuationToken": continuation token}`, consumer data (would be trimed based on org and role). If there data remaining "continuationToken" would contains key for next records (`[Appliction ID, Furnisher ID, Pin, Subscriber Code]`), else "null".
```
#### example usage from cli:
```
 docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByFurnisherId","org", "role","app1", "fur1", "10","null","null","null"]}'

  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByFurnisherId","org", "role","any", "any", "10","{\"attributes\":[\"app1\",\"fur1\",\"any\",\"any\"]}",,"2013-02-05","2019-02-05"]}'
```

### `queryConsumerByAppId(stub,  args)`
Query all consumer's information from one single application. Result would be trimed based on org and role defined in `PiiTrimFunction`.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> max records returns (if "null", using default 100)  
args[4] -> <JSON string or "null"> continuation token `{"attributes":[Appliction ID, Furnisher ID, Pin, Subscriber Code]}`. If "null", return all qualified records (may encounter exceed as a single query can only get 100 000 records).  
args[5] -> <string> start date (for query by date range), if not use "null".  
args[6] -> <string> end date (for query by date range), if not use "null". 

return: <JSON string> `{"data": query result, "continuationToken": continuation token}`, consumer data (would be trimed based on org and role). If there data remaining "continuationToken" would contains key for next records (`[Appliction ID, Furnisher ID, Pin, Subscriber Code]`), else "null".
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByAppId","ECS", "admin", "app1", "10","null", "2013-02-05","2019-02-05"]}'

  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByAppId","ECS", "admin","any", "10","{\"attributes\":[\"app1\",\"any\",\"any\",\"any\"]}","2013-02-05","2019-02-05"]}'
```

### `changeTradeStreamByFullKey(stub, args)`
Change an item in ConsumerPii to a new value. `SubscriberCode` and  `PaymentHistory` (if contains) cannot be modified.
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> pin  
args[5] -> <string> subscriber ID  
args[6] -> <string> item to be changed  
args[7] -> <string> new value  

return: <JSON string> transaction success/fail message
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke \
      -C $CHANNEL \
      -n $NAME \
      --peerAddresses $PEER \
      --tlsRootCertFiles $ORDERER_CA \
      -o $ORDERER \
      --cafile $ORDERER_CA \
      --tls \
      -c '{"Args":["changeTradeStreamByFullKey", "ECS", "admin", "app1", "fur1", "pin1", "sub1", "AccountBalance", "100"]}'
```

### `addPaymentHistoryByFullKey(stub, args)`
Add a new payment history. 
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> pin  
args[5] -> <string> subscriber ID  
args[6] -> <string> new payment history  

return: <JSON string> transaction success/fail message
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke \
      -C $CHANNEL \
      -n $NAME \
      --peerAddresses $PEER \
      --tlsRootCertFiles $ORDERER_CA \
      -o $ORDERER \
      --cafile $ORDERER_CA \
      --tls \
      -c '{"Args":["addPaymentHistoryByFullKey", "ECS", "admin", "app1", "fur1","NewPayment"]}'
```

### `queryHistoryForKey(stub,  args)`
Query a consumer information's modification history by full key. 
```
args[0] -> <string> org of user  
args[1] -> <string> role of user  
args[2] -> <string> application ID  
args[3] -> <string> furnisher ID  
args[4] -> <string> pin  
args[5] -> <string> subscriber code  

return: <JSON string> consumer data (would be trimed based on org and role)
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryHistoryForKey","ECS", "admin", "app1", "fur1", "pin1","sub1"]}'
```

# `experian_logging.js`
It is used to realize auto logging on a logging channel (`logchannel` in our case) where every user is joined to this cannel and can have access to query the log info) when an invoke or query happens, and query for logging history by user name. The logging info is stored on chain using a composite key named `key1~key2` where `key1` represents the user name and `key2` is the time stamps.

### `writeLog(stub, args)`
```
args[0] -> <string>userName
args[1] -> <string>timeStamp
args[2] -> <string> logging info
```
It would be call by Lambda function after any operation on blockchain.
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode invoke \
      -C $CHANNEL \
      -n $NAME \
      --peerAddresses $PEER \
      --tlsRootCertFiles $ORDERER_CA \
      -o $ORDERER \
      --cafile $ORDERER_CA \
      --tls \
      -c '{"Args":["writeLog", "ECS", "2019-08-23", "{\"message\":\"This is the logging info.\"}"]}'
```

### `queryLogsByUser(stub, args)`
Query the operation history of a particular user on all the channels. 
```
args[0] -> user name
```
#### example usage from cli:
```
docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryLogsByUser","ECS"]}'
```