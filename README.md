# Veritas - Decentralized KYC Verification System

Veritas is a decentralized Know Your Customer (KYC) verification system built on the Stacks blockchain using Clarity smart contracts. It provides a transparent and secure way to manage user verifications while maintaining privacy and compliance.

## Features

- Decentralized KYC verification management
- Multi-level verification system
- Authorized verifier management
- Transparent verification history
- Privacy-preserving user data handling

## Smart Contract Architecture

The smart contract includes several key components:

### Data Storage
- `verified-users`: Maps user principals to their verification status and history
- `verifiers`: Maps authorized verifier addresses to their status

### Key Functions

1. Verifier Management
   - `add-verifier`: Add new authorized verifiers
   - `remove-verifier`: Remove verifier access

2. User Verification
   - `verify-user`: Perform initial user verification
   - `update-user-status`: Update existing user verification status

3. Status Checking
   - `get-user-status`: Query user verification status
   - `is-verifier`: Check if an address is an authorized verifier

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Node.js and NPM (for testing environment)

### Installation

1. Clone the repository
```bash
git clone https://github.com/your-username/veritas.git
cd veritas
```

2. Install dependencies
```bash
npm install
```

3. Deploy the contract
```bash
clarinet contract deploy
```

### Usage

#### Adding a Verifier
```clarity
(contract-call? .veritas add-verifier 'VERIFIER_ADDRESS)
```

#### Verifying a User
```clarity
(contract-call? .veritas verify-user 'USER_ADDRESS "VERIFIED")
```

#### Checking User Status
```clarity
(contract-call? .veritas get-user-status 'USER_ADDRESS)
```

## Security Considerations

- Only authorized verifiers can perform verifications
- Contract owner has exclusive rights to manage verifiers
- All verification records are immutable and transparent
- User data privacy is maintained through minimal on-chain storage

## Testing

Run the test suite:
```bash
clarinet test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

