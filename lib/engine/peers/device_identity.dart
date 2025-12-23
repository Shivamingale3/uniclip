import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class DeviceIdentity {
  static const String _keyDeviceId = 'device_id';
  static const String _keyDeviceName = 'device_name';

  String? _deviceId;
  String? _deviceName;

  String get deviceId => _deviceId ?? 'unknown';
  String get deviceName => _deviceName ?? 'Unknown Device';
  String get os => Platform.operatingSystem;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_keyDeviceId);
    _deviceName = prefs.getString(_keyDeviceName);

    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_keyDeviceId, _deviceId!);
    }

    if (_deviceName == null) {
      _deviceName = Platform.localHostname;
    }
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceName, name);
  }
}
