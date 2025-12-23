import 'package:flutter/material.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/engine/peers/peer_registry.dart';
import 'package:uniclip/engine/pairing/pairing_manager.dart';
import 'package:uniclip/ui/pairing/pairing_screen.dart';

class UniclipZoneScreen extends StatefulWidget {
  const UniclipZoneScreen({super.key});

  @override
  State<UniclipZoneScreen> createState() => _UniclipZoneScreenState();
}

class _UniclipZoneScreenState extends State<UniclipZoneScreen>
    with WidgetsBindingObserver {
  List<PairedDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    Engine().pairingManager.events.listen((e) {
      if (e.type == PairingEventType.success) {
        _refresh();
      }
    });
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _devices = List.from(Engine().peerRegistry.devices);
      _devices.sort((a, b) => b.lastPairedAt.compareTo(a.lastPairedAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Header instead of AppBar for cleaner look
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Uniclip Zone',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PairingScreen(),
                          ),
                        );
                        _refresh();
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _devices.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: _devices.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(_devices[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hub_outlined,
              size: 48,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your zone is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pair devices to sync clipboard instantly.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PairingScreen()),
              );
              _refresh();
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Device"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(PairedDevice device) {
    return Card(
      // Global Theme handles shape and color
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    device.os.contains('android')
                        ? Icons.phone_android
                        : device.os.contains('ios')
                        ? Icons.phone_iphone
                        : Icons.laptop,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${device.os} • ${device.lastSeenIp}",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: device.autoSync,
                    onChanged: (val) async {
                      await Engine().peerRegistry.toggleAutoSync(device.id);
                      _refresh();
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Unpair Device?"),
                          content: Text(
                            "Do you want to remove ${device.name}?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text(
                                "Unpair",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await Engine().peerRegistry.unpair(device.id);
                        _refresh();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.red.shade300,
                      side: BorderSide(
                        color: Colors.red.shade900.withOpacity(0.5),
                      ),
                    ),
                    child: const Text("Unpair"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Engine().clipboardManager.forceSyncTo(device.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sending clipboard...")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Sync Now"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
