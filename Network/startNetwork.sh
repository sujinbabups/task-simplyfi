#!/bin/bash

echo "------------Register the ca admin for each organization—----------------"

docker compose -f docker/docker-compose-ca.yaml up -d
sleep 3

sudo chmod -R 777 organizations/

echo "------------Register and enroll the users for each organization—-----------"

chmod +x registerEnroll.sh

./registerEnroll.sh
sleep 3

echo "—-------------Build the infrastructure—-----------------"
docker compose -f docker/docker-compose-2org.yaml up -d

sleep 3

echo "-------------Generate the genesis block—-------------------------------"

export FABRIC_CFG_PATH=${PWD}/config

export CHANNEL_NAME=orgchannel

configtxgen -profile TwoOrgsChannel -outputBlock ${PWD}/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
sleep 2

echo "------ Create the application channel------"

export ORDERER_CA=${PWD}/organizations/ordererOrganizations/sample.com/orderers/orderer.sample.com/msp/tlscacerts/tlsca.sample.com-cert.pem

export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/sample.com/orderers/orderer.sample.com/tls/server.crt

export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/sample.com/orderers/orderer.sample.com/tls/server.key

osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/channel-artifacts/$CHANNEL_NAME.block -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
sleep 2

osnadmin channel list -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
sleep 2

export FABRIC_CFG_PATH=${PWD}/peercfg
export CORE_PEER_LOCALMSPID=organization1MSP
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/organization1.sample.com/peers/peer0.organization1.sample.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/organization1.sample.com/users/Admin@organization1.sample.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export organization1_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/organization1.sample.com/peers/peer0.organization1.sample.com/tls/ca.crt
export ORG1_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/organization1.sample.com/peers/peer0.organization1.sample.com/tls/ca.crt
sleep 2
echo "—---------------Join organization1 peer to the channel—-------------"

echo ${FABRIC_CFG_PATH}
sleep 2
peer channel join -b ${PWD}/channel-artifacts/${CHANNEL_NAME}.block
sleep 3

echo "-----channel List----"
peer channel list

echo "—-------------Organization1 anchor peer update—-----------"

peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.sample.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
sleep 1

cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.organization1MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.organization1.sample.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..

peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.sample.com --tls --cafile $ORDERER_CA
sleep 1

echo "—---------------package chaincode—-------------"

peer lifecycle chaincode package assetchain.tar.gz --path ${PWD}/../Chaincode/ --lang node --label assetchain_1.0
sleep 1

echo "—---------------install chaincode in organization1 peer—-------------"

peer lifecycle chaincode install assetchain.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled
sleep 1

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid assetchain.tar.gz)

echo "—---------------Approve chaincode in organization1 peer—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.sample.com --channelID $CHANNEL_NAME --name Asset --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent

sleep 2


export CORE_PEER_LOCALMSPID=organization2MSP 
export CORE_PEER_ADDRESS=localhost:9051 
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/organization2.sample.com/peers/peer0.organization2.sample.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/organization2.sample.com/users/Admin@organization2.sample.com/msp
export ORG2_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/organization2.sample.com/peers/peer0.organization2.sample.com/tls/ca.crt


echo "—---------------Join organization2 peer to the channel—-------------"

peer channel join -b ${PWD}/channel-artifacts/$CHANNEL_NAME.block
sleep 1
peer channel list
    
echo "—-------------organization2 anchor peer update—-----------"

peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.sample.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
sleep 1

cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json
cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.organization2MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.organization2.sample.com","port": 9051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..

peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.sample.com --tls --cafile $ORDERER_CA
sleep 1

echo "—---------------package chaincode—-------------"

peer lifecycle chaincode package assetchain.tar.gz --path ${PWD}/../Chaincode/ --lang node --label assetchain_1.0
sleep 1

echo "—---------------install chaincode in organization2 peer—-------------"

peer lifecycle chaincode install assetchain.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled
sleep 1

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid assetchain.tar.gz)

echo "—---------------Approve chaincode in organization2 peer—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.sample.com --channelID $CHANNEL_NAME --name Asset --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent

sleep 2

echo "—---------------Commit chaincode-------------"

peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name Asset --version 1.0 --sequence 1  --cafile $ORDERER_CA --output json

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.sample.com --channelID $CHANNEL_NAME --name Asset --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles $ORG1_PEER_TLSROOTCERT --peerAddresses localhost:9051 --tlsRootCertFiles $ORG2_PEER_TLSROOTCERT

sleep 1


peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name Asset --cafile $ORDERER_CA


# invoke
# peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.sample.com --tls --cafile "${PWD}/organizations/ordererOrganizations/sample.com/orderers/orderer.sample.com/msp/tlscacerts/tlsca.sample.com-cert.pem" -C orgchannel -n Asset --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/organization1.sample.com/peers/peer0.organization1.sample.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/organization2.sample.com/peers/peer0.organization2.sample.com/tls/ca.crt" -c '{"function":"CreateAsset","Args":["Asset-2","organization1","100"]}'
# query
# peer chaincode query -C orgchannel -n Asset -c '{"function":"GetAllAssets","Args":[]}'
# peer chaincode query -C orgchannel -n Asset -c '{"function":"ReadAsset","Args":["Asset-200"]}'

# peer chaincode query -C orgchannel -n Asset -c '{"function":"DeleteAsset","Args":["Asset-200"]}'

