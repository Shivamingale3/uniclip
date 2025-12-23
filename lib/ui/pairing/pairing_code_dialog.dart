import 'package:flutter/material.dart';

class PairingCodeDialog extends StatelessWidget {
  final String code;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PairingCodeDialog({
    super.key,
    required this.code,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Format code as "1 2 3  4 5 6"
    final formattedCode = code.split('').join(' ');

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm Pairing', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Does this code match the one on the other device?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text(
            formattedCode,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(16),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text("CONFIRM"),
        ),
      ],
    );
  }
}
