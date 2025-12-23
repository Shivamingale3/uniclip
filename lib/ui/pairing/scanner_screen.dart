import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uniclip/engine/pairing/pairing_manager.dart';
import 'package:uniclip/engine/protocol/messages.dart';
import 'package:uniclip/service/service_client.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  List<DiscoveryMessage> _peers = [];
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Engine Listeners via ServiceClient
    ServiceClient().discoveryStream.listen((message) {
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

    ServiceClient().pairingStream.listen((event) {
      print("ScannerScreen: Received PairingEvent: ${event.type}");
      if (!mounted) return;
      switch (event.type) {
        case PairingEventType.codeDisplay:
          _showPairingDialog(event.data as String);
          break;
        case PairingEventType.success:
          print("ScannerScreen: Pairing Success. Popping to Root...");
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;
        case PairingEventType.error:
          print("ScannerScreen: Pairing Error: ${event.data}");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(event.data.toString())));
          break;
      }
    });
  }

  void _showPairingDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SECURITY INTERCEPT",
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'Courier',
                  fontSize: 16,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'Courier',
                      shadows: [BoxShadow(color: Colors.green, blurRadius: 10)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject Button
                  GestureDetector(
                    onTap: () {
                      ServiceClient().confirmPairing(false);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "REJECT",
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Authorize Button
                  GestureDetector(
                    onTap: () {
                      ServiceClient().confirmPairing(true);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        "AUTHORIZE",
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getOsIcon(String? os) {
    if (os == null) return Icons.device_unknown;
    final lower = os.toLowerCase();
    if (lower.contains('android')) return Icons.android;
    if (lower.contains('ios') ||
        lower.contains('iphone') ||
        lower.contains('mac'))
      return Icons.apple;
    if (lower.contains('windows') || lower.contains('linux'))
      return Icons.computer;
    return Icons.device_unknown;
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Radar Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, _) => CustomPaint(
                painter: RadarPainter(_radarController.value * 2 * math.pi),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.green),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "RADAR SCANNER",
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'Courier',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Detected Peers List
                Expanded(
                  child: _peers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "SEARCHING FREQUENCIES...",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${(_radarController.value * 100).toInt()}%",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          itemCount: _peers.length,
                          itemBuilder: (c, i) {
                            final peer = _peers[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  print(
                                    "Scanner: Tapping to pair with ${peer.deviceName} at ${peer.sourceIp}:${peer.tcpPort}",
                                  );
                                  ServiceClient().initiatePairing(
                                    peer.sourceIp ?? '127.0.0.1',
                                    peer.tcpPort,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(
                                      0.6,
                                    ), // See-through HUD
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                      width: 1,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ), // Technical shape
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Target Icon / reticle
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getOsIcon(peer.os),
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Data Block
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              peer.deviceName.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontFamily: 'Courier',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  "IP: ${peer.sourceIp}",
                                                  style: TextStyle(
                                                    color: Colors.green
                                                        .withOpacity(0.7),
                                                    fontFamily: 'Courier',
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (peer.os != null)
                                                  Text(
                                                    "OS: ${peer.os}",
                                                    style: TextStyle(
                                                      color: Colors.green
                                                          .withOpacity(0.7),
                                                      fontFamily: 'Courier',
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          border: Border.all(
                                            color: Colors.green,
                                          ),
                                        ),
                                        child: const Text(
                                          "LOCK",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double rotation;
  RadarPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 1.5; // Large radar

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw concentric circles
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), paint);
    }

    // Draw crosshairs
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );

    // Draw Sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [Colors.green.withOpacity(0), Colors.green.withOpacity(0.5)],
        stops: const [0.75, 1.0],
        transform: GradientRotation(
          rotation - math.pi / 2,
        ), // Offset so tail follows head
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = sweepPaint.shader);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
