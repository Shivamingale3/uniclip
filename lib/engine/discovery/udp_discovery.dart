import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../protocol/messages.dart';
import '../peers/device_identity.dart';

class UdpDiscovery {
  static const int discoveryPort = 49494;
  final DeviceIdentity identity;
  final int tcpPort; // Port the TCP server is listening on

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  final StreamController<DiscoveryMessage> _discoveryStream =
      StreamController.broadcast();

  Stream<DiscoveryMessage> get messages => _discoveryStream.stream;

  UdpDiscovery(this.identity, this.tcpPort);

  Future<void> start() async {
    // Stop if already running
    stop();

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handlePacket(datagram);
          }
        }
      });

      // Start broadcasting
      _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _sendBroadcast();
      });

      print('UDP Discovery started on port $discoveryPort');
    } catch (e) {
      print('Failed to bind UDP socket: $e');
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _socket = null;
  }

  Future<void> _sendBroadcast() async {
    if (_socket == null) return;

    List<String> ips = [];
    try {
      ips = await identity.getIpAddresses();
    } catch (e) {
      // Ignore
    }

    final message = DiscoveryMessage(
      version: 1,
      deviceId: identity.deviceId,
      deviceName: identity.deviceName,
      os: identity.os,
      tcpPort: tcpPort,
      pairingMode: true,
      ips: ips,
    );

    final jsonData = jsonEncode(message.toJson());
    final data = utf8.encode(jsonData);

    try {
      _socket!.send(data, InternetAddress('255.255.255.255'), discoveryPort);
    } catch (e) {
      print('Broadcast error: $e');
    }
  }

  void _handlePacket(Datagram datagram) {
    try {
      final jsonString = utf8.decode(datagram.data);
      final json = jsonDecode(jsonString);
      final message = DiscoveryMessage.fromJson(json);

      // Ignore own messages
      if (message.deviceId == identity.deviceId) return;

      // Attach source IP
      String remoteIp = datagram.address.address;
      print("Discovery: Packet from $remoteIp. Payload IPs: ${message.ips}");

      // If remote appears as loopback (127.0.0.1) but payload has IPs, use first valid one
      if ((remoteIp == '127.0.0.1' || remoteIp == '::1') &&
          message.ips != null &&
          message.ips!.isNotEmpty) {
        final validIp = message.ips!.firstWhere(
          (ip) => ip != '127.0.0.1' && ip != '::1',
          orElse: () => remoteIp,
        );
        print("Discovery: Substituting $remoteIp with $validIp");
        remoteIp = validIp;
      }

      final messageWithIp = message.copyWithIp(remoteIp);

      _discoveryStream.add(messageWithIp);
    } catch (e) {
      print("Discovery Error: $e");
    }
  }
}
