const fs = require('fs');
const path = require('path');
const { Wallets } = require('fabric-network');

async function importIdentity(userType, userName) {
    try {
        const walletPath = path.join(__dirname, 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const identityLabel = userName;
        const credPath = path.join(__dirname, `../Network/organizations/peerOrganizations/organization1.sample.com/users/${userType}@organization1.sample.com/msp`);

        const certPath = path.join(credPath, 'signcerts/cert.pem');
        const keyPath = path.join(credPath, 'keystore');

        if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
            throw new Error(`Certificate or key directory for "${userType}" not found.`);
        }

        const keyFiles = fs.readdirSync(keyPath);
        if (keyFiles.length === 0) {
            throw new Error(`No private key found for "${userType}".`);
        }

        const keyFile = path.join(keyPath, keyFiles[0]);
        const certificate = fs.readFileSync(certPath).toString();
        const privateKey = fs.readFileSync(keyFile).toString();

        const identity = {
            credentials: {
                certificate,
                privateKey,
            },
            mspId: 'organization1MSP',
            type: 'X.509',
        };

        await wallet.put(identityLabel, identity);
        console.log(`✅ Successfully imported "${identityLabel}" into the wallet.`);
    } catch (error) {
        console.error(`❌ Error importing identity "${userType}": ${error.message}`);
    }
}

async function main() {
    console.log("🔄 Importing Admin and Auditor identities...");
    await importIdentity("Admin", "organization1admin"); // Import Admin
    await importIdentity("Auditor", "organization1auditor"); // Import Auditor
    console.log("✅ All identities imported successfully.");
}

main().catch(console.error);
