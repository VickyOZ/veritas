;; Veritas - Decentralized KYC Verification System
;; Smart contract for managing KYC verifications on Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant error-unauthorized (err u1))
(define-constant error-already-verified (err u2))
(define-constant error-invalid-status (err u3))
(define-constant error-user-not-found (err u4))
(define-constant error-invalid-input (err u5))

;; Data maps
(define-map verified-users 
    principal 
    {status: (string-ascii 20),
     verification-date: uint,
     verifier: principal,
     risk-level: (string-ascii 10),
     is-frozen: bool})

(define-map verifiers principal bool)

(define-map verification-history
    { user: principal, action-id: uint }
    { action: (string-ascii 20),
      timestamp: uint,
      verifier: principal,
      details: (string-ascii 50) })

(define-map user-action-counters principal uint)

;; Private functions
(define-private (is-valid-status (status (string-ascii 20)))
    (or (is-eq status "VERIFIED")
        (is-eq status "PENDING")
        (is-eq status "REJECTED")))

(define-private (is-valid-risk-level (risk-level (string-ascii 10)))
    (or (is-eq risk-level "LOW")
        (is-eq risk-level "STANDARD")
        (is-eq risk-level "HIGH")))

(define-private (is-valid-action (action (string-ascii 20)))
    (or (is-eq action "VERIFIED")
        (is-eq action "UPDATED")
        (is-eq action "REJECTED")
        (is-eq action "ACCOUNT_FROZEN")
        (is-eq action "ACCOUNT_UNFROZEN")))

;; Public functions
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
        (asserts! (is-none (map-get? verifiers verifier)) error-invalid-input)
        (ok (map-set verifiers verifier true))))

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
        (asserts! (is-some (map-get? verifiers verifier)) error-invalid-input)
        (ok (map-delete verifiers verifier))))

(define-public (verify-user (user principal) (status (string-ascii 20)) (risk-level (string-ascii 10)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender))))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-none (map-get? verified-users user)) error-already-verified)
            (asserts! (is-valid-status status) error-invalid-status)
            (asserts! (is-valid-risk-level risk-level) error-invalid-input)
            (ok (map-set verified-users 
                user 
                {status: status,
                 verification-date: block-height,
                 verifier: tx-sender,
                 risk-level: risk-level,
                 is-frozen: false})))))

(define-public (update-user-status (user principal) (new-status (string-ascii 20)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender)))
          (user-data (map-get? verified-users user)))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-some user-data) error-user-not-found)
            (asserts! (is-valid-status new-status) error-invalid-status)
            (ok (map-set verified-users 
                user 
                (merge (unwrap-panic user-data) {status: new-status}))))))

(define-public (bulk-verify-users (users (list 200 principal)) (status (string-ascii 20)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender))))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-valid-status status) error-invalid-status)
            (ok (map verify-single-user users)))))

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

(define-read-only (is-verification-expired (user principal))
    (match (map-get? verified-users user)
        verified-data (> (- block-height (get verification-date verified-data)) u365)
        false))

(define-private (get-next-action-id (user principal))
    (let ((current-id (default-to u0 (map-get? user-action-counters user))))
        (begin
            (map-set user-action-counters user (+ current-id u1))
            (+ current-id u1))))

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
            (asserts! (is-some (map-get? verified-users user)) error-user-not-found)
            (asserts! (is-valid-action action) error-invalid-input)
            (asserts! (<= (len details) u50) error-invalid-input)
            (ok (map-set verification-history
                { user: user, action-id: action-id }
                { action: action,
                  timestamp: block-height,
                  verifier: tx-sender,
                  details: details })))))

(define-public (set-account-freeze-status 
    (user principal) 
    (freeze-status bool) 
    (reason (string-ascii 50)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender)))
          (user-data (map-get? verified-users user)))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-some user-data) error-user-not-found)
            (asserts! (<= (len reason) u50) error-invalid-input)
            (let ((updated-user-data (merge (unwrap-panic user-data) { is-frozen: freeze-status })))
                (ok (begin 
                    (map-set verified-users user updated-user-data)
                    (record-verification-action user 
                        (if freeze-status "ACCOUNT_FROZEN" "ACCOUNT_UNFROZEN") 
                        reason)))))))

;; Read-only functions
(define-read-only (get-user-status (user principal))
    (map-get? verified-users user))

(define-read-only (is-verifier (address principal))
    (default-to false (map-get? verifiers address)))

(define-read-only (get-verification-history (user principal) (action-id uint))
    (map-get? verification-history { user: user, action-id: action-id }))

(define-read-only (get-last-action-id (user principal))
    (default-to u0 (map-get? user-action-counters user)))

(define-read-only (get-user-verification-stats (user principal))
    (let ((user-data (map-get? verified-users user))
          (last-action-id (default-to u0 (map-get? user-action-counters user))))
        (if (is-none user-data)
            (err error-user-not-found)
            (ok {
                verification-age: (- block-height 
                    (get verification-date (unwrap-panic user-data))),
                total-actions: last-action-id,
                is-expired: (is-verification-expired user),
                current-status: (get status (unwrap-panic user-data)),
                current-risk-level: (get risk-level (unwrap-panic user-data)),
                is-frozen: (get is-frozen (unwrap-panic user-data))
            }))))

;; New function to update user risk level
(define-public (update-user-risk-level 
    (user principal) 
    (new-risk-level (string-ascii 10))
    (reason (string-ascii 50)))
    (let ((is-verifier (default-to false (map-get? verifiers tx-sender)))
          (user-data (map-get? verified-users user)))
        (begin
            (asserts! is-verifier error-unauthorized)
            (asserts! (is-some user-data) error-user-not-found)
            (asserts! (is-valid-risk-level new-risk-level) error-invalid-input)
            (asserts! (<= (len reason) u50) error-invalid-input)
            (let ((updated-user-data (merge (unwrap-panic user-data) 
                    {risk-level: new-risk-level})))
                (ok (begin 
                    (map-set verified-users user updated-user-data)
                    (record-verification-action user 
                        "UPDATED"
                        reason)))))))