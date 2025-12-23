import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/engine/peers/peer_registry.dart';
import 'package:uniclip/engine/pairing/pairing_manager.dart';
import 'package:uniclip/ui/pairing/scanner_screen.dart';
import '../widgets/skeuo_widgets.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:system_tray/system_tray.dart';
import 'package:uniclip/service/service_client.dart';

class UniclipDeskScreen extends StatefulWidget {
  const UniclipDeskScreen({super.key});

  @override
  State<UniclipDeskScreen> createState() => _UniclipDeskScreenState();
}

class _UniclipDeskScreenState extends State<UniclipDeskScreen>
    with WindowListener {
  String _clipboardContent = "WAITING FOR SIGNAL...";
  List<PairedDevice> _devices = [];

  // New state variables for system tray and window management
  // final SystemTray _systemTray = SystemTray();
  // final AppWindow _appWindow = AppWindow();

  @override
  void initState() {
    super.initState();
    // Add window listener and system tray initialization for desktop platforms
    // Desktop window management - Disabled until SystemTray update
    // if (!Platform.isAndroid && !Platform.isIOS) {
    //   windowManager.addListener(this);
    //   _initSystemTray();
    // }

    _refresh(); // Initial refresh for devices
    Engine().pairingManager.events.listen((e) {
      if (e.type == PairingEventType.success) {
        _refresh();
      }
    });

    // Listen to the stream for ALL updates (local + remote)
    ServiceClient().clipboardStream.listen((content) {
      setState(() {
        _clipboardContent = content;
      });
    });

    // Listen to peers
    ServiceClient().peersStream.listen((peers) {
      setState(() {
        _devices = peers;
      });
    });
  }

  /*
  Future<void> _initSystemTray() async {
    String iconPath = Platform.isWindows
        ? 'assets/app_icon.ico'
        : 'assets/app_icon.png';
    // Note: requires assets configuration. For now relying on default or package assets if present.
    // Using simple approach first.

    await _systemTray.initSystemTray(title: "Uniclip", iconPath: iconPath);

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(label: 'Quit', onClicked: (menuItem) => _appWindow.close()),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? _appWindow.show() : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? _systemTray.popUpContextMenu() : _appWindow.show();
      }
    });
  }

  @override
  void onWindowClose() async {
    // Minimize to tray
    await _appWindow.hide();
  }
  */

  @override
  void dispose() {
    // windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _devices = List.from(Engine().peerRegistry.devices);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Cyberdeck casing
      body: Stack(
        children: [
          // Background Texture (Carbon Fiber / Industrial Plastic)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.2,
                colors: [Color(0xFF222222), Color(0xFF111111), Colors.black],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _showEditNameDialog,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Engine().identity.deviceName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.green.withOpacity(0.1),
                                  ),
                                  child: const Text(
                                    "IDENTITY",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit,
                                  color: Colors.green.withOpacity(0.5),
                                  size: 16,
                                ),
                              ],
                            ),
                            Text(
                              Engine().identity.os.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildStatusLight(true),
                          const SizedBox(width: 8),
                          const Text(
                            "SYSTEM ONLINE",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // MAIN DISPLAY (CRT)
                // Now shows _clipboardContent updated via stream
                SkeuoCRT(content: _clipboardContent, height: 200),

                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 24, 24, 8),
                  child: Text(
                    "DEVICE CONTROL RACK",
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                ),

                // DEVICE RACK
                Expanded(
                  child: _devices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (c, i) {
                            final device = _devices[i];
                            return SkeuoControlModule(
                              deviceName: device.name,
                              osType: device.os, // Pass OS type for icon
                              status: "${device.os} : ${device.lastSeenIp}",
                              isAutoSync: device.autoSync,
                              onAutoSyncChanged: (val) async {
                                await Engine().peerRegistry.toggleAutoSync(
                                  device.id,
                                );
                                _refresh();
                              },
                              onManualSync: () async {
                                // Use forceSyncTo from Engine
                                await Engine().clipboardManager.forceSyncTo(
                                  device.id,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Signal Transmitted"),
                                    ),
                                  );
                                }
                              },
                              onUnpair: () async {
                                await Engine().peerRegistry.unpair(device.id);
                                _refresh();
                              },
                            );
                          },
                        ),
                ),

                // BOTTOM CONTROLS
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SkeuoButton(
                    color: const Color(0xFF222222),
                    height: 50,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerScreen(),
                        ),
                      );
                      _refresh();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.radar, color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "INITIATE SCAN",
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'Courier',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.3,
            child: Icon(Icons.dns, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            "RACK EMPTY",
            style: TextStyle(
              color: Colors.white38,
              fontFamily: 'Courier',
              fontSize: 20,
            ),
          ),
          const Text(
            "INSERT MODULES TO BEGIN",
            style: TextStyle(
              color: Colors.white24,
              fontFamily: 'Courier',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(
      text: Engine().identity.deviceName,
    );
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "IDENTITY CONFIGURATION",
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  labelText: "DEVICE DESIGNATION",
                  labelStyle: TextStyle(
                    color: Colors.green.withOpacity(0.7),
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CANCEL",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SkeuoButton(
                    width: 100,
                    height: 40,
                    color: Colors.green.shade900,
                    onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        await Engine().updateDeviceName(controller.text);
                        setState(() {}); // Refresh UI
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("UPDATE", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLight(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: active ? Colors.green : Colors.red, blurRadius: 4),
        ],
      ),
    );
  }
}
