class NowPlaying {
  final String? source;
  final String? track;
  final String? artist;
  final String? album;
  final String? stationName;
  final String? artUrl;
  final String? playStatus;

  NowPlaying({
    this.source,
    this.track,
    this.artist,
    this.album,
    this.stationName,
    this.artUrl,
    this.playStatus,
  });

  bool get isStandby => source == 'STANDBY' || source == null;
  bool get isPlaying => playStatus == 'PLAY_STATE' || playStatus == 'BUFFERING_STATE';
}
