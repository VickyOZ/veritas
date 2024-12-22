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
     verifier: principal,
     risk-level: (string-ascii 10),
     is-frozen: bool})

(define-map verifiers principal bool)

;; Store verification history
(define-map verification-history
    { user: principal, action-id: uint }
    { action: (string-ascii 20),
      timestamp: uint,
      verifier: principal,
      details: (string-ascii 50) })

;; Track last action ID for each user
(define-map user-action-counters principal uint)

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
                 verifier: tx-sender,
                 risk-level: "STANDARD",
                 is-frozen: false})))))

(define-public (update-user-status (user principal) (new-status (string-ascii 20)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender)))
          (user-data (unwrap! (map-get? verified-users user) error-invalid-status)))
        (begin
            (asserts! is-verifier error-unauthorized)
            (ok (map-set verified-users 
                user 
                (merge user-data {status: new-status}))))))

;; Function to verify multiple users at once
(define-public (bulk-verify-users (users (list 200 principal)) (status (string-ascii 20)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender))))
        (begin
            (asserts! is-verifier error-unauthorized)
            (ok (map verify-single-user users)))))

;; Helper function for bulk verification
(define-private (verify-single-user (user principal))
    (match (map-get? verified-users user)
        prev-entry false
        (map-set verified-users 
            user 
            {status: "VERIFIED",
             verification-date: block-height,
             verifier: tx-sender,
             risk-level: "STANDARD",
             is-frozen: false})))

;; Function to check if verification has expired (e.g., after 365 days)
(define-read-only (is-verification-expired (user principal))
    (let ((user-info (map-get? verified-users user)))
        (match user-info
            verified-data (> (- block-height (get verification-date verified-data)) u365)
            false)))

;; Helper function to get and increment action counter
(define-private (get-next-action-id (user principal))
    (let ((current-id (default-to u0 (map-get? user-action-counters user))))
        (begin
            (map-set user-action-counters user (+ current-id u1))
            (+ current-id u1))))

;; Function to record verification history
(define-public (record-verification-action 
    (user principal) 
    (action (string-ascii 20)) 
    (details (string-ascii 50)))
    (let (
        (is-verifier (default-to false (map-get? verifiers tx-sender)))
        (action-id (get-next-action-id user))
    )
        (begin
            (asserts! is-verifier error-unauthorized)
            (ok (map-set verification-history
                { user: user, action-id: action-id }
                { action: action,
                  timestamp: block-height,
                  verifier: tx-sender,
                  details: details })))))

;; Function to freeze/unfreeze user accounts
(define-public (set-account-freeze-status 
    (user principal) 
    (freeze-status bool) 
    (reason (string-ascii 50)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender)))
          (user-data (unwrap! (map-get? verified-users user) error-invalid-status)))
        (begin
            (asserts! is-verifier error-unauthorized)
            (ok (begin 
                (map-set verified-users user 
                    (merge user-data { is-frozen: freeze-status }))
                (record-verification-action user 
                    (if freeze-status "ACCOUNT_FROZEN" "ACCOUNT_UNFROZEN") 
                    reason))))))

;; Read-only functions
(define-read-only (get-user-status (user principal))
    (map-get? verified-users user))

(define-read-only (is-verifier (address principal))
    (default-to false (map-get? verifiers address)))

(define-read-only (get-verification-history (user principal) (action-id uint))
    (map-get? verification-history { user: user, action-id: action-id }))

(define-read-only (get-last-action-id (user principal))
    (default-to u0 (map-get? user-action-counters user)))