import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/now_playing.dart';
import '../models/radio_station.dart';
import '../models/speaker.dart';
import '../services/soundtouch_client.dart';
import '../state/favorites_store.dart';
import 'preset_edit_screen.dart';

class SpeakerDetailScreen extends StatefulWidget {
  final Speaker speaker;
  const SpeakerDetailScreen({super.key, required this.speaker});

  @override
  State<SpeakerDetailScreen> createState() => _SpeakerDetailScreenState();
}

class _SpeakerDetailScreenState extends State<SpeakerDetailScreen> {
  late final SoundTouchClient _client;
  NowPlaying? _np;
  int _volume = 0;
  bool _loading = true;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _client = SoundTouchClient(widget.speaker);
    _refresh();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _client.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _client.nowPlaying(),
        _client.volume(),
      ]);
      if (!mounted) return;
      setState(() {
        _np = results[0] as NowPlaying;
        _volume = results[1] as int;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.speaker.name),
        actions: [
          IconButton(
              icon: const Icon(Icons.power_settings_new),
              tooltip: 'Power',
              onPressed: () => _guarded(_client.powerToggle)),
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refresh),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  _NowPlayingCard(np: _np),
                  const SizedBox(height: 16),
                  _Controls(
                    onPlayPause: () => _guarded(_client.playPause),
                    onPrev: () => _guarded(_client.prevTrack),
                    onNext: () => _guarded(_client.nextTrack),
                    onMute: () => _guarded(_client.mute),
                  ),
                  const SizedBox(height: 16),
                  _VolumeSlider(
                    volume: _volume,
                    onChanged: (v) =>
                        _guarded(() => _client.setVolume(v.round())),
                  ),
                  const SizedBox(height: 24),
                  const Text('Presets',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final favorites = context.watch<FavoritesStore>();
                    final slots = favorites.slotsFor(widget.speaker.host);
                    return _PresetsGrid(
                      stations: slots,
                      onTap: (slot) {
                        final station = slots[slot];
                        if (station != null) {
                          _guarded(() => _client.playRadioStation(station));
                        }
                      },
                      onEdit: (slot) async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PresetEditScreen(
                            client: _client,
                            speaker: widget.speaker,
                            presetId: slot,
                          ),
                        ));
                        _refresh();
                      },
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final NowPlaying? np;
  const _NowPlayingCard({required this.np});

  @override
  Widget build(BuildContext context) {
    final n = np;
    if (n == null || n.isStandby) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.power_off, size: 32),
            SizedBox(width: 12),
            Text('Standby'),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (n.artUrl != null && n.artUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(n.artUrl!,
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.music_note, size: 64)),
              )
            else
              const Icon(Icons.music_note, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.stationName ?? n.track ?? n.source ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (n.artist != null) Text(n.artist!),
                  if (n.album != null)
                    Text(n.album!, style: const TextStyle(color: Colors.grey)),
                  Text(n.source ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VoidCallback onPlayPause;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onMute;
  const _Controls({
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(iconSize: 32, icon: const Icon(Icons.skip_previous), onPressed: onPrev),
        IconButton(iconSize: 40, icon: const Icon(Icons.play_arrow), onPressed: onPlayPause),
        IconButton(iconSize: 32, icon: const Icon(Icons.skip_next), onPressed: onNext),
        IconButton(iconSize: 32, icon: const Icon(Icons.volume_off), onPressed: onMute),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final int volume;
  final ValueChanged<double> onChanged;
  const _VolumeSlider({required this.volume, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.volume_down),
      Expanded(
        child: Slider(
          value: volume.clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$volume',
          onChanged: onChanged,
        ),
      ),
      const Icon(Icons.volume_up),
    ]);
  }
}

class _PresetsGrid extends StatelessWidget {
  final Map<int, RadioStation> stations;
  final void Function(int slot) onTap;
  final void Function(int slot) onEdit;
  const _PresetsGrid({
    required this.stations,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: List.generate(FavoritesStore.slotCount, (i) {
        final slot = i + 1;
        return _PresetTile(
          slot: slot,
          station: stations[slot],
          onTap: () => onTap(slot),
          onEdit: () => onEdit(slot),
        );
      }),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final int slot;
  final RadioStation? station;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _PresetTile({
    required this.slot,
    required this.station,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = station == null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEmpty ? onEdit : onTap,
        onLongPress: onEdit,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$slot',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Text(
                      isEmpty ? '— empty —' : station!.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                        color: isEmpty ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: 'Assign station',
            ),
          ),
        ]),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
      ]),
    );
  }
}
