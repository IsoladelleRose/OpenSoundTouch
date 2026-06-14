class RadioStation {
  final String stationUuid;
  final String name;
  final String url;
  final String? favicon;
  final String? country;
  final String? language;
  final String? tags;
  final int? bitrate;
  final String? codec;

  RadioStation({
    required this.stationUuid,
    required this.name,
    required this.url,
    this.favicon,
    this.country,
    this.language,
    this.tags,
    this.bitrate,
    this.codec,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
        stationUuid: (json['stationuuid'] ?? json['stationUuid'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        url: (json['url_resolved'] ?? json['url'] ?? '') as String,
        favicon: json['favicon'] as String?,
        country: json['country'] as String?,
        language: json['language'] as String?,
        tags: json['tags'] as String?,
        bitrate: json['bitrate'] is int ? json['bitrate'] as int : null,
        codec: json['codec'] as String?,
      );
}
