# uniclip

![uniclip banner](assets/banner.png)

**LAN Clipboard Sync. No Cloud. No Accounts. Just Speed.**

Uniclip is a privacy-first, LAN-only clipboard synchronization tool designed for Android, Windows, and Linux. Seamlessly share text and images between your devices without sending data to the cloud.

---

## Imagine This

You copy a code snippet on your laptop.
You paste it on your phone.
Instantly.
No internet required.

---

## Why uniclip?

### 🔒 Privacy First

Your clipboard data never leaves your local network. No external servers, no cloud storage, no accounts to manage.

### ⚡ Blazing Fast

Uses direct TCP connections for transfer. Text is instant. Images are optimized.

### 📱 Cross-Platform

Works natively on:

- **Android**: Background sync & quick tiles.
- **Windows**: Seamless integration.
- **Linux**: Supports X11 & Wayland.

### 🔗 Trust-Based Pairing

Explicit pairing with a 6-digit code. Trust on first use, secure forever.

---

## Features

- **Text & Image Sync**: Copy on one device, paste on another.
- **Auto-Sync**: (Optional) Automatically push changes as you copy.
- **Device Discovery**: Automatically finds devices on your Wi-Fi.
- **Battery Friendly**: No heavy background processes.

---

## Architecture

See [uniclip.md](uniclip.md) for a deep dive into the architecture, protocol, and design philosophy.

## Getting Started

1.  **Clone the repository**
2.  **Run with Flutter**
    ```bash
    flutter run
    ```

## License

MIT
