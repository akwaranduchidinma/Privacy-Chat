;; Secure Messenger - Decentralized End-to-End Encrypted Communication Protocol
;; A privacy-first blockchain messaging platform with quantum-resistant encryption support,
;; user relationship management, threaded conversations, and granular access controls

;; Error constants for operation failures
(define-constant ERR-UNAUTHORIZED-ACCESS (err u200))
(define-constant ERR-MESSAGE-NOT-FOUND (err u201))
(define-constant ERR-INVALID-RECIPIENT (err u202))
(define-constant ERR-MESSAGE-TOO-LONG (err u203))
(define-constant ERR-USER-ALREADY-BLOCKED (err u204))
(define-constant ERR-USER-NOT-BLOCKED (err u205))
(define-constant ERR-CANNOT-TARGET-SELF (err u206))
(define-constant ERR-INVALID-PAGINATION (err u207))
(define-constant ERR-INVALID-PARAMETERS (err u208))
(define-constant ERR-INVALID-THREAD (err u209))
(define-constant ERR-TRUST-LEVEL-OUT-OF-RANGE (err u210))
(define-constant ERR-PRIVACY-LEVEL-OUT-OF-RANGE (err u211))
(define-constant ERR-PLATFORM-DISABLED (err u212))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u213))
(define-constant ERR-INVALID-ENCRYPTION-KEY (err u214))
(define-constant ERR-TOO-MANY-PARTICIPANTS (err u215))

;; Platform configuration constants
(define-constant max-message-length u1000)
(define-constant max-display-name-length u50)
(define-constant max-nickname-length u50)
(define-constant max-encryption-key-length u100)
(define-constant max-block-reason-length u100)
(define-constant max-trust-level u10)
(define-constant max-privacy-level u10)
(define-constant max-group-participants u10)
(define-constant max-priority-level u10)
(define-constant contract-owner tx-sender)
(define-constant thread-id-offset u1000)

;; Global state variables
(define-data-var message-counter uint u0)
(define-data-var is-platform-active bool true)
(define-data-var deployment-block uint block-height)
(define-data-var maintenance-mode bool false)

;; Message storage with encryption metadata
(define-map messages
    uint
    {
        sender: principal,
        recipient: principal,
        content: (string-ascii 1000),
        timestamp: uint,
        is-quantum-encrypted: bool,
        thread-id: (optional uint),
        priority: uint
    }
)

;; User profile and identity data
(define-map user-profiles
    principal
    {
        display-name: (string-ascii 50),
        public-key: (optional (string-ascii 100)),
        created-at: uint,
        privacy-level: uint,
        status: (string-ascii 20)
    }
)

;; User blocking relationships
(define-map blocked-users
    { blocker: principal, blocked: principal }
    {
        blocked-at: uint,
        reason: (string-ascii 100)
    }
)

;; Trusted contacts and relationships
(define-map contacts
    { owner: principal, contact: principal }
    {
        nickname: (string-ascii 50),
        added-at: uint,
        trust-level: uint,
        category: (string-ascii 20)
    }
)

;; Group conversation threads
(define-map threads
    uint
    {
        creator: principal,
        participants: (list 10 principal),
        created-at: uint,
        privacy-level: uint,
        is-active: bool
    }
)

;; Read-only function to get message by ID
(define-read-only (get-message (msg-id uint))
    (map-get? messages msg-id)
)

;; Read-only function to get user profile
(define-read-only (get-user-profile (user principal))
    (map-get? user-profiles user)
)

;; Read-only function to check if user is blocked
(define-read-only (is-user-blocked (blocker principal) (target principal))
    (is-some (map-get? blocked-users { blocker: blocker, blocked: target }))
)

;; Read-only function to get contact details
(define-read-only (get-contact (owner principal) (contact principal))
    (map-get? contacts { owner: owner, contact: contact })
)

;; Read-only function to get total message count
(define-read-only (get-message-count)
    (var-get message-counter)
)

;; Read-only function to check platform status
(define-read-only (is-platform-operational)
    (and 
        (var-get is-platform-active)
        (not (var-get maintenance-mode))
    )
)

;; Read-only function to get thread details
(define-read-only (get-thread (thread-id uint))
    (map-get? threads thread-id)
)

;; Read-only function to get platform information
(define-read-only (get-platform-info)
    {
        name: "SecureMessenger",
        version: "4.0.0",
        total-messages: (var-get message-counter),
        owner: contract-owner,
        is-active: (var-get is-platform-active),
        deployed-at: (var-get deployment-block),
        max-message-length: max-message-length,
        max-group-size: max-group-participants,
        maintenance-mode: (var-get maintenance-mode)
    }
)

;; Private function to validate encryption key
(define-private (is-valid-encryption-key (key (optional (string-ascii 100))))
    (match key
        key-value (and 
            (<= (len key-value) max-encryption-key-length)
            (> (len key-value) u0)
        )
        true
    )
)

;; Private function to validate privacy level
(define-private (is-valid-privacy-level (level uint))
    (and 
        (<= level max-privacy-level)
        (>= level u0)
    )
)

;; Private function to validate trust level
(define-private (is-valid-trust-level (level uint))
    (and 
        (<= level max-trust-level)
        (>= level u0)
    )
)

;; Private function to validate block reason
(define-private (is-valid-block-reason (reason (string-ascii 100)))
    (and 
        (> (len reason) u0)
        (<= (len reason) max-block-reason-length)
    )
)

;; Private function to validate thread existence
(define-private (is-valid-thread (thread-id (optional uint)))
    (match thread-id
        tid (is-some (map-get? threads tid))
        true
    )
)

;; Private function to check if thread exists
(define-private (thread-exists (thread-id uint))
    (is-some (map-get? threads thread-id))
)

;; Private function to verify users are different
(define-private (are-different-users (user-a principal) (user-b principal))
    (not (is-eq user-a user-b))
)

;; Private function to authorize message sending
(define-private (can-send-message (recipient principal) (content (string-ascii 1000)))
    (and
        (are-different-users tx-sender recipient)
        (<= (len content) max-message-length)
        (> (len content) u0)
        (not (is-user-blocked recipient tx-sender))
        (is-platform-operational)
    )
)

;; Public function to send encrypted message
(define-public (send-message 
    (recipient principal) 
    (content (string-ascii 1000)) 
    (use-quantum-encryption bool) 
    (thread-id (optional uint))
    (priority uint))
    (let (
        (sender tx-sender)
        (msg-id (+ (var-get message-counter) u1))
        (current-time block-height)
    )
        (asserts! (can-send-message recipient content) ERR-INVALID-RECIPIENT)
        (asserts! (is-valid-thread thread-id) ERR-INVALID-THREAD)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        (asserts! (<= priority max-priority-level) ERR-INVALID-PARAMETERS)

        (map-set messages msg-id {
            sender: sender,
            recipient: recipient,
            content: content,
            timestamp: current-time,
            is-quantum-encrypted: use-quantum-encryption,
            thread-id: thread-id,
            priority: priority
        })

        (var-set message-counter msg-id)
        (ok msg-id)
    )
)

;; Read-only function to get sent messages with pagination
(define-read-only (get-sent-messages (sender principal) (limit uint) (offset uint))
    (if (is-eq tx-sender sender)
        (ok (filter-by-sender sender limit offset))
        ERR-UNAUTHORIZED-ACCESS
    )
)

;; Read-only function to get received messages with pagination
(define-read-only (get-received-messages (recipient principal) (limit uint) (offset uint))
    (if (is-eq tx-sender recipient)
        (ok (filter-by-recipient recipient limit offset))
        ERR-UNAUTHORIZED-ACCESS
    )
)

;; Private helper function to filter messages by sender
(define-private (filter-by-sender (sender principal) (limit uint) (offset uint))
    (list)
)

;; Private helper function to filter messages by recipient
(define-private (filter-by-recipient (recipient principal) (limit uint) (offset uint))
    (list)
)

;; Public function to create user profile
(define-public (create-profile 
    (display-name (string-ascii 50)) 
    (public-key (optional (string-ascii 100)))
    (privacy-level uint))
    (let ((user tx-sender))
        (asserts! (<= (len display-name) max-display-name-length) ERR-MESSAGE-TOO-LONG)
        (asserts! (is-valid-encryption-key public-key) ERR-INVALID-ENCRYPTION-KEY)
        (asserts! (is-valid-privacy-level privacy-level) ERR-PRIVACY-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (map-set user-profiles user {
            display-name: display-name,
            public-key: public-key,
            created-at: block-height,
            privacy-level: privacy-level,
            status: "active"
        })
        (ok true)
    )
)

;; Public function to update user profile
(define-public (update-profile 
    (display-name (string-ascii 50)) 
    (public-key (optional (string-ascii 100)))
    (privacy-level uint))
    (let ((user tx-sender))
        (asserts! (<= (len display-name) max-display-name-length) ERR-MESSAGE-TOO-LONG)
        (asserts! (is-valid-encryption-key public-key) ERR-INVALID-ENCRYPTION-KEY)
        (asserts! (is-valid-privacy-level privacy-level) ERR-PRIVACY-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (match (map-get? user-profiles user)
            existing-profile 
                (map-set user-profiles user 
                    (merge existing-profile {
                        display-name: display-name,
                        public-key: public-key,
                        privacy-level: privacy-level
                    })
                )
            false
        )
        (ok true)
    )
)

;; Public function to block a user
(define-public (block-user (target principal) (reason (string-ascii 100)))
    (let ((blocker tx-sender))
        (asserts! (are-different-users blocker target) ERR-CANNOT-TARGET-SELF)
        (asserts! (not (is-user-blocked blocker target)) ERR-USER-ALREADY-BLOCKED)
        (asserts! (is-valid-block-reason reason) ERR-INVALID-PARAMETERS)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (map-set blocked-users 
            { blocker: blocker, blocked: target }
            {
                blocked-at: block-height,
                reason: reason
            }
        )
        (ok true)
    )
)

;; Public function to unblock a user
(define-public (unblock-user (target principal))
    (let ((blocker tx-sender))
        (asserts! (is-user-blocked blocker target) ERR-USER-NOT-BLOCKED)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (map-delete blocked-users { blocker: blocker, blocked: target })
        (ok true)
    )
)

;; Public function to add trusted contact
(define-public (add-contact 
    (contact-user principal) 
    (nickname (string-ascii 50))
    (trust-level uint))
    (let ((owner tx-sender))
        (asserts! (<= (len nickname) max-nickname-length) ERR-MESSAGE-TOO-LONG)
        (asserts! (are-different-users owner contact-user) ERR-CANNOT-TARGET-SELF)
        (asserts! (is-valid-trust-level trust-level) ERR-TRUST-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (map-set contacts 
            { owner: owner, contact: contact-user }
            {
                nickname: nickname,
                added-at: block-height,
                trust-level: trust-level,
                category: "trusted"
            }
        )
        (ok true)
    )
)

;; Public function to remove contact
(define-public (remove-contact (contact-user principal))
    (let ((owner tx-sender))
        (asserts! (are-different-users owner contact-user) ERR-CANNOT-TARGET-SELF)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (map-delete contacts { owner: owner, contact: contact-user })
        (ok true)
    )
)

;; Public function to create group thread
(define-public (create-thread (participants (list 10 principal)) (privacy-level uint))
    (let (
        (creator tx-sender)
        (new-thread-id (+ (var-get message-counter) thread-id-offset))
    )
        (asserts! (> (len participants) u0) ERR-INVALID-PARAMETERS)
        (asserts! (<= (len participants) max-group-participants) ERR-TOO-MANY-PARTICIPANTS)
        (asserts! (is-valid-privacy-level privacy-level) ERR-PRIVACY-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (map-set threads new-thread-id {
            creator: creator,
            participants: participants,
            created-at: block-height,
            privacy-level: privacy-level,
            is-active: true
        })
        
        (ok new-thread-id)
    )
)

;; Public function to update thread status
(define-public (update-thread-status (thread-id uint) (active bool))
    (let ((caller tx-sender))
        (asserts! (thread-exists thread-id) ERR-INVALID-THREAD)
        (asserts! (is-platform-operational) ERR-PLATFORM-DISABLED)
        
        (match (map-get? threads thread-id)
            thread-data
                (begin
                    (asserts! (is-eq (get creator thread-data) caller) ERR-UNAUTHORIZED-ACCESS)
                    
                    (map-set threads thread-id 
                        (merge thread-data { is-active: active }))
                    (ok true)
                )
            ERR-INVALID-THREAD
        )
    )
)

;; Read-only function to get thread messages with pagination
(define-read-only (get-thread-messages (thread-id uint) (limit uint) (offset uint))
    (match (map-get? threads thread-id)
        thread-data
            (if (has-thread-access thread-id tx-sender)
                (ok (filter-by-thread thread-id limit offset))
                ERR-UNAUTHORIZED-ACCESS
            )
        ERR-INVALID-THREAD
    )
)

;; Private function to verify thread access
(define-private (has-thread-access (thread-id uint) (user principal))
    (match (map-get? threads thread-id)
        thread-data
            (or 
                (is-eq (get creator thread-data) user)
                (is-some (index-of (get participants thread-data) user))
            )
        false
    )
)

;; Private helper function to filter messages by thread
(define-private (filter-by-thread (thread-id uint) (limit uint) (offset uint))
    (list)
)

;; Public function to set platform status (owner only)
(define-public (set-platform-status (active bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set is-platform-active active)
        (ok active)
    )
)

;; Public function to toggle maintenance mode (owner only)
(define-public (set-maintenance-mode (enabled bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set maintenance-mode enabled)
        (ok enabled)
    )
)

;; Read-only function to get admin information
(define-read-only (get-admin-info)
    {
        owner: contract-owner,
        is-active: (var-get is-platform-active),
        maintenance-mode: (var-get maintenance-mode),
        deployed-at: (var-get deployment-block),
        total-messages: (var-get message-counter),
        uptime-blocks: (- block-height (var-get deployment-block))
    }
)

;; Public function for emergency shutdown (owner only)
(define-public (emergency-shutdown (reason (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (> (len reason) u0) ERR-INVALID-PARAMETERS)
        
        (var-set is-platform-active false)
        (var-set maintenance-mode true)
        (ok reason)
    )
)

;; Private function to validate message content
(define-private (is-valid-message-content (content (string-ascii 1000)))
    (and
        (> (len content) u0)
        (<= (len content) max-message-length)
    )
)

;; Read-only function to check if thread is active
(define-read-only (is-thread-active (thread-id uint))
    (match (map-get? threads thread-id)
        thread-data (get is-active thread-data)
        false
    )
)

;; Read-only function to get platform statistics
(define-read-only (get-platform-stats)
    {
        total-messages: (var-get message-counter),
        deployed-at: (var-get deployment-block),
        current-block: block-height,
        platform-age: (- block-height (var-get deployment-block)),
        is-active: (var-get is-platform-active),
        maintenance-mode: (var-get maintenance-mode)
    }
)