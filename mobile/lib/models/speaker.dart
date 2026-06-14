class Speaker {
  final String name;
  final String host;
  final int port;
  final String? macAddress;

  Speaker({
    required this.name,
    required this.host,
    this.port = 8090,
    this.macAddress,
  });

  String get baseUrl => 'http://$host:$port';
  String get webSocketUrl => 'ws://$host:8080';

  Map<String, dynamic> toJson() => {
        'name': name,
        'host': host,
        'port': port,
        'macAddress': macAddress,
      };

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
        name: json['name'] as String,
        host: json['host'] as String,
        port: (json['port'] as int?) ?? 8090,
        macAddress: json['macAddress'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is Speaker && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}
