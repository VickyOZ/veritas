;; Veritas - Decentralized KYC Verification System
;; Smart contract for managing KYC verifications on Stacks blockchain

(define-constant contract-owner tx-sender)
(define-constant error-unauthorized (err u1))
(define-constant error-already-verified (err u2))
(define-constant error-invalid-status (err u3))

;; Define data maps for storing KYC information
(define-map verified-users 
    principal 
    {status: (string-ascii 20),
     verification-date: uint,
     verifier: principal})

(define-map verifiers principal bool)

;; Define public functions
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
        (ok (map-set verifiers verifier true))))

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
        (ok (map-set verifiers verifier false))))

(define-public (verify-user (user principal) (status (string-ascii 20)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender))))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-none (map-get? verified-users user)) error-already-verified)
            (ok (map-set verified-users 
                user 
                {status: status,
                 verification-date: block-height,
                 verifier: tx-sender})))))

(define-public (update-user-status (user principal) (new-status (string-ascii 20)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender))))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-some (map-get? verified-users user)) error-invalid-status)
            (ok (map-set verified-users 
                user 
                {status: new-status,
                 verification-date: block-height,
                 verifier: tx-sender})))))

;; Read-only functions
(define-read-only (get-user-status (user principal))
    (map-get? verified-users user))

(define-read-only (is-verifier (address principal))
    (default-to false (map-get? verifiers address)))