import 'package:flutter/material.dart';
import '../config.dart';
import '../models/radio_station.dart';
import '../services/radio_search_service.dart';
import '../services/soundtouch_client.dart';

class PresetEditScreen extends StatefulWidget {
  final SoundTouchClient client;
  final int presetId;
  const PresetEditScreen({
    super.key,
    required this.client,
    required this.presetId,
  });

  @override
  State<PresetEditScreen> createState() => _PresetEditScreenState();
}

class _PresetEditScreenState extends State<PresetEditScreen> {
  final _searchCtrl = TextEditingController();
  final _searchService = RadioSearchService(backendBaseUrl: backendBaseUrl);
  List<RadioStation> _results = const [];
  bool _searching = false;
  String? _error;

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final r = await _searchService.search(name: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() => _results = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _assign(RadioStation station) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.client.assignStationToPreset(station, widget.presetId);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text('Assigned "${station.name}" to preset ${widget.presetId}')));
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign to preset ${widget.presetId}')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search radio stations',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _searching ? null : _search, child: const Text('Search')),
          ]),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(
                      child: Text('Type a station name and tap Search.'),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 0),
                      itemBuilder: (context, i) {
                        final s = _results[i];
                        return ListTile(
                          leading: (s.favicon != null && s.favicon!.isNotEmpty)
                              ? Image.network(s.favicon!,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.radio))
                              : const Icon(Icons.radio),
                          title: Text(s.name),
                          subtitle: Text([
                            if (s.country != null) s.country,
                            if (s.codec != null) s.codec,
                            if (s.bitrate != null) '${s.bitrate} kbps',
                          ].whereType<String>().join(' • ')),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => _assign(s),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
