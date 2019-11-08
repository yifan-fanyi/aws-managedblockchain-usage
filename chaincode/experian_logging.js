/*********************************************************************************************************
 * chaincode for the experian user case logging
 * share transactions between each orgs
 * 2019.07.31
 * last update: 2019.08.01.09.03
 * 
 * log is store on chain by the key User~TimeStamp
 * 
 * By adding the followin code to index.js in lambda can write the log
  let tim = (new Date).getTime().toString()
	let loginfo = {
		'User':username,
		'Org':orgName, 
		'Peer':peers, 
		'Channel':channelName, 
		'ChainCode':chaincodeName, 
		'fcn':fcn,
		'args':args,
		'TimeStamp':tim
	}
	let message1 = await invoke.invokeChaincode(peers, "logchannel", "experian_logcode", [username.toString(), tim.toString(), JSON.stringify(loginfo)], "writeLog", username, orgName);

  * for query logs:
  *   queryLogsByUser  
  *                 -> args[0]: UserName
 ********************************************************************************************************/
function stringToArray(bufferString) {
  /*
  // change string to uint8
  // chiancode requires return value encode as uint8
  */
  var util= require('util');
	let uint8Array = new util.TextEncoder("utf-8").encode(bufferString);
	return uint8Array;
}
/****************************************** start: chaincode *******************************************/
'use strict';
const shim = require('fabric-shim');
const util = require('util');

let Chaincode = class {
  async Init(stub){
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

  async writeLog(stub, args){
    console.info('============= START : writeLog ===========');

    let loginfostr = args[2];

    let key = await stub.createCompositeKey('key1~key2', [args[0], args[1]]);
    if (!key) {
      console.log('<Failed> Failed to create the createCompositeKey <--> key1~key2.');
      throw new Error('Failed to create the createCompositeKey');
    }
    await stub.putState(key, Buffer.from(JSON.stringify({"log":loginfostr})));
    console.info('<Success> Successfully logging <--> ', key);
    console.info('============= END : writeLog ===========');
  }
  
  async queryLogsByUser(stub, args){
   console.info('============= START : queryLogsByUser ===========');
   if (args.length != 1) {
     console.log('<Error> Incorrect number of arguments. Need 1, but got <--> ', args.length);
     throw new Error('Incorrect number of arguments.');
   }
   let User = args[0];
   let histAsBytesitor = await stub.getStateByPartialCompositeKey('key1~key2', [User]); 
   let hist = [];
   let count = 0;

   while(true){
     let responseRange = await histAsBytesitor.next();
     if (!responseRange || !responseRange.value || !responseRange.value.key) {
       await histAsBytesitor.close();
       break;
     }
     let jsonRes = {};
     jsonRes.Key = responseRange.value.key;
       try {
         jsonRes.Record = JSON.parse(responseRange.value.value.toString('utf8'));
       } catch (err) {
         console.log(err);
         jsonRes.Record = responseRange.value.value.toString('utf8');
       }
       hist.push(jsonRes);
     console.info('<Success> Query key1~key2 <--> ', responseRange.value.key);
     count++;
   }
   let res = JSON.stringify({'User': User, 'Logging history': hist});
   console.log('<Success> Query User <--> ', User, ' Logging history <--> ', hist);
   console.info('============= END : queryLogsByUser ===========');
   return stringToArray(res);
  }
};

/******************************************* end: chaincode **********************************************/

shim.start(new Chaincode());