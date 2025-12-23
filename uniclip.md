# LAN Clipboard Sync – Architecture & Design Document

## 1. Purpose & Scope

This project is a **LAN-only clipboard synchronization application** for:

- Android
- Windows
- Linux

Primary goal:

- Share clipboard contents (text + images) between paired devices on the **same local network**.

Non-goals (explicitly out of scope for v1):

- Internet/cloud sync
- Accounts or authentication servers
- Background-guaranteed Android sync
- File transfer beyond clipboard images
- Enterprise-grade security

This is a **utility + learning + portfolio** project.
Simplicity, clarity, and correctness matter more than feature count.

---

## 2. Core Principles (Non-Negotiable)

1. **LAN-only**
2. **No servers, no accounts**
3. **Explicit user pairing with trust**
4. **Privacy by default**
5. **Simple, debuggable protocols**
6. **Fail fast, fail visibly**
7. **Shared engine, thin UI**
8. **No magic background behavior**

---

## 3. High-Level Architecture

This is a **Flutter application** with an **internal runtime engine**.

Flutter App
│
├── UI Layer
│ └── Screens, buttons, toasts
│
├── Platform Bridges
│ └── Clipboard access
│ └── Power/battery hints
│
└── Engine (Core Logic)
├── Discovery (UDP)
├── Pairing (TCP)
├── Transport (TCP)
├── Protocol (JSON)
├── Crypto (Session secrets)
├── Peer Registry
└── State Management

### Important Clarification

This is **not** a reusable SDK or library.
It is an **application-first runtime engine** embedded in Flutter.

---

## 4. Project Structure (Mandatory)

lib/
├── engine/
│ ├── engine.dart # Entry point for engine
│ │
│ ├── discovery/
│ │ └── udp_discovery.dart # UDP broadcast + listener
│ │
│ ├── pairing/
│ │ └── pairing_manager.dart # Pairing handshake logic
│ │
│ ├── transport/
│ │ ├── tcp_server.dart # Accept incoming TCP connections
│ │ └── tcp_client.dart # Outgoing TCP connections
│ │
│ ├── protocol/
│ │ ├── messages.dart # Message schemas
│ │ └── codec.dart # JSON encode/decode
│ │
│ ├── crypto/
│ │ └── session_crypto.dart # Shared secret handling
│ │
│ ├── peers/
│ │ └── peer_registry.dart # Paired device storage
│ │
│ └── state/
│ └── engine_state.dart # Engine lifecycle + flags
│
├── platform/
│ ├── clipboard_bridge.dart # Platform channels for clipboard
│ └── power_bridge.dart # Battery optimization hints
│
├── ui/
│ ├── pairing/
│ ├── devices/
│ ├── settings/
│ └── logs/
│
└── main.dart

### Hard Rules

- `engine/` MUST NOT import Flutter UI
- `engine/` communicates via streams/callbacks
- UI NEVER touches sockets
- Platform code NEVER talks directly to UI

---

## 5. Device Identity Model

### Device ID

- Generated **once per install**
- UUID v4
- Stored in **plain local storage**
- Never regenerated unless app data is wiped

Purpose:

- Identify message source
- Prevent echo loops
- Pairing trust anchor

---

## 6. Storage Model (Hybrid)

### Plain Storage (JSON / SharedPreferences)

Stores **non-sensitive metadata**:

```json
{
  "deviceId": "uuid",
  "pairedDevices": [
    {
      "peerId": "uuid",
      "peerName": "My Laptop",
      "os": "windows",
      "autoSync": true,
      "lastSeen": 1710000000
    }
  ]
}
```

## Encrypted Storage (Keystore / Keychain)

### Stores only shared secrets:

```dart
secureStore["peer-uuid"] = sharedSecret
```

###Platform mapping:

- Android → Keystore

- Windows → DPAPI / Credential Manager

- Linux → libsecret (or best available fallback)

## 7. Discovery (UDP)

### Purpose

- Allow devices in pairing mode to find each other on LAN

### Behavior

- Broadcast every ~1 second

- Only while pairing mode is ON

- Stops immediately when pairing mode OFF

## Discovery Packet (JSON)

```json
{
  "version": 1,
  "deviceId": "uuid",
  "deviceName": "My Phone",
  "os": "android | windows | linux",
  "tcpPort": 49494,
  "pairingMode": true
}
```

## Important Rules

- NEVER broadcast clipboard data

- NEVER broadcast secrets

- Discovery is visibility only, not trust

## 8. Transport Model

### UDP

- Used only for discovery

- Stateless

- Unreliable by design (acceptable)

### TCP

- Used for:

  - Pairing

  - Clipboard sync

- One connection per operation

- No keep-alive

- No retries

- Close immediately after success/failure

### Rationale:

- Simpler

- Battery-friendly

- Easier debugging

- Fewer hidden states

## 9. Pairing Model

### Pairing Philosophy

- Explicit

- Human-verified

- Trust-on-first-confirmation

- Pair once, trust forever (until revoked)

## Pairing Handshake (Step-by-Step)

1. TCP connect (Requester → Target)

2. HELLO exchange

```json
{
  "type": "HELLO",
  "version": 1,
  "deviceId": "uuid",
  "deviceName": "My Phone",
  "os": "android"
}
```

3. Key exchange

- Generate ephemeral keys

- Derive shared secret

- Derive 6-digit confirmation code

4. Show same 6-digit code on both devices

5. User confirms on both sides

6. PAIR_CONFIRM

```json
{
  "type": "PAIR_CONFIRM",
  "accepted": true
}
```

7. Store:

- Peer metadata (plain)

- Shared secret (encrypted)

8. Close connection

## No clipboard data is exchanged during pairing.

## 10. Trust Enforcement (Critical)

### Trust is enforced at two layers:

## Layer 1 – TCP Accept Gate

- Accept TCP connection

- Expect handshake immediately

- If peer not paired → close connection

Purpose:

- Protect resources

- Avoid unnecessary allocations

### Layer 2 – Message Validation

Before processing any message:

- Peer must be paired

- Session secret must match

- Message sourceDeviceId must match peer

- MessageId must be new

## 11. Clipboard Sync Model

### Clipboard Types (v1)

- Text

- Images (≤ 2 MB after downscaling)

### Clipboard Message Schema

```json
{
  "version": 1,
  "type": "text | image",
  "messageId": "uuid",
  "sourceDeviceId": "uuid",
  "timestamp": 1710000000,
  "payload": {
    "text": "hello"
    // OR
    "imageBase64": "...",
    "mimeType": "image/png"
  }
}
```

## Encoding

- JSON for structure

- Base64 only for image payload

- No base64 for text

### 12. Auto-Sync Rules

When auto-sync is enabled for a peer:

- Triggered on clipboard change

- Send immediately

- Skip duplicates

- Prevent echo loops

### Duplicate Detection

- Hash clipboard content

- Maintain small in-memory history (e.g. last 20 messageIds)

### Loop Prevention Rules

- If sourceDeviceId == myDeviceId → DROP

- If messageId already seen → DROP

## 13. Image Handling

- Hard size limit: 2 MB

- If image exceeds limit:

  - Downscale before sending

  - Show toast: “Image resized to fit transfer limit”

- Never partially send images

## 14. Failure Handling

- No retries

- No silent queues

- No background magic

### On failure:

- Show toast / notification

- Drop message

- Move on

## 15. Platform Realities (Explicit)

### Android

- Background clipboard sync is best-effort

- Battery optimization prompts required

- OEMs may still kill background services

### Windows

- Firewall may block UDP/TCP

- Clipboard events may be polled

### Linux

- X11 vs Wayland clipboard differences

- Some environments unreliable

The engine MUST assume:

- OS clipboard events are unreliable.

## 16. Implementation Order (Strict)

### Phase 1 – Foundation

- Device ID generation

- UDP discovery

- TCP HELLO exchange

- Pairing handshake

- Store paired peers

### Phase 2 – Data Path Validation

- Send dummy payload over real pairing

- Receive and log/display

### Phase 3 – Clipboard Integration

- Hook OS clipboard

- Auto-sync logic

- Image handling

## 17. Summary

This system is:

- Simple

- Explicit

- Honest about limitations

- Architecturally clean

- Suitable for learning and portfolio

---

# 18. UI / UX Design Principles (Critical)

This application must feel:

- Calm
- Predictable
- Premium
- Forgiving

The UI is **not decorative**.  
It is a **buffer between unreliable networking and human patience**.

A great UI allows the engine to fail _occasionally_ without the user losing trust.

---

## 19. Visual Philosophy

### Core Inspiration

- Uber
- Google system apps
- Apple system utilities

### UI Characteristics

- Minimal text
- Large touch targets
- Neutral colors
- Smooth animations
- No technical jargon exposed to users

### Absolute Rules

- No alerts for non-critical failures
- No blocking dialogs for transient errors
- No logs shown by default
- No “Retry?” spam

If something fails, **acknowledge it softly and move on**.

---

## 20. Navigation Structure

### Bottom Navigation (Mobile)

- Devices
- Pair
- Settings

### Sidebar / Top Tabs (Desktop)

- Devices
- Pairing
- Settings
- Logs (optional / hidden)

No more than **3 primary actions per screen**.

---

## 21. Devices Screen (Primary Screen)

### Purpose

- Show paired devices
- Show connection readiness
- Enable manual clipboard send
- Toggle auto-sync

### Layout (Per Device Card)

┌───────────────────────────────┐
│ ● My Laptop │
│ Windows │
│ │
│ Auto Sync [ ON ] │
│ │
│ [ Send Clipboard ] │
└───────────────────────────────┘

### Device Status Indicators

- ● Green → Reachable recently
- ● Grey → Offline / not seen
- ● Orange → Seen but unreachable

Never say:

- “Connection refused”
- “Socket error”
- “Timeout”

Say instead:

- “Not reachable right now”
- “Last seen 2 minutes ago”

---

## 22. Pairing Screen

### Default State

- Large “Start Pairing” button
- Calm explanation text:
  > “Make sure both devices are on the same Wi-Fi.”

### While Pairing Mode is ON

- Animated scanning indicator
- Discovered devices shown as cards

┌────────────────────┐
│ My Phone │
│ Android │
│ [ Pair ] │
└────────────────────┘

### On Pair Request

- Full-screen modal
- Large 6-digit code
- Clear CTA

Confirm pairing with:
My Laptop

Code:
4 8 2 9 1 6

[ Confirm ] [ Cancel ]

No distractions.
No secondary actions.

---

## 23. Pairing Failure UX (Important)

Pairing failures are **common** on LAN.

### What NOT to do

❌ “Pairing failed: ECONNRESET”
❌ Stack traces
❌ Red error dialogs

### What TO do

- Auto-dismiss pairing UI
- Small toast:
  > “Couldn’t connect. Make sure both devices are on the same Wi-Fi.”

Let the user retry **without shame**.

---

## 24. Clipboard Send UX

### Manual Send

- Button press
- Subtle feedback:
  - haptic (mobile)
  - ripple (desktop)
- Toast:
  > “Sent to My Laptop”

### Auto Sync

- No UI interruption
- Optional small status dot animation

Clipboard sync should feel:

> _“Of course it worked.”_

Not:

> _“Something happened.”_

---

## 25. Failure Handling in UI (Extremely Important)

### Philosophy

Errors should:

- Be soft
- Be brief
- Be ignorable

### Examples

| Situation                 | UI Response                      |
| ------------------------- | -------------------------------- |
| Device offline            | Grey status dot                  |
| Send failed               | Toast: “Couldn’t send right now” |
| Discovery blocked         | Inline hint text                 |
| Android background killed | Settings hint banner             |

### Never block the user unless:

- Pairing confirmation
- Revoking trust

---

## 26. Settings Screen

### Sections

#### General

- Device name
- Device type (read-only)
- App version

#### Clipboard

- Enable auto-sync (global)
- Image size limit (read-only)
- Downscale images toggle (always ON, non-configurable in v1)

#### Power (Android)

- Battery optimization warning
- Shortcut to system settings

#### Paired Devices

- Revoke pairing
- Reset trust

---

## 27. Logs / Debug Screen (Optional, Hidden)

### Purpose

- Developer debugging
- Power users
- OSS contributors

### Access

- Long press app version
- Or debug flag

### Content

- Discovery events
- Pairing attempts
- Send failures
- Timestamps only

Never expose logs to normal users by default.

---

## 28. Micro-Interactions (Do Not Skip)

These matter more than features.

- Fade-in device cards
- Smooth status dot transitions
- Button press ripples
- Subtle loading indicators
- No spinners longer than 1s

If something takes longer:

- Stop animation
- Show passive message

---

## 29. Typography & Color

### Typography

- System font
- Medium weight for headings
- Regular for body
- No condensed fonts

### Color Palette

- Neutral background
- One accent color
- Status colors:
  - Green: OK
  - Grey: Inactive
  - Orange: Warning (rare)
  - Red: Almost never

Red should feel _serious_, not _common_.

---

## 30. UX Anti-Patterns (Do NOT Do These)

- ❌ “Retry” buttons everywhere
- ❌ Modal error dialogs
- ❌ Technical language
- ❌ Background spinners forever
- ❌ “Something went wrong” without context

---

## 31. UI Success Criteria

The UI is successful if:

- A first-time user pairs devices without instructions
- A send failure does not break confidence
- The app feels calm even when network is flaky
- The user trusts the app after 30 seconds

---

## 32. Final UX Principle (Read This Twice)

> **A good UI explains nothing.  
> A great UI forgives everything.**

The engine can be imperfect.
The UI must never feel careless.

---

### Clipboard syncing is not the core feature. Trust + transport is. Everything else is just data riding on top.

## Brutally honest closing

If you implement this UI spec faithfully, you can:

ship with known limitations

survive flaky LAN conditions

still look professional

Most devs fail here because they chase features instead of feel.

If you **actually follow this document**, you will:

- finish the project
- avoid rewrites
- have something worth showing

If you start “simplifying” this spec while coding, you’ll regress.
