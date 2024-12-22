# Veritas - Decentralized KYC Verification System

Veritas is a decentralized Know Your Customer (KYC) verification system built on the Stacks blockchain using Clarity smart contracts. It provides a transparent, secure, and compliant way to manage user verifications with comprehensive audit trails.

## Features

- **Advanced Verification Management**
  - Multi-level user verification states (VERIFIED, PENDING, REJECTED)
  - Risk-level assessment (LOW, STANDARD, HIGH)
  - Account freeze functionality for suspicious activities
  - Verification expiry tracking (365-block window)

- **Robust Verifier System**
  - Controlled verifier authorization
  - Comprehensive action logging
  - Bulk verification capabilities
  - Granular permission management

- **Audit & Compliance**
  - Detailed verification history tracking
  - Action-based event logging
  - User statistics and metrics
  - Risk level management
  - Immutable audit trails

## Smart Contract Architecture

### Data Models

```clarity
;; User Verification Data
{
  status: (string-ascii 20),           // VERIFIED, PENDING, REJECTED
  verification-date: uint,             // Block height of verification
  verifier: principal,                 // Address of verifier
  risk-level: (string-ascii 10),       // LOW, STANDARD, HIGH
  is-frozen: bool                      // Account freeze status
}

;; Verification History Entry
{
  action: (string-ascii 20),           // Type of action performed
  timestamp: uint,                     // Block height of action
  verifier: principal,                 // Address of verifier
  details: (string-ascii 50)           // Additional context
}
```

### Core Functions

#### Verifier Management
```clarity
(define-public (add-verifier (verifier principal)))
(define-public (remove-verifier (verifier principal)))
```

#### User Verification
```clarity
(define-public (verify-user (user principal) 
                           (status (string-ascii 20)) 
                           (risk-level (string-ascii 10))))

(define-public (update-user-status (user principal) 
                                 (new-status (string-ascii 20))))

(define-public (bulk-verify-users (users (list 200 principal)) 
                                (status (string-ascii 20))))
```

#### Risk Management
```clarity
(define-public (update-user-risk-level (user principal) 
                                     (new-risk-level (string-ascii 10))
                                     (reason (string-ascii 50))))

(define-public (set-account-freeze-status (user principal) 
                                        (freeze-status bool) 
                                        (reason (string-ascii 50))))
```

#### Audit & Reporting
```clarity
(define-read-only (get-user-verification-stats (user principal)))
(define-read-only (get-verification-history (user principal) (action-id uint)))
(define-read-only (is-verification-expired (user principal)))
```

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

### Usage Examples

#### Adding a New Verifier
```clarity
;; Only contract owner can add verifiers
(contract-call? .veritas add-verifier 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### Verifying a User
```clarity
;; Must be called by an authorized verifier
(contract-call? .veritas verify-user 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
    "VERIFIED" 
    "STANDARD")
```

#### Updating Risk Level
```clarity
(contract-call? .veritas update-user-risk-level
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
    "HIGH"
    "Suspicious transaction patterns detected")
```

#### Freezing an Account
```clarity
(contract-call? .veritas set-account-freeze-status
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
    true
    "Multiple failed verification attempts")
```

## Security Considerations

- **Access Control**: Strict role-based access control for verifiers
- **Data Validation**: Comprehensive input validation for all functions
- **Audit Trail**: Immutable record of all verification actions
- **Privacy**: Minimal on-chain data storage with focus on verification status
- **Risk Management**: Multi-level risk assessment and account freezing capabilities

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
