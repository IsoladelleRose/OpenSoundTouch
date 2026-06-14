import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/now_playing.dart';
import '../models/preset.dart';
import '../models/radio_station.dart';
import '../models/speaker.dart';

class SoundTouchClient {
  final Speaker speaker;
  final http.Client _http;

  SoundTouchClient(this.speaker, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('${speaker.baseUrl}$path');

  Future<XmlDocument> _get(String path) async {
    final response =
        await _http.get(_uri(path)).timeout(const Duration(seconds: 4));
    _ensureOk(response);
    return XmlDocument.parse(response.body);
  }

  Future<XmlDocument> _post(String path, String body) async {
    final response = await _http
        .post(
          _uri(path),
          headers: const {'Content-Type': 'application/xml'},
          body: body,
        )
        .timeout(const Duration(seconds: 4));
    _ensureOk(response);
    return XmlDocument.parse(response.body);
  }

  void _ensureOk(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('SoundTouch ${speaker.host} returned ${r.statusCode}: ${r.body}');
    }
  }

  // ---- read endpoints -------------------------------------------------------

  Future<Map<String, String>> info() async {
    final doc = await _get('/info');
    final root = doc.rootElement;
    return {
      'name': root.findElements('name').firstOrNull?.innerText ?? '',
      'type': root.findElements('type').firstOrNull?.innerText ?? '',
      'softwareVersion':
          root.findElements('components').firstOrNull?.toString() ?? '',
    };
  }

  Future<NowPlaying> nowPlaying() async {
    final doc = await _get('/now_playing');
    final root = doc.rootElement;
    final source = root.getAttribute('source');
    return NowPlaying(
      source: source,
      track: root.findElements('track').firstOrNull?.innerText,
      artist: root.findElements('artist').firstOrNull?.innerText,
      album: root.findElements('album').firstOrNull?.innerText,
      stationName: root.findElements('stationName').firstOrNull?.innerText,
      artUrl: root.findElements('art').firstOrNull?.innerText,
      playStatus: root.findElements('playStatus').firstOrNull?.innerText,
    );
  }

  Future<List<Preset>> presets() async {
    final doc = await _get('/presets');
    final result = <Preset>[];
    for (final p in doc.rootElement.findElements('preset')) {
      final idAttr = p.getAttribute('id');
      final id = int.tryParse(idAttr ?? '') ?? 0;
      final ci = p.findElements('ContentItem').firstOrNull;
      if (ci == null) {
        result.add(Preset(id: id));
        continue;
      }
      result.add(Preset(
        id: id,
        itemName: ci.findElements('itemName').firstOrNull?.innerText,
        source: ci.getAttribute('source'),
        location: ci.getAttribute('location'),
        sourceAccount: ci.getAttribute('sourceAccount'),
        containerArt: ci.findElements('containerArt').firstOrNull?.innerText,
      ));
    }
    return result;
  }

  Future<int> volume() async {
    final doc = await _get('/volume');
    final txt = doc.rootElement
            .findElements('actualvolume')
            .firstOrNull
            ?.innerText ??
        '0';
    return int.tryParse(txt) ?? 0;
  }

  // ---- control endpoints ----------------------------------------------------

  Future<void> setVolume(int level) async {
    final clamped = level.clamp(0, 100);
    await _post('/volume', '<volume>$clamped</volume>');
  }

  Future<void> _key(String value, {Duration hold = Duration.zero}) async {
    await _post(
        '/key', '<key state="press" sender="Gabbo">$value</key>');
    if (hold > Duration.zero) {
      await Future.delayed(hold);
    }
    await _post(
        '/key', '<key state="release" sender="Gabbo">$value</key>');
  }

  Future<void> playPause() => _key('PLAY_PAUSE');
  Future<void> nextTrack() => _key('NEXT_TRACK');
  Future<void> prevTrack() => _key('PREV_TRACK');
  Future<void> powerToggle() => _key('POWER');
  Future<void> mute() => _key('MUTE');

  Future<void> selectPreset(int presetId) {
    if (presetId < 1 || presetId > 6) {
      throw ArgumentError('Preset id must be 1..6');
    }
    return _key('PRESET_$presetId');
  }

  /// Long-press a preset key to STORE the currently playing item to that slot.
  /// The speaker needs the item to already be playing before this call.
  Future<void> storePreset(int presetId) {
    if (presetId < 1 || presetId > 6) {
      throw ArgumentError('Preset id must be 1..6');
    }
    return _key('PRESET_$presetId', hold: const Duration(seconds: 3));
  }

  /// Plays an internet-radio station via /select with a ContentItem.
  Future<void> playRadioStation(RadioStation station) async {
    final escapedName = _escapeXml(station.name);
    final escapedUrl = _escapeXml(station.url);
    final escapedArt =
        station.favicon == null ? '' : _escapeXml(station.favicon!);
    final body = '<ContentItem source="INTERNET_RADIO" '
        'location="$escapedUrl" '
        'sourceAccount="" '
        'isPresetable="true">'
        '<itemName>$escapedName</itemName>'
        '${station.favicon == null ? '' : '<containerArt>$escapedArt</containerArt>'}'
        '</ContentItem>';
    await _post('/select', body);
  }

  /// One-shot: play this station, wait briefly, then long-press the preset key
  /// to store the now-playing content as the requested preset.
  Future<void> assignStationToPreset(RadioStation station, int presetId) async {
    await playRadioStation(station);
    await Future.delayed(const Duration(seconds: 2));
    await storePreset(presetId);
  }

  String _escapeXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  void dispose() => _http.close();
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
