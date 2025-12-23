import 'dart:async';
import 'dart:io';

class TcpServer {
  ServerSocket? _serverSocket;
  int _port = 0;

  int get port => _port;

  final StreamController<Socket> _connectionController =
      StreamController.broadcast();
  Stream<Socket> get onConnection => _connectionController.stream;

  Future<void> start() async {
    try {
      // Bind to any available port (0)
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      _port = _serverSocket!.port;

      print('TCP Server listening on port $_port');

      _serverSocket!.listen((Socket socket) {
        print('Incoming connection from ${socket.remoteAddress.address}');
        _connectionController.add(socket);
      });
    } catch (e) {
      print('Failed to bind TCP server: $e');
      rethrow;
    }
  }

  void stop() {
    _serverSocket?.close();
    _serverSocket = null;
  }
}
