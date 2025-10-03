# Secure Messenger Smart Contract

## Overview

SecureMessenger is a decentralized end-to-end encrypted communication protocol built on the Stacks blockchain using Clarity smart contracts. It provides a privacy-first messaging platform with quantum-resistant encryption support, user relationship management, threaded conversations, and granular access controls.

## Features

### Core Messaging
- Send encrypted messages between users
- Quantum-resistant encryption support
- Message threading for organized conversations
- Priority levels for messages
- Message history tracking

### User Management
- User profiles with display names and public keys
- Privacy level controls
- User status tracking
- Profile creation and updates

### Relationship Management
- Block/unblock users with reasons
- Trusted contacts system with nicknames
- Trust levels (0-10) for contact categorization
- Contact organization by category

### Group Communication
- Create group conversation threads
- Support for up to 10 participants per thread
- Thread-level privacy controls
- Thread activation/deactivation
- Thread creator permissions

### Platform Administration
- Platform activation controls
- Maintenance mode toggle
- Emergency shutdown capability
- Platform statistics and monitoring

## Constants

### Error Codes
- `ERR-UNAUTHORIZED-ACCESS (u200)` - User lacks permission for operation
- `ERR-MESSAGE-NOT-FOUND (u201)` - Message ID does not exist
- `ERR-INVALID-RECIPIENT (u202)` - Recipient is invalid or blocked
- `ERR-MESSAGE-TOO-LONG (u203)` - Content exceeds maximum length
- `ERR-USER-ALREADY-BLOCKED (u204)` - User is already blocked
- `ERR-USER-NOT-BLOCKED (u205)` - User is not blocked
- `ERR-CANNOT-TARGET-SELF (u206)` - Cannot perform action on self
- `ERR-INVALID-PAGINATION (u207)` - Invalid pagination parameters
- `ERR-INVALID-PARAMETERS (u208)` - Invalid function parameters
- `ERR-INVALID-THREAD (u209)` - Thread does not exist
- `ERR-TRUST-LEVEL-OUT-OF-RANGE (u210)` - Trust level exceeds maximum
- `ERR-PRIVACY-LEVEL-OUT-OF-RANGE (u211)` - Privacy level exceeds maximum
- `ERR-PLATFORM-DISABLED (u212)` - Platform is not operational
- `ERR-INSUFFICIENT-PERMISSIONS (u213)` - Insufficient permissions
- `ERR-INVALID-ENCRYPTION-KEY (u214)` - Invalid encryption key format
- `ERR-TOO-MANY-PARTICIPANTS (u215)` - Exceeds maximum group size

### Platform Limits
- Maximum message length: 1000 characters
- Maximum display name length: 50 characters
- Maximum nickname length: 50 characters
- Maximum encryption key length: 100 characters
- Maximum block reason length: 100 characters
- Maximum trust level: 10
- Maximum privacy level: 10
- Maximum group participants: 10
- Maximum priority level: 10

## Public Functions

### Messaging

#### send-message
```clarity
(send-message (recipient principal) (content (string-ascii 1000)) (use-quantum-encryption bool) (thread-id (optional uint)) (priority uint))
```
Sends an encrypted message to a recipient. Returns the message ID on success.

**Parameters:**
- `recipient` - Principal address of the message recipient
- `content` - Message content (max 1000 characters)
- `use-quantum-encryption` - Enable quantum-resistant encryption
- `thread-id` - Optional thread ID for threaded conversations
- `priority` - Message priority level (0-10)

**Requirements:**
- Sender and recipient must be different users
- Content must not be empty and within length limit
- Sender must not be blocked by recipient
- Platform must be operational
- Thread ID must be valid if provided

### Profile Management

#### create-profile
```clarity
(create-profile (display-name (string-ascii 50)) (public-key (optional (string-ascii 100))) (privacy-level uint))
```
Creates a user profile with display name, optional public key, and privacy settings.

#### update-profile
```clarity
(update-profile (display-name (string-ascii 50)) (public-key (optional (string-ascii 100))) (privacy-level uint))
```
Updates an existing user profile.

### User Blocking

#### block-user
```clarity
(block-user (target principal) (reason (string-ascii 100)))
```
Blocks a user with a specified reason.

#### unblock-user
```clarity
(unblock-user (target principal))
```
Removes a user from the blocked list.

### Contact Management

#### add-contact
```clarity
(add-contact (contact-user principal) (nickname (string-ascii 50)) (trust-level uint))
```
Adds a trusted contact with a nickname and trust level.

#### remove-contact
```clarity
(remove-contact (contact-user principal))
```
Removes a contact from the trusted list.

### Thread Management

#### create-thread
```clarity
(create-thread (participants (list 10 principal)) (privacy-level uint))
```
Creates a group conversation thread with specified participants.

#### update-thread-status
```clarity
(update-thread-status (thread-id uint) (active bool))
```
Activates or deactivates a thread. Only the thread creator can perform this action.

### Administrative Functions (Owner Only)

#### set-platform-status
```clarity
(set-platform-status (active bool))
```
Enables or disables the platform.

#### set-maintenance-mode
```clarity
(set-maintenance-mode (enabled bool))
```
Toggles maintenance mode.

#### emergency-shutdown
```clarity
(emergency-shutdown (reason (string-ascii 200)))
```
Performs an emergency shutdown with a reason.

## Read-Only Functions

### Message Retrieval

#### get-message
```clarity
(get-message (msg-id uint))
```
Retrieves a message by ID.

#### get-sent-messages
```clarity
(get-sent-messages (sender principal) (limit uint) (offset uint))
```
Gets paginated sent messages for a sender. Only accessible by the sender.

#### get-received-messages
```clarity
(get-received-messages (recipient principal) (limit uint) (offset uint))
```
Gets paginated received messages for a recipient. Only accessible by the recipient.

#### get-thread-messages
```clarity
(get-thread-messages (thread-id uint) (limit uint) (offset uint))
```
Gets paginated messages from a thread. Only accessible by thread participants.

### User Information

#### get-user-profile
```clarity
(get-user-profile (user principal))
```
Retrieves a user's profile information.

#### get-contact
```clarity
(get-contact (owner principal) (contact principal))
```
Gets contact details for a specific contact relationship.

#### is-user-blocked
```clarity
(is-user-blocked (blocker principal) (target principal))
```
Checks if a user is blocked by another user.

### Thread Information

#### get-thread
```clarity
(get-thread (thread-id uint))
```
Retrieves thread details.

#### is-thread-active
```clarity
(is-thread-active (thread-id uint))
```
Checks if a thread is active.

### Platform Information

#### get-message-count
```clarity
(get-message-count)
```
Returns the total number of messages sent.

#### is-platform-operational
```clarity
(is-platform-operational)
```
Checks if the platform is operational (active and not in maintenance mode).

#### get-platform-info
```clarity
(get-platform-info)
```
Returns comprehensive platform information including version, message count, and status.

#### get-platform-stats
```clarity
(get-platform-stats)
```
Returns platform statistics including message count and uptime.

#### get-admin-info
```clarity
(get-admin-info)
```
Returns administrative information including owner and platform status.

## Data Structures

### Message
```clarity
{
    sender: principal,
    recipient: principal,
    content: (string-ascii 1000),
    timestamp: uint,
    is-quantum-encrypted: bool,
    thread-id: (optional uint),
    priority: uint
}
```

### User Profile
```clarity
{
    display-name: (string-ascii 50),
    public-key: (optional (string-ascii 100)),
    created-at: uint,
    privacy-level: uint,
    status: (string-ascii 20)
}
```

### Blocked User
```clarity
{
    blocked-at: uint,
    reason: (string-ascii 100)
}
```

### Contact
```clarity
{
    nickname: (string-ascii 50),
    added-at: uint,
    trust-level: uint,
    category: (string-ascii 20)
}
```

### Thread
```clarity
{
    creator: principal,
    participants: (list 10 principal),
    created-at: uint,
    privacy-level: uint,
    is-active: bool
}
```

## Security Considerations

- All message sending operations check for blocked users
- Platform operations can be disabled for maintenance or emergencies
- Thread access is restricted to participants and creators
- Profile updates and contact management require authentication
- Owner-only functions are protected with authorization checks

## Usage Examples

### Creating a Profile
```clarity
(contract-call? .secure-messenger create-profile "Alice" (some "public-key-123") u5)
```

### Sending a Message
```clarity
(contract-call? .secure-messenger send-message 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "Hello, secure world!" true none u1)
```

### Blocking a User
```clarity
(contract-call? .secure-messenger block-user 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "spam")
```

### Creating a Group Thread
```clarity
(contract-call? .secure-messenger create-thread (list 'ST1... 'ST2... 'ST3...) u3)
```