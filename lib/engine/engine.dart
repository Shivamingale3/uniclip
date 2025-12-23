import 'dart:convert';
import 'dart:io';
import 'discovery/udp_discovery.dart';
import 'pairing/pairing_manager.dart';
import 'peers/device_identity.dart';
import 'peers/peer_registry.dart'; // Import
import 'transport/tcp_server.dart';
import 'clipboard/clipboard_manager.dart';
import 'transfer/transfer_manager.dart';
import 'protocol/messages.dart';

class Engine {
  static final Engine _instance = Engine._internal();

  factory Engine() => _instance;

  final DeviceIdentity identity = DeviceIdentity();
  final TcpServer tcpServer = TcpServer();
  final PeerRegistry peerRegistry = PeerRegistry(); // Initialize
  late final PairingManager pairingManager;
  late final UdpDiscovery discovery;
  late final TransferManager transferManager;
  late final ClipboardManager clipboardManager;

  Engine._internal() {
    pairingManager = PairingManager(identity, peerRegistry); // Pass registry
    transferManager = TransferManager(identity, peerRegistry); // Pass registry
    clipboardManager = ClipboardManager(identity, transferManager);
  }

  Future<void> start() async {
    await identity.initialize();
    await peerRegistry.load(); // Load peers

    await tcpServer.start();
    pairingManager.localPort = tcpServer.port;
    tcpServer.onConnection.listen(_handleIncomingConnection);

    discovery = UdpDiscovery(identity, tcpServer.port);
    await discovery.start();

    discovery.messages.listen((msg) {
      // Just keeping registry info updated?
      // If paired, update IP/Port implicitly?
      // For now, let Pairing/Transfer update registry explicitly.
      // OR: If msg.deviceId is in registry, update its IP/Port.
      if (peerRegistry.isPaired(msg.deviceId)) {
        peerRegistry.addOrUpdate(
          msg.deviceId,
          msg.deviceName,
          msg.os,
          msg.sourceIp ?? '127.0.0.1',
          msg.tcpPort,
        );
      }
    });

    clipboardManager.start();

    print("Engine started. Device ID: ${identity.deviceId}");
  }

  void _handleIncomingConnection(Socket socket) {
    socket.listen(
      (data) {
        try {
          final jsonString = utf8.decode(data);
          final json = jsonDecode(jsonString);

          if (json['type'] == 'HELLO' || json['type'] == 'PAIR_CONFIRM') {
            pairingManager.handleDataOnce(socket, data);
          } else if (json['type'] == 'CLIPBOARD') {
            final msg = ClipboardMessage.fromJson(json);
            transferManager.handleIncoming(msg);
            socket.close();
          }
        } catch (e) {
          print("Dispatch error: $e");
          socket.close();
        }
      },
      onError: (e) => socket.close(),
      onDone: () => socket.close(),
    );
  }

  Future<void> updateDeviceName(String newName) async {
    await identity.setDeviceName(newName);
    // Restart discovery to broadcast new name
    discovery.stop();
    await discovery.start();
  }

  void stop() {
    discovery.stop();
    tcpServer.stop();
    clipboardManager.stop();
  }
}
