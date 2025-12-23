import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PairedDevice {
  final String id;
  final String name;
  final String os;
  final String lastSeenIp;
  final int lastSeenPort;
  final bool autoSync;
  final int lastPairedAt;

  PairedDevice({
    required this.id,
    required this.name,
    required this.os,
    required this.lastSeenIp,
    required this.lastSeenPort,
    this.autoSync = false,
    required this.lastPairedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'os': os,
    'lastSeenIp': lastSeenIp,
    'lastSeenPort': lastSeenPort,
    'autoSync': autoSync,
    'lastPairedAt': lastPairedAt,
  };

  factory PairedDevice.fromJson(Map<String, dynamic> json) {
    return PairedDevice(
      id: json['id'],
      name: json['name'],
      os: json['os'],
      lastSeenIp: json['lastSeenIp'],
      lastSeenPort: json['lastSeenPort'],
      autoSync: json['autoSync'] ?? false,
      lastPairedAt: json['lastPairedAt'] ?? 0,
    );
  }

  PairedDevice copyWith({
    String? name,
    String? lastSeenIp,
    int? lastSeenPort,
    bool? autoSync,
  }) {
    return PairedDevice(
      id: id,
      name: name ?? this.name,
      os: os,
      lastSeenIp: lastSeenIp ?? this.lastSeenIp,
      lastSeenPort: lastSeenPort ?? this.lastSeenPort,
      autoSync: autoSync ?? this.autoSync,
      lastPairedAt: lastPairedAt,
    );
  }
}

class PeerRegistry {
  static const String _keyPairedDevices = 'paired_devices';
  final List<PairedDevice> _devices = [];

  List<PairedDevice> get devices => List.unmodifiable(_devices);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPairedDevices);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _devices.clear();
      _devices.addAll(jsonList.map((j) => PairedDevice.fromJson(j)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _devices.map((d) => d.toJson()).toList();
    await prefs.setString(_keyPairedDevices, jsonEncode(jsonList));
  }

  Future<void> addOrUpdate(
    String id,
    String name,
    String os,
    String ip,
    int port,
  ) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        name: name,
        lastSeenIp: ip,
        lastSeenPort: port,
      );
    } else {
      _devices.add(
        PairedDevice(
          id: id,
          name: name,
          os: os,
          lastSeenIp: ip,
          lastSeenPort: port,
          lastPairedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    await _save();
  }

  Future<void> toggleAutoSync(String id) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final current = _devices[index];
      _devices[index] = current.copyWith(autoSync: !current.autoSync);
      await _save();
    }
  }

  Future<void> unpair(String id) async {
    _devices.removeWhere((d) => d.id == id);
    await _save();
  }

  PairedDevice? getDevice(String id) {
    try {
      return _devices.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isPaired(String id) {
    return _devices.any((d) => d.id == id);
  }
}
