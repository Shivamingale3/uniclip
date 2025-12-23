import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../protocol/messages.dart';
import '../peers/device_identity.dart';
import '../peers/peer_registry.dart'; // Import

enum PairingState { idle, pairing, confirming, paired, failed }

class PairingManager {
  final DeviceIdentity identity;
  final PeerRegistry peerRegistry; // Registry

  final StreamController<PairingEvent> _eventController =
      StreamController.broadcast();

  Stream<PairingEvent> get events => _eventController.stream;

  PairingState _state = PairingState.idle;
  String? _currentCode;
  Socket? _currentSocket;
  // Temporary peer info storage during handshake
  String? _pendingPeerId;
  String? _pendingPeerName;
  String? _pendingPeerOs;
  int _pendingPeerPort = 0;

  // New field for local port
  int localPort = 0;

  PairingManager(this.identity, this.peerRegistry);

  void handleDataOnce(Socket socket, List<int> data) {
    _currentSocket = socket;
    _state = PairingState.pairing;
    _handleData(socket, data);
  }

  void initiatePairing(String host, int port) async {
    try {
      print("Initiating pairing to $host:$port");
      _state = PairingState.pairing;
      final socket = await Socket.connect(host, port);
      _currentSocket = socket;
      // Storing port for pending info
      _pendingPeerPort = port;

      socket.listen(
        (data) {
          _handleData(socket, data);
        },
        onError: (e) {
          print("Pairing socket error: $e");
          _reset();
        },
        onDone: () => _reset(),
      );

      final hello = HelloMessage(
        version: 1,
        deviceId: identity.deviceId,
        deviceName: identity.deviceName,
        os: identity.os,
        tcpPort: localPort, // SENDING LOCAL PORT
      );

      _sendJson(socket, hello.toJson());
    } catch (e) {
      print("Pairing connection failed: $e");
      _eventController.add(
        PairingEvent(PairingEventType.error, "Could not connect to device"),
      );
      _reset();
    }
  }

  void confirmPairing(bool accept) {
    if (_state != PairingState.confirming) return;

    // Include identity in confirmation so initiator knows who accepted
    final msg = PairConfirmMessage(
      accepted: accept,
      deviceId: identity.deviceId,
      deviceName: identity.deviceName,
      os: identity.os,
    );

    if (_currentSocket != null) {
      _sendJson(_currentSocket!, msg.toJson());
    }

    if (accept) {
      _finalizePairing();
    } else {
      _reset();
    }
  }

  void _handleData(Socket socket, List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final json = jsonDecode(jsonString);

      if (json['type'] == 'HELLO') {
        final msg = HelloMessage.fromJson(json);
        _pendingPeerId = msg.deviceId;
        _pendingPeerName = msg.deviceName;
        _pendingPeerOs = msg.os;
        // Now extracting port from HELLO
        _pendingPeerPort = msg.tcpPort ?? 0;

        _currentCode = _generateCode();
        _state = PairingState.confirming;
        _eventController.add(
          PairingEvent(PairingEventType.codeDisplay, _currentCode),
        );
      } else if (json['type'] == 'PAIR_CONFIRM') {
        final msg = PairConfirmMessage.fromJson(json);
        if (msg.accepted) {
          // We are the initiator, receiving confirmation.
          // Use the info from the message if available
          if (msg.deviceId != null) {
            _pendingPeerId = msg.deviceId;
            _pendingPeerName = msg.deviceName;
            _pendingPeerOs = msg.os;
          }
          _finalizePairing();
        } else {
          _eventController.add(
            PairingEvent(PairingEventType.error, "Pairing Rejected"),
          );
          _reset();
        }
      }
    } catch (e) {
      print("Error parsing data: $e");
    }
  }

  void _finalizePairing() async {
    _state = PairingState.paired;
    _eventController.add(
      PairingEvent(PairingEventType.success, "Paired successfully"),
    );

    if (_pendingPeerId != null && _pendingPeerName != null) {
      await peerRegistry.addOrUpdate(
        _pendingPeerId!,
        _pendingPeerName!,
        _pendingPeerOs ?? 'unknown',
        _currentSocket?.remoteAddress.address ?? '127.0.0.1',
        _pendingPeerPort,
      );
    }
    _reset();
  }

  void _sendJson(Socket socket, Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    socket.write(jsonString);
    socket.flush();
  }

  void _reset() {
    _state = PairingState.idle;
    _currentSocket?.close();
    _currentSocket = null;
    _currentCode = null;
    // Don't clear pending immediately if needed for finalize, but handled above
  }

  String _generateCode() {
    final r = Random();
    return (100000 + r.nextInt(900000)).toString();
  }
}

enum PairingEventType { codeDisplay, error, success }

class PairingEvent {
  final PairingEventType type;
  final dynamic data;

  PairingEvent(this.type, this.data);
}
