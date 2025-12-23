import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/engine/peers/peer_registry.dart';
import 'package:quick_settings/quick_settings.dart';

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

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Quick Settings Setup
    QuickSettings.setup(
      onTileClicked: (tile) {
        if (tile.tileStatus == TileStatus.active) {
          tile.tileStatus = TileStatus.inactive;
          tile.label = "Sync Paused";
          // TODO: Pause Engine
        } else {
          tile.tileStatus = TileStatus.active;
          tile.label = "Auto Sync On";
          // TODO: Resume Engine
        }
        return tile;
      },
      onTileAdded: (tile) {
        tile.tileStatus = TileStatus.active;
        tile.label = "Auto Sync On";
        return tile;
      },
    );

    // Initialize Engine in this Isolate
    final engine = Engine();

    // Need to initialize Engine properly
    // Note: SharedPreferences works in background isolate on Android.
    await engine.start();

    // Listen to Engine Clipboard Events and forward to UI
    engine.clipboardManager.contentStream.listen((content) {
      service.invoke('clipboard_update', {'content': content});

      // Update Notification
      FlutterLocalNotificationsPlugin().show(
        888,
        'Uniclip Active',
        'Copied: ${content.length > 20 ? content.substring(0, 20) + "..." : content}',
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

    // Listen to UI commands
    service.on('manual_sync').listen((event) {
      // handle manual sync request from UI
    });

    service.on('stop').listen((event) {
      service.stopSelf();
    });
  }
}
