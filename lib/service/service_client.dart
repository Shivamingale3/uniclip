import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/engine/peers/peer_registry.dart';
import 'package:uniclip/engine/protocol/messages.dart';
import 'package:uniclip/engine/pairing/pairing_manager.dart';

class ServiceClient {
  static final ServiceClient _instance = ServiceClient._internal();
  factory ServiceClient() => _instance;

  // Clipboard Stream
  final StreamController<String> _clipboardController =
      StreamController.broadcast();
  Stream<String> get clipboardStream => _clipboardController.stream;

  // Paired Devices Stream
  final StreamController<List<PairedDevice>> _peersController =
      StreamController<List<PairedDevice>>.broadcast();
  Stream<List<PairedDevice>> get peersStream => _peersController.stream;
  List<PairedDevice> _lastKnownPeers = [];
  List<PairedDevice> get peers => _lastKnownPeers;

  // Discovery Stream (Scanned Devices)
  final StreamController<DiscoveryMessage> _discoveryController =
      StreamController.broadcast();
  Stream<DiscoveryMessage> get discoveryStream => _discoveryController.stream;

  // Pairing Events Stream
  final StreamController<PairingEvent> _pairingController =
      StreamController.broadcast();
  Stream<PairingEvent> get pairingStream => _pairingController.stream;

  ServiceClient._internal() {
    if (Platform.isAndroid || Platform.isIOS) {
      _initMobile();
    } else {
      _initDesktop();
    }
  }

  void _initDesktop() {
    // Clipboard
    Engine().clipboardManager.contentStream.listen((content) {
      _clipboardController.add(content);
    });

    // Peers
    Engine().peerRegistry.devicesStream.listen((devices) {
      _lastKnownPeers = devices;
      _peersController.add(devices);
    });
    Future.delayed(Duration.zero, () {
      _lastKnownPeers = Engine().peerRegistry.devices;
      _peersController.add(_lastKnownPeers);
    });

    // Discovery
    Engine().discovery.messages.listen((msg) {
      _discoveryController.add(msg);
    });

    // Pairing
    Engine().pairingManager.events.listen((event) {
      _pairingController.add(event);
    });
  }

  void _initMobile() {
    final service = FlutterBackgroundService();

    // Clipboard
    service.on('clipboard_update').listen((event) {
      if (event != null && event['content'] != null) {
        _clipboardController.add(event['content'] as String);
      }
    });

    // Peers
    service.on('peers_update').listen((event) {
      if (event != null && event['devices'] != null) {
        final List<dynamic> jsonList = jsonDecode(event['devices'] as String);
        final devices = jsonList.map((j) => PairedDevice.fromJson(j)).toList();
        _lastKnownPeers = devices;
        _peersController.add(devices);
      }
    });

    // Discovery
    service.on('discovery_update').listen((event) {
      if (event != null && event['message'] != null) {
        try {
          final msg = DiscoveryMessage.fromJson(jsonDecode(event['message']));
          _discoveryController.add(msg);
        } catch (e) {
          print("Error parsing discovery message: $e");
        }
      }
    });

    // Pairing
    service.on('pairing_update').listen((event) {
      if (event != null && event['event'] != null) {
        // Need PairingEvent.fromJson or similar. Wait, PairingEvent stores generic data.
        // We'll need to reconstruct it manually or add serialization to PairingEvent.
        // For now, let's assume we pass type and data separately.
        try {
          final typeIndex = event['type'] as int;
          final data = event['data'];
          _pairingController.add(
            PairingEvent(PairingEventType.values[typeIndex], data),
          );
        } catch (e) {
          print("Error parsing pairing event: $e");
        }
      }
    });
  }

  void initiatePairing(String ip, int port) {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke('initiate_pairing', {
        'ip': ip,
        'port': port,
      });
    } else {
      Engine().pairingManager.initiatePairing(ip, port);
    }
  }

  void confirmPairing(bool accept) {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke('confirm_pairing', {'accept': accept});
    } else {
      Engine().pairingManager.confirmPairing(accept);
    }
  }

  Future<void> updateDeviceName(String name) async {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke('update_name', {'name': name});
    } else {
      await Engine().updateDeviceName(name);
    }
  }
}
