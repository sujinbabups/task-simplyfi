# task-simplyfi
**ABAC-Based Asset Management System :**
This project implements Hyperledger Fabric with Attribute-Based Access Control (ABAC) policies for managing assets.
It includes admin, auditor, and regular user roles, ensuring access control over asset creation, updates, deletion, and retrieval.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger%20Fabric-2.5-brightgreen)](https://www.hyperledger.org/use/fabric)
[![Node.js](https://img.shields.io/badge/Node.js-16.x-green)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/Docker-required-blue)](https://www.docker.com/)

> A blockchain-based asset management system built on Hyperledger Fabric with Attribute-Based Access Control (ABAC).

## 📋 Prerequisites

- Docker
- Node.js 
- Hyperledger Fabric Binaries
- Postman (for API testing)

## 🏗️ Architecture

This project implements a secure asset management system using Hyperledger Fabric's permissioned blockchain with ABAC policies. The system supports three user roles:

- **Admin**: Full asset management capabilities
- **Auditor**: Complete asset visibility
- **User**: Access to owned assets only

## 💼 Key Features

- ✨ ABAC-Based Access Control
- 🔐 Role-Based Authorization
- 📊 Asset Lifecycle Management
- 🌐 RESTful API Interface
- 🔄 Real-time Asset Updates

## 🛠️ Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/sujinbabups/task-simplyfi.git
   cd task-simplyfi
   ```

2. **Set Up Network**
   ```bash
   cd Network
   chmod +x startNetwork
   ./startNetwork.sh
   ```

3. **Configure Client**
   ```bash
   cd ../Client
   npm install
   node importIdentity.js
   ```

4. **Start Server**
   ```bash
   cd Server
   npm install
   node index.js
   ```
## 🔒 Access Control Matrix

| Operation | Admin | Auditor | User |
|-----------|-------|---------|------|
| Create    | ✅    | ❌      | ❌   |
| Read All  | ❌    | ✅      | ❌   |
| Read Own  | ✅    | ✅      | ✅   |
| Update    | ✅    | ❌      | ❌   |
| Delete    | ✅    | ❌      | ❌   |

## 🐛 Troubleshooting

### Network Issues
```bash
# Check docker containers
docker ps -a

# Restart network
./stopNetwork.sh && ./startNetwork.sh
```

### Identity Issues
```bash
# Reimport identities
cd Client
node importIdentity.js

# Check CA identities
fabric-ca-client identity list --tls.certfiles organizations/fabric-ca/organization1/ca-cert.pem
```

## ✨ Acknowledgments

- Hyperledger Fabric Community
- Node.js Community
- Docker Team
