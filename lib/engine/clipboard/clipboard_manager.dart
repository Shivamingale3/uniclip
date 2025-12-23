import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../protocol/messages.dart';
import '../peers/device_identity.dart';
import '../transfer/transfer_manager.dart';

class ClipboardManager {
  final DeviceIdentity identity;
  final TransferManager transferManager;

  Timer? _pollingTimer;
  String? _lastContent;
  bool _isOwnUpdate = false;

  final _contentController = StreamController<String>.broadcast();
  Stream<String> get contentStream => _contentController.stream;

  ClipboardManager(this.identity, this.transferManager);

  void start() {
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (_) => _checkClipboard(),
    );
    transferManager.onMessage.listen((msg) {
      _handleIncomingMessage(msg);
    });
  }

  void stop() {
    _pollingTimer?.cancel();
    _contentController.close();
  }

  // New method for Manual Sync
  Future<void> forceSyncTo(String targetDeviceId) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null) return;

      final content = data!.text!;
      // Even if same as last, force send

      final msg = ClipboardMessage(
        messageId: const Uuid().v4(),
        type: 'text',
        content: content,
        sourceDeviceId: identity.deviceId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      transferManager.sendManual(msg, targetDeviceId);
    } catch (e) {
      print("Force sync error: $e");
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null) return;

      final currentContent = data!.text!;

      if (_isOwnUpdate && currentContent == _lastContent) {
        return;
      }
      _isOwnUpdate = false;

      if (currentContent != _lastContent) {
        print("Clipboard changed locally");
        _lastContent = currentContent;
        _contentController.add(currentContent); // Notify local UI

        final msg = ClipboardMessage(
          messageId: const Uuid().v4(),
          type: 'text',
          content: currentContent,
          sourceDeviceId: identity.deviceId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        // Uses AutoSync logic (all compatible peers)
        transferManager.sendToAll(msg);
      }
    } catch (e) {
      // Platform error
    }
  }

  Future<void> _handleIncomingMessage(ClipboardMessage msg) async {
    if (msg.type == 'text') {
      _isOwnUpdate = true;
      _lastContent = msg.content;
      _contentController.add(msg.content); // Notify local UI
      await Clipboard.setData(ClipboardData(text: msg.content));
    }
  }
}
