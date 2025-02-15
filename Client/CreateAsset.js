const ClientApplication = require('./client');

let userClient = new ClientApplication();
userClient.submitTxn(
    "organization1admin",       
    "orgchannel",
    "Asset",
    "CreateAsset",
    "Asset-200",
    "user1",
    "5000"
).then(result => {
    console.log(new TextDecoder().decode(result));
    console.log(" Asset successfully created");
}).catch(error => {
    console.error(" Failed to submit transaction:", error);
});
