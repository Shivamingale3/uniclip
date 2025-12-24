import 'package:flutter/material.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/engine/pairing/pairing_manager.dart';
import 'package:uniclip/engine/protocol/messages.dart';
import 'pairing_code_dialog.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final List<DiscoveryMessage> _peers = [];

  @override
  void initState() {
    super.initState();
    Engine().discovery.messages.listen((message) {
      if (mounted) {
        setState(() {
          final index = _peers.indexWhere(
            (p) => p.deviceId == message.deviceId,
          );
          if (index != -1) {
            _peers[index] = message;
          } else {
            _peers.add(message);
          }
        });
      }
    });

    Engine().pairingManager.events.listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case PairingEventType.codeDisplay:
          _showPairingDialog(event.data as String);
          break;
        case PairingEventType.success:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.data.toString()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          break;
        case PairingEventType.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.data.toString()),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    });
  }

  void _showPairingDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PairingCodeDialog(
        code: code,
        onConfirm: () {
          Engine().pairingManager.confirmPairing(true);
          Navigator.of(context).pop();
        },
        onCancel: () {
          Engine().pairingManager.confirmPairing(false);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _initiatePairing(DiscoveryMessage peer) {
    Engine().pairingManager.initiatePairing(
      peer.sourceIp ?? '127.0.0.1',
      peer.tcpPort,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Looking for devices on the local network...\nEnsure privacy is safe.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),

          if (_peers.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _peers.length,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final peer = _peers[index];
                  return _buildPeerTile(peer);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeerTile(DiscoveryMessage peer) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.deviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${peer.os} • ${peer.sourceIp}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _initiatePairing(peer),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text("PAIR"),
          ),
        ],
      ),
    );
  }
}
