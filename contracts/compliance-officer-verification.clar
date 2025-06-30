;; Compliance Officer Verification Contract
;; Manages verification and authorization of cybersecurity compliance officers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CERTIFICATION (err u103))

;; Data structures
(define-map compliance-officers
  principal
  {
    verified: bool,
    certification-level: uint,
    verification-date: uint,
    certifying-body: (string-ascii 50),
    expiry-date: uint
  }
)

(define-map certification-bodies
  (string-ascii 50)
  {
    authorized: bool,
    registration-date: uint
  }
)

(define-data-var total-officers uint u0)

;; Public functions
(define-public (register-certification-body (body-name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set certification-bodies body-name {
      authorized: true,
      registration-date: stacks-block-height
    })
    (ok true)
  )
)

(define-public (verify-compliance-officer
  (officer principal)
  (certification-level uint)
  (certifying-body (string-ascii 50))
  (expiry-date uint)
)
  (let (
    (body-info (map-get? certification-bodies certifying-body))
  )
    (asserts! (is-some body-info) ERR_INVALID_CERTIFICATION)
    (asserts! (get authorized (unwrap-panic body-info)) ERR_INVALID_CERTIFICATION)
    (asserts! (is-none (map-get? compliance-officers officer)) ERR_ALREADY_VERIFIED)

    (map-set compliance-officers officer {
      verified: true,
      certification-level: certification-level,
      verification-date: stacks-block-height,
      certifying-body: certifying-body,
      expiry-date: expiry-date
    })

    (var-set total-officers (+ (var-get total-officers) u1))
    (ok true)
  )
)

(define-public (revoke-officer-verification (officer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? compliance-officers officer)) ERR_NOT_FOUND)

    (map-delete compliance-officers officer)
    (var-set total-officers (- (var-get total-officers) u1))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified-officer (officer principal))
  (match (map-get? compliance-officers officer)
    officer-data (and
      (get verified officer-data)
      (> (get expiry-date officer-data) stacks-block-height)
    )
    false
  )
)

(define-read-only (get-officer-info (officer principal))
  (map-get? compliance-officers officer)
)

(define-read-only (get-total-officers)
  (var-get total-officers)
)

(define-read-only (is-authorized-body (body-name (string-ascii 50)))
  (match (map-get? certification-bodies body-name)
    body-info (get authorized body-info)
    false
  )
)
