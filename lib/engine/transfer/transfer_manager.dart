import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../protocol/messages.dart';
import '../peers/device_identity.dart';
import '../peers/peer_registry.dart'; // Import

class TransferManager {
  final DeviceIdentity identity;
  final PeerRegistry peerRegistry; // Registry

  final StreamController<ClipboardMessage> _incomingController =
      StreamController.broadcast();

  Stream<ClipboardMessage> get onMessage => _incomingController.stream;

  // We no longer manually manage "knownPeers" list here, we rely on PeerRegistry
  // But PeerRegistry stores persistent data. Discovery updates it.

  TransferManager(this.identity, this.peerRegistry);

  void updatePeers(List<DiscoveryMessage> peers) {
    // Legacy: No longer needed effectively if Engine updates Registry directly.
    // Keeping for potential optimization or pure discovery mode messages.
  }

  Future<void> sendToAll(ClipboardMessage message) async {
    // Iterate over PERSISTED & PAIRED devices
    for (final device in peerRegistry.devices) {
      // Filter: AutoSync check or Manual?
      // If this confusingly named "start()" call triggers it, it's auto-sync.
      // But wait, the UI "Send" button calls this too.
      // Let's assume sendToAll is manual or auto-sync triggered.
      // Design requirement: "Ones with auto sync should automatically get clipboard content".
      // So we need `sendToDevice(id, msg)` and `sendToAllAutoSync(msg)`.

      // For now, if we call "sendToAll", we imply standard sync.
      // But if this is triggered by `ClipboardManager` (Auto Sync), we should check `autoSync` flag.
      // Let's refactor: `sendToAll(msg)` sends to ALL paired (Manual Sync broadcast).
      // `sendToAutoSync(msg)` sends only to those enabled.

      // Current Implementation: Just sends to all.
      // Let's conform to design: "The ones with auto sync should automatically get clipboard content".
      // This implies filtering.

      if (device.autoSync) {
        _sendToPeer(device.lastSeenIp, device.lastSeenPort, message);
      }
    }
  }

  Future<void> sendManual(ClipboardMessage message, String deviceId) async {
    final device = peerRegistry.getDevice(deviceId);
    if (device != null) {
      _sendToPeer(device.lastSeenIp, device.lastSeenPort, message);
    }
  }

  Future<void> _sendToPeer(
    String host,
    int port,
    ClipboardMessage message,
  ) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      final jsonStr = jsonEncode(message.toJson());
      socket.write(jsonStr);
      await socket.flush();
      socket.close();
      print("Sent clipboard to $host:$port");
    } catch (e) {
      print("Failed to send to $host:$port : $e");
    }
  }

  void handleIncoming(ClipboardMessage message) {
    if (message.sourceDeviceId == identity.deviceId) {
      return;
    }

    // Check if source is paired?
    if (!peerRegistry.isPaired(message.sourceDeviceId)) {
      print(
        "Ignored clipboard from unpaired device: ${message.sourceDeviceId}",
      );
      return;
    }

    _incomingController.add(message);
  }
}
