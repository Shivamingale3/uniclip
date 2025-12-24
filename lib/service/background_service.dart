import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uniclip/engine/engine.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'uniclip_service',
      'Uniclip Background Service',
      description: 'Maintains clipboard sync connection',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'uniclip_service',
        initialNotificationTitle: 'Uniclip Service',
        initialNotificationContent: 'Clipboard Sync Active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Engine in this Isolate
  final engine = Engine();

  // Need to initialize Engine properly
  await engine.start();

  // Listen to Engine Clipboard Events and forward to UI
  engine.clipboardManager.contentStream.listen((content) {
    service.invoke('clipboard_update', {'content': content});

    // Update Notification
    FlutterLocalNotificationsPlugin().show(
      888,
      'Uniclip Active',
      'Copied: ${content.length > 20 ? "${content.substring(0, 20)}..." : content}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'uniclip_service',
          'Uniclip Background Service',
          icon: 'ic_launcher',
          ongoing: true,
        ),
      ),
    );
  });

  // Listen to Peer Registry Changes
  engine.peerRegistry.devicesStream.listen((devices) {
    final jsonList = devices.map((d) => d.toJson()).toList();
    service.invoke('peers_update', {'devices': jsonEncode(jsonList)});
  });

  // Forward Discovery Messages
  engine.discovery.messages.listen((msg) {
    service.invoke('discovery_update', {'message': jsonEncode(msg.toJson())});
  });

  // Forward Pairing Events
  engine.pairingManager.events.listen((event) {
    service.invoke('pairing_update', {
      'type': event.type.index,
      'data': event.data,
    });
  });

  // Listen to UI commands
  service.on('manual_sync').listen((event) {
    if (event != null && event['deviceId'] != null) {
      engine.clipboardManager.forceSyncTo(event['deviceId']);
    }
  });

  service.on('unpair').listen((event) {
    if (event != null && event['deviceId'] != null) {
      engine.peerRegistry.unpair(event['deviceId']);
    }
  });

  service.on('toggle_auto_sync').listen((event) {
    if (event != null && event['deviceId'] != null) {
      engine.peerRegistry.toggleAutoSync(event['deviceId']);
    }
  });

  service.on('update_name').listen((event) {
    if (event != null && event['name'] != null) {
      engine.updateDeviceName(event['name']);
    }
  });

  service.on('initiate_pairing').listen((event) {
    if (event != null) {
      print(
        "BackgroundService: Initiating pairing to ${event['ip']}:${event['port']}",
      );
      engine.pairingManager.initiatePairing(event['ip'], event['port']);
    }
  });

  service.on('confirm_pairing').listen((event) {
    if (event != null) {
      engine.pairingManager.confirmPairing(event['accept']);
    }
  });

  service.on('local_clipboard_update').listen((event) {
    if (event != null && event['content'] != null) {
      engine.clipboardManager.setLocalContent(event['content']);
    }
  });

  service.on('stop').listen((event) {
    service.stopSelf();
  });
}
