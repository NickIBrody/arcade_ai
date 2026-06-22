class SshProfile {
  final String id;
  String label;
  String host;
  int port;
  String username;

  SshProfile({
    required this.id,
    this.label = '',
    this.host = '',
    this.port = 22,
    this.username = '',
  });

  String get display => label.isNotEmpty ? label : '$username@$host';

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'host': host,
        'port': port,
        'username': username,
      };

  factory SshProfile.fromJson(Map<String, dynamic> j) => SshProfile(
        id: j['id'],
        label: j['label'] ?? '',
        host: j['host'] ?? '',
        port: j['port'] ?? 22,
        username: j['username'] ?? '',
      );
}
