const ClientApplication = require('./client');

let userClient = new ClientApplication();
userClient.submitTxn(
    "organization1user",       
    "orgchannel",
    "Asset",
    "ReadAsset",
    "Asset-100",
   ).then(result => {
    console.log(new TextDecoder().decode(result));
    console.log(" Asset Details")
}).catch(error => {
    console.error(" Failed to submit transaction:", error);
});
