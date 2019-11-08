// last update 2019.08.21

'use strict';
const shim = require('fabric-shim');
const util = require('util');

let MAX_FURNISHER_ID = "~";
let MAX_PIN = "~";
let MAX_SUBSCRIBER_ID = "~";

function hasPermission(org, role){
  // check permission
  if ((org == "ECS" || org == "CIS") && role == "admin"){
    return true;
  }
  return false;
}

function dateFiltering(data, startDate, endDate){
  // filtering by date according to role
  if (startDate == "null" && endDate == "null"){
    return true;
  }
  else if(startDate == "null" && data.TradeStream.StatusDate <= endDate){
    return true;
  }
  else if(endDate == "null" && data.TradeStream.StatusDate >= startDate){
    return true;
  }
  else if(startDate <= data.TradeStream.StatusDate && endDate >= data.TradeStream.StatusDate){
    return true;
  }
  return false;
}

function PiiTrimFunction(org, role, data){
  // what pii to return
  if (hasPermission(org, role) == true){
    return data;
  }
  let newData = {"ConsumerPii":{"Pin":"null"}, "TradeStream":"null"};
  newData.ConsumerPii.Pin = data.ConsumerPii.Pin;
  newData.TradeStream = data.TradeStream;
  return newData;
}

/**************************************************************************/
function ModifyItem(obj, item, val, flag){
  if(obj.hasOwnProperty(item)){
    flag.value = true;
    obj[item] = val;
    return;
  }
  var key_obj = Object.keys(obj);
  for(var i = 0; i < key_obj.length; i++){
    if(typeof(obj[key_obj[i]]) == 'object'){
      ModifyItem(obj[key_obj[i]], item, val, flag);
    }
  }
  return;
}
 
function stringToArray(bufferString){
  var util= require('util');
  let uint8Array = new util.TextEncoder("utf-8").encode(bufferString);
  return uint8Array;
}

async function getResultFromIterator(stub, iterator, maxCount, org, role, callback){
  console.info('============= START : getResultFromIterator ===========');
  let res = [];
  let continuationToken;
  let tmpcount = 1;
  while(true){
    var responseRange = await iterator.next();
    if (!responseRange || !responseRange.value || !responseRange.value.key) {
      continuationToken = "null";
      await iterator.close();
      break;
    }
    if(tmpcount > maxCount){
      continuationToken = await stub.splitCompositeKey(responseRange.value.key);
      await iterator.close();
      break;
    }
    let jsonRes;
    try {
      jsonRes = JSON.parse(responseRange.value.value.toString('utf8'));
    } catch (err) {
      console.log(err);
      continue;
    }    
    if(callback(jsonRes) != true){
      continue;
    }
    
    res.push(PiiTrimFunction(org, role, jsonRes));
    tmpcount++;
  }
  let result = JSON.stringify({"data": res, "continuationToken": continuationToken});
  console.info('============= END : getResultFromIterator ===========');
  return stringToArray(result);
}

async function queryMultipleRecordsByKey(stub, org, role, keys, maxCountstring, endKey, callback) {
  //    args[0] -> ['AppId', 'FurnisherId'] OR ['appId', 'FurnisherId', 'Pin', 'SubscriberCode']
  //    args[1] -> maxCount
  //    arg[2] -> EndKey {'AppId', 'FurnisherId', 'Pin', 'SubscriberCode'}, // can be null if using PartialKey
  //  returns {'data': '[{}, {}]}, 'continuationToken' : {}}
  console.info('============= START : queryMultipleRecordsByKey ===========');
  let maxCount;
  if(maxCountstring == "null"){
    maxCount = 100;
  }
  else{
    maxCount = parseInt(maxCountstring);
  }
  let iterator;
  if(keys.length == 4){
    let compositeKey = stub.createCompositeKey('ECS-TS', keys);
    let endCompositeKey = stub.createCompositeKey('ECS-TS', endKey);
    iterator = await stub.getStateByRange(compositeKey, endCompositeKey);
  }
  else{
    iterator = await stub.getStateByPartialCompositeKey('ECS-TS', keys); 
  }
  let result =  await getResultFromIterator(stub, iterator, maxCount, org, role, callback)
  console.info('============= END : queryMultipleRecordsByKey ===========');
  return result;
}
 
 /******************************* ChainCode **************************************/
let Chaincode = class {
  async Init(stub){
    let ret = stub.getFunctionAndParameters();
    console.info('=========== Instantiated chaincode ===========');
    return shim.success();
  }
 
  async Invoke(stub){
    let ret = stub.getFunctionAndParameters();
    console.info(ret);
    let method = this[ret.fcn];
    if (!method) {
      console.error('<Error> No function of name:' + ret.fcn + ' found');
      throw new Error('Received unknown function ' + ret.fcn + ' invocation');
    }
    try {
      let payload = await method(stub, ret.params);
      return shim.success(payload);
    } catch (err) {
      console.log(err);
      return shim.error(err);
    }
  }

  /*
  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByAppId","ECS", "admin", "app1", "10","null", "startDate","endDate"]}'

  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByAppId","ECS", "admin","any", "10","{\"attributes\":[\"app1\",\"any\",\"any\",\"any\"]}","startDate","endDate"]}'
  */
  async queryConsumerByAppId(stub, args){
    console.info('============= START : queryConsumerByAppId ===========');
    let org = args[0];
    let role = args[1];
    let appId = args[2];
    let maxCount = args[3]
    let continuation = args[4];
    let startDate = args[5];
    let endDate = args[6];

    let key, endKey
    if(continuation == "null"){
      key = [appId];
      endKey = null;
    }
    else{
      let continuationToken = JSON.parse(continuation);
      key = continuationToken["attributes"].slice(0);
      endKey = continuationToken["attributes"].slice(0);
      endKey[1] = MAX_FURNISHER_ID;
      endKey[2] = MAX_PIN;
      endKey[3] = MAX_SUBSCRIBER_ID;
    }
    let res = await queryMultipleRecordsByKey(stub, org, role, key, maxCount, endKey, (data) => dateFiltering(data, startDate, endDate));
    console.info('============= END : queryConsumerByAppId ===========');
    return res;
  }

   /*
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
      -c '{"Args":["queryConsumerByFurnisherId","org", "role","any", "any", "10","{\"attributes\":[\"app1\",\"fur1\",\"any\",\"any\"]}",,"startDate","endDate"]}'
  */
  async queryConsumerByFurnisherId(stub, args){
    console.info('============= START : queryConsumerByFurnisherId ===========');
    let org = args[0];
    let role = args[1];
    let appId = args[2];
    let furnisherId = args[3];
    let maxCount = args[4]
    let continuation = args[5];
    let startDate = args[6];
    let endDate = args[7];

    let key, endKey
    if(continuation == "null"){
      key = [appId, furnisherId];
      endKey = null;
    }
    else{
      let continuationToken = JSON.parse(continuation);
      key = continuationToken["attributes"].slice(0);
      endKey = continuationToken["attributes"].slice(0);
      endKey[2] = MAX_PIN;
      endKey[3] = MAX_SUBSCRIBER_ID;
    }
    let res = await queryMultipleRecordsByKey(stub, org, role, key, maxCount, endKey, (data) => dateFiltering(data, startDate, endDate));
    console.info('============= END : queryConsumerByFurnisherId ===========');
    return res;
  }
 
 /*
  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByPin", "ECS", "admin", "app1", "fur1", "pin1","10","null", "20190800", "201908010"]}'

  docker exec \
    -e "CORE_PEER_TLS_ENABLED=true" \
    -e "CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA" \
    -e "CORE_PEER_ADDRESS=$PEER" \
    -e "CORE_PEER_LOCALMSPID=$MSP" \
    -e "CORE_PEER_MSPCONFIGPATH=$MSP_PATH" \
    cli peer chaincode query \
      -C $CHANNEL \
      -n $NAME \
      -c '{"Args":["queryConsumerByPin","ECS", "admin", "any", "any", "any","10","{\"attributes\":[\"app1\",\"fur1\",\"pin1\",\"any\"]}",\"null\",\"null\"]}'
  */
  async queryConsumerByPin(stub,  args){
    console.info('============= START : queryConsumerByPin ===========');
    let org = args[0];
    let role = args[1];
    let appId = args[2];
    let furnisherId = args[3];
    let Pin = args[4];
    let maxCount = args[5]
    let continuation = args[6];
    let startDate = args[7];
    let endDate = args[8];

    let key, endKey;
    if(continuation == "null"){
      key = [appId, furnisherId, Pin];
      endKey = "null";
    }
    else{
      let continuationToken = JSON.parse(continuation);
      key = continuationToken["attributes"].slice(0);
      endKey = continuationToken["attributes"].slice(0);
      endKey[3] = MAX_SUBSCRIBER_ID;
    }
    let res = await queryMultipleRecordsByKey(stub, org, role, key, maxCount, endKey, (data) => dateFiltering(data, startDate, endDate));
    console.info('============= END : queryConsumerByPin ===========');
    return res;
  }
 
  /*
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
  */
  async queryConsumerByFullKey(stub, args) {
    // query consumer info by full key
    //  keys:
    //    args[0] -> ['org', 'role' appId', 'FurnisherId', 'Pin', 'SubscriberCode']
    //  returns consumer
    console.info('============= START : queryConsumerByFullKey ===========');
    let org = args[0];
    let role = args[1];
    let appId = args[2];
    let furnisherId = args[3];
    let Pin = args[4];
    let SubscriberCode = args[5];
    let compositeKey = await stub.createCompositeKey ('ECS-TS', [appId, furnisherId, Pin, SubscriberCode]);
    let consumerAsBytes = await stub.getState(compositeKey); 
    if (!consumerAsBytes || consumerAsBytes.toString().length <= 0) {
      console.info('<Error> Consumer does not exists.');
      throw new Error('Consumer does not exist.');
    }
    console.info('============= END : queryConsumerByFullKey ===========');
    return stringToArray(JSON.stringify(PiiTrimFunction(org, role, JSON.parse(consumerAsBytes))));
  }

  async queryHistoryForKey(stub, args) {
    console.log('============= START : queryHistoryForKey ===========');
    let org = args[0];
    let role = args[1];
    let appId = args[2];
    let furnisherId = args[3];
    let Pin = args[4];
    let SubscriberCode = args[5];
    let key = await stub.createCompositeKey ('ECS-TS', [appId, furnisherId, Pin, SubscriberCode]);
    let historyIterator = await stub.getHistoryForKey(key);
    let history = [];
    while (true) {
      let historyRecord = await historyIterator.next();
      if (historyRecord.value && historyRecord.value.value.toString()) {
        let jsonRes = {};
        jsonRes.TxId = historyRecord.value.tx_id;
        jsonRes.Timestamp = historyRecord.value.timestamp;
        jsonRes.IsDelete = historyRecord.value.is_delete.toString();
      try {
          jsonRes.Record = JSON.parse(historyRecord.value.value.toString('utf8'));
        } catch (err) {
          jsonRes.Record = historyRecord.value.value.toString('utf8');
        }
        jsonRes.Record = PiiTrimFunction(org, role, jsonRes.Record);
        history.push(jsonRes);
      }
      if (historyRecord.done) {
        await historyIterator.close();
        console.log('##### queryHistoryForKey all results: ' + JSON.stringify(history));
        console.log('============= END : queryHistoryForKey ===========');
        return Buffer.from(JSON.stringify(history));
      }
    }
  }
  
  /*
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
  */
  async createNewConsumerFromJson(stub, args){
    // create new consumers by passing a JSON object
    // example: {k1: Consumer, k2: Consumer}
    //    args[0] -> org
    //    args[1] -> role
    //    args[2] -> AppId
    //    args[3] -> FurnisherId
    //    args[4] -> JSON object
    console.info('============= START : createNewConsumersFromJson ===========');
    let org = args[0];
    let role = args[1];
    if(hasPermission(org,role) == false){
      throw new Error('No permission.');
    }
    let AppId = args[2];
    let FurnisherId = args[3];
    let consumerdata = JSON.parse(args[4]);
    if(!consumerdata.ConsumerPii.hasOwnProperty('Pin') || consumerdata.ConsumerPii.Pin == 'null' || !consumerdata.TradeStream.hasOwnProperty('SubscriberCode') || consumerdata.TradeStream.SubscriberCode == 'null'){
      console.log('<Error> Pin and SubscriberCode are must to create new consumer.');
      throw new Error('Consumer Pin and SubscriberCode are needed.');
    }
    let key = await stub.createCompositeKey('ECS-TS', [AppId, FurnisherId, consumerdata.ConsumerPii.Pin, consumerdata.TradeStream.SubscriberCode]); 
    await stub.putState(key, Buffer.from(JSON.stringify(consumerdata)));
    console.info('============= END : createNewConsumersFromJson ===========');
  }

  async changeConsumerPiiByFullKey(stub, args) {
    // change consumer pii info
    //    args[0] -> org
    //    args[1] -> role
    //    args[2] -> AppId
    //    args[3] -> FurnisherId
    //    args[4] -> Pin
    //    args[5] -> SubscriberCode
    //    args[6] -> Properity to be changed
    //    args[7] -> New value
    console.info('============= START : changeConsumerPiiByFullKey ===========');
    let org = args[0];
    let role = args[1];
    if(hasPermission(org,role) == false){
      throw new Error('No permission.');
    }
    let AppId = args[2];
    let FurnisherId = args[3];
    let Pin = args[4];
    let SubscriberCode = args[5];
    let item = args[6];
    let newVal = args[7];
    if(item == 'Pin'){
      console.log('<Error> Failed to modify item that cannot be modified <--> ', item);
      throw new Error('Can not modify this item');
    }
    let key = await stub.createCompositeKey('ECS-TS', [AppId, FurnisherId, Pin, SubscriberCode]);
    let consumerAsBytes = await stub.getState(key);
    if (!consumerAsBytes || consumerAsBytes.toString().length <= 0) {
      console.info('<Error> Consumer does not exist. key <--> ', key);
      throw new Error(key + ' does not exist in ledger.');
    }
    let consumer = JSON.parse(consumerAsBytes);
    let flag = {value: false};
    ModifyItem(consumer.ConsumerPii, item, newVal, flag);
    if(flag.value == false){
      console.info('<Error> Property <--> ', item, ' does not exist. key <-->', key);
      throw new Error(item + ' does not exist in data structure.');
    }
    await stub.putState(key, Buffer.from(JSON.stringify(consumer)));
    console.info('<Success> Changed <--> ', item, '. key <--> ', key);
    console.info('============= END : changeConsumerPiiByFullKey ===========');
  }
 
  async changeTradeStreamByFullKey(stub, args) {
    // change consumer's trade stream info
    //    args[0] -> org
    //    args[1] -> role
    //    args[2] -> AppId
    //    args[3] -> FurnisherId
    //    args[4] -> Pin
    //    args[5] -> SubscriberCode
    //    args[6] -> Properity to be changed
    //    args[7] -> New value
    console.info('============= START : changeTradeStreamByFullKey ===========');
    let org = args[0];
    let role = args[1];
    if(hasPermission(org,role) == false){
      throw new Error('No permission.');
    }
    let AppId = args[2];
    let FurnisherId = args[3];
    let Pin = args[4];
    let SubscriberCode = args[5];
    let item = args[6];
    let newVal = args[7];
    if(item == 'SubscriberCode' || item == 'PaymentHistory'){
      console.log('<Error> Failed to modify item that cannot be modified (Try to use <addPaymentHistoryById> if adding) <--> ', item);
      throw new Error('Can not modify this item');
    }
    let key = await stub.createCompositeKey('ECS-TS', [AppId, FurnisherId, Pin, SubscriberCode]);
    let consumerAsBytes = await stub.getState(key);
    if (!consumerAsBytes || consumerAsBytes.toString().length <= 0) {
      console.info('<Error> Consumer not exists. key <--> ', key);
      throw new Error(key + ' does not exist in ledger.');
    }
    let consumer = JSON.parse(consumerAsBytes);
    var flag = {value: false};
    ModifyItem(consumer.TradeStream, item, newVal, flag);
    if(flag.value == false){
      console.info('<Error> Property <--> ', item, ' does not exist. key <-->', key);
      throw new Error(item + ' does not exist in data structure.');
    }
    await stub.putState(key, Buffer.from(JSON.stringify(consumer)));
    console.info('<Success> Changed <--> ', item, '. key <--> ', key);
    console.info('============= END : changeTradeStreamByFullKey ===========');
  }
 
  async addPaymentHistoryByFullKey(stub, args) {
    // add payment history
    //    args[0] -> org
    //    args[1] -> role
    //    args[2] -> AppId
    //    args[3] -> FurnisherId
    //    args[4] -> Pin
    //    args[5] -> SubscriberCode
    //    args[6] -> New payment
    console.info('============= START : addPaymentHistoryByFullKey ===========');
    let org = args[0];
    let role = args[1];
    if(hasPermission(org,role) == false){
      throw new Error('No permission.');
    }
    let AppId = args[2];
    let FurnisherId = args[3];
    let Pin = args[4];
    let SubscriberCode = args[5];
    let newVal = args[6];

    let key = await stub.createCompositeKey('ECS-TS', [AppId, FurnisherId, Pin, SubscriberCode]); 
    let consumerAsBytes = await stub.getState(key);
    if (!consumerAsBytes || consumerAsBytes.toString().length <= 0) {
      console.info('<Error> Consumer not exists. Failed to add payment history <--> ', key);
      throw new Error(key + ' does not exist in ledger.');
    }
    let consumer = JSON.parse(consumerAsBytes);
    consumer.TradeStream.PaymentHistory.push(newVal);
 
    await stub.putState(key, Buffer.from(JSON.stringify(consumer)));
    console.info('<Success> Adde payment history. key <--> ', key);
    console.info('============= END : addPaymentHistoryByFullKey ===========');
  }
};
 
shim.start(new Chaincode());
 
 