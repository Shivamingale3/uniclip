import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/skeuo_theme.dart';

// --- CRT DISPLAY ---
class SkeuoCRT extends StatelessWidget {
  final String content;
  final double height;
  final double width;

  const SkeuoCRT({
    super.key,
    required this.content,
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414), // Dark plastic Bezel
        borderRadius: BorderRadius.circular(20),
        boxShadow: SkeuoTheme.deepShadow,
        border: Border.all(color: Colors.white10, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 4), // Bezel inset
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(0, 0),
              spreadRadius: 2,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Screen Glow
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF003300), Colors.black],
                    radius: 1.2,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: Color(0xFF33FF00), // Phosphor Green
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      shadows: [
                        Shadow(color: Color(0xFF33FF00), blurRadius: 5),
                      ],
                    ),
                  ),
                ),
              ),
              // Scanlines
              IgnorePointer(
                child: CustomPaint(
                  painter: ScanLinePainter(),
                  size: Size.infinite,
                ),
              ),
              // Reflection/Glare
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      stops: const [0, 0.4, 0.5, 1],
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.3);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- BUTTONS ---
class SkeuoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double height;
  final double width;
  final bool isRound;

  const SkeuoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = SkeuoTheme.metalGrey,
    this.height = 60,
    this.width = double.infinity,
    this.isRound = false,
  });

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        curve: Curves.easeOutQuad,
        transform: _isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color,
          shape: widget.isRound ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isRound ? null : BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isPressed
                ? [
                    Color.lerp(widget.color, Colors.black, 0.2)!,
                    Color.lerp(widget.color, Colors.black, 0.1)!,
                  ]
                : [
                    Color.lerp(widget.color, Colors.white, 0.2)!,
                    widget.color,
                    Color.lerp(widget.color, Colors.black, 0.3)!,
                  ],
          ),
          boxShadow: _isPressed
              ? SkeuoTheme.pressedShadow
              : SkeuoTheme.deepShadow,
          border: Border.all(color: Colors.white10, width: 1.0),
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
              fontFamily: 'Courier',
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// --- MODULE TOGGLE ---
class SkeuoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SkeuoToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Significantly larger size (70x120)
        width: 70,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? Colors.green.withOpacity(0.5) : Colors.white12,
            width: value ? 2 : 1,
          ),
          boxShadow: [
            const BoxShadow(
              color: Colors.black,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            if (value)
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ), // Glow when ON
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Slot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  if (value)
                    const BoxShadow(
                      color: Colors.green,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ), // Slot glows
                ],
              ),
            ),

            // Text Labels (ON/OFF)
            Positioned(
              top: 8,
              child: Text(
                "ON",
                style: TextStyle(
                  fontSize: 10,
                  color: value ? Colors.green : Colors.transparent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Text(
                "OFF",
                style: TextStyle(
                  fontSize: 10,
                  color: !value ? Colors.red : Colors.transparent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Lever
            AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment(0, -0.7) : Alignment(0, 0.7),
              child: Container(
                width: 50,
                height: 50, // Larger knob
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      value ? Colors.green.shade200 : Colors.grey,
                      value ? Colors.green.shade900 : Colors.black,
                    ],
                    stops: const [0.1, 0.4, 1.0],
                    center: const Alignment(-0.3, -0.3),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- LIGHTBOX SWITCH ---
class SkeuoLightboxToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SkeuoLightboxToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onChanged(!value);
      },
      child: Container(
        width: 70,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a), // Dark metal frame
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 4),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: value
                ? const Color(0xFF003300)
                : const Color(0xFF330000), // Dark Green vs Dark Red
            border: Border.all(
              color: value
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
              width: 1,
            ),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: value
                  ? [
                      const Color(0xFFccffcc),
                      const Color(0xFF00ff00),
                      const Color(0xFF004400),
                    ]
                  : [
                      const Color(0xFFffcccc),
                      const Color(0xFFff0000),
                      const Color(0xFF440000),
                    ],
              stops: const [0.2, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: value
                    ? Colors.greenAccent.withOpacity(0.6)
                    : Colors.redAccent.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: value
                    ? const Color(0xFF003300)
                    : const Color(0xFF330000),
                shadows: [],
              ),
              child: Text(value ? "ON" : "OFF"),
            ),
          ),
        ),
      ),
    );
  }
}

// --- RACK MODULE ---
class SkeuoControlModule extends StatelessWidget {
  final String deviceName;
  final String status;
  final String osType;
  final bool isAutoSync;
  final ValueChanged<bool> onAutoSyncChanged;
  final VoidCallback onManualSync;
  final VoidCallback onUnpair;

  const SkeuoControlModule({
    super.key,
    required this.deviceName,
    required this.status,
    required this.osType,
    required this.isAutoSync,
    required this.onAutoSyncChanged,
    required this.onManualSync,
    required this.onUnpair,
  });

  IconData _getOsIcon() {
    final lower = osType.toLowerCase();
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SkeuoTheme.metalGrey,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF333333), Color(0xFF222222)],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          // TOP ROW: Name and Auto Sync
          Row(
            children: [
              const Icon(Icons.add, size: 12, color: Colors.black54),
              const SizedBox(width: 8),
              // OS Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white12),
                ),
                child: Icon(_getOsIcon(), color: Colors.white70, size: 18),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    deviceName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Auto Sync Label & Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "AUTO",
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white54,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 2),
                  SkeuoLightboxToggle(
                    value: isAutoSync,
                    onChanged: onAutoSyncChanged,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.add, size: 12, color: Colors.black54),
            ],
          ),

          const SizedBox(height: 12),

          // BOTTOM ROW: Status and Manual Controls
          Row(
            children: [
              const SizedBox(width: 24), // Approx padding to align with text
              Text(
                status,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
              const Spacer(),
              SkeuoButton(
                width: 44,
                height: 44,
                color: const Color(0xFF333333),
                onPressed: onManualSync,
                child: const Icon(Icons.sync, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 16),
              SkeuoButton(
                width: 44,
                height: 44,
                color: const Color(0xFF441111), // Reddish base
                onPressed: onUnpair,
                child: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }
}
