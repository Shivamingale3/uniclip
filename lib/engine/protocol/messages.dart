class DiscoveryMessage {
  final int version;
  final String deviceId;
  final String deviceName;
  final String os;
  final int tcpPort;
  final bool pairingMode;
  final String? sourceIp;

  DiscoveryMessage({
    required this.version,
    required this.deviceId,
    required this.deviceName,
    required this.os,
    required this.tcpPort,
    required this.pairingMode,
    this.sourceIp,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'os': os,
    'tcpPort': tcpPort,
    'pairingMode': pairingMode,
  };

  // Factory from JSON (IP is unknown at decode time)
  factory DiscoveryMessage.fromJson(Map<String, dynamic> json) {
    return DiscoveryMessage(
      version: json['version'] as int,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      os: json['os'] as String,
      tcpPort: json['tcpPort'] as int,
      pairingMode: json['pairingMode'] as bool,
    );
  }

  DiscoveryMessage copyWithIp(String ip) {
    return DiscoveryMessage(
      version: version,
      deviceId: deviceId,
      deviceName: deviceName,
      os: os,
      tcpPort: tcpPort,
      pairingMode: pairingMode,
      sourceIp: ip,
    );
  }
}

class HelloMessage {
  final int version;
  final String deviceId;
  final String deviceName;
  final String os;
  final int? tcpPort; // Added listening port

  HelloMessage({
    required this.version,
    required this.deviceId,
    required this.deviceName,
    required this.os,
    this.tcpPort,
  });

  Map<String, dynamic> toJson() => {
    'type': 'HELLO',
    'version': version,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'os': os,
    'tcpPort': tcpPort,
  };

  factory HelloMessage.fromJson(Map<String, dynamic> json) {
    return HelloMessage(
      version: json['version'] as int,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      os: json['os'] as String,
      tcpPort: json['tcpPort'] as int?,
    );
  }
}

class PairConfirmMessage {
  final bool accepted;
  final String? deviceId;
  final String? deviceName;
  final String? os;

  PairConfirmMessage({
    required this.accepted,
    this.deviceId,
    this.deviceName,
    this.os,
  });

  Map<String, dynamic> toJson() => {
    'type': 'PAIR_CONFIRM',
    'accepted': accepted,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'os': os,
  };

  factory PairConfirmMessage.fromJson(Map<String, dynamic> json) {
    return PairConfirmMessage(
      accepted: json['accepted'] as bool,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      os: json['os'] as String?,
    );
  }
}

class ClipboardMessage {
  final String messageId;
  final String type; // 'text' or 'image'
  final String content; // text content or base64 image
  final String sourceDeviceId;
  final int timestamp;

  ClipboardMessage({
    required this.messageId,
    required this.type,
    required this.content,
    required this.sourceDeviceId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': 'CLIPBOARD',
    'payloadType': type,
    'messageId': messageId,
    'content': content,
    'sourceDeviceId': sourceDeviceId,
    'timestamp': timestamp,
  };

  factory ClipboardMessage.fromJson(Map<String, dynamic> json) {
    return ClipboardMessage(
      messageId: json['messageId'] as String,
      type: json['payloadType'] as String,
      content: json['content'] as String,
      sourceDeviceId: json['sourceDeviceId'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}
