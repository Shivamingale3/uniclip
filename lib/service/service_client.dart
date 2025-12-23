import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/engine/peers/peer_registry.dart';

class ServiceClient {
  static final ServiceClient _instance = ServiceClient._internal();
  factory ServiceClient() => _instance;

  final StreamController<String> _clipboardController =
      StreamController.broadcast();
  Stream<String> get clipboardStream => _clipboardController.stream;

  final StreamController<List<PairedDevice>> _peersController =
      StreamController<List<PairedDevice>>.broadcast();
  Stream<List<PairedDevice>> get peersStream => _peersController.stream;
  List<PairedDevice> _lastKnownPeers = [];
  List<PairedDevice> get peers => _lastKnownPeers;

  ServiceClient._internal() {
    if (Platform.isAndroid || Platform.isIOS) {
      _initMobile();
    } else {
      _initDesktop();
    }
  }

  void _initDesktop() {
    Engine().clipboardManager.contentStream.listen((content) {
      _clipboardController.add(content);
    });

    // Direct Peer Access
    Engine().peerRegistry.devicesStream.listen((devices) {
      _lastKnownPeers = devices;
      _peersController.add(devices);
    });
    // Load initial state
    Future.delayed(Duration.zero, () {
      _lastKnownPeers = Engine().peerRegistry.devices;
      _peersController.add(_lastKnownPeers);
    });
  }

  void _initMobile() {
    FlutterBackgroundService().on('clipboard_update').listen((event) {
      if (event != null && event['content'] != null) {
        _clipboardController.add(event['content'] as String);
      }
    });

    FlutterBackgroundService().on('peers_update').listen((event) {
      if (event != null && event['devices'] != null) {
        final List<dynamic> jsonList = jsonDecode(event['devices'] as String);
        final devices = jsonList.map((j) => PairedDevice.fromJson(j)).toList();
        _lastKnownPeers = devices;
        _peersController.add(devices);
      }
    });
  }

  // --- Actions ---

  Future<void> updateDeviceName(String name) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // TODO: Send to service
      // FlutterBackgroundService().invoke('update_name', {'name': name});
    } else {
      await Engine().updateDeviceName(name);
    }
  }

  // Expose Peer Registry somewhat?
  // For now, UI polls PeerRegistry.
  // On Mobile, PeerRegistry in UI Isolate is EMPTY.
  // We need to sync PeerList too.
}
