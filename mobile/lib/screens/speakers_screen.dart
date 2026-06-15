import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/speaker.dart';
import '../state/favorites_store.dart';
import '../state/speakers_store.dart';
import 'speaker_detail_screen.dart';

class SpeakersScreen extends StatefulWidget {
  const SpeakersScreen({super.key});

  @override
  State<SpeakersScreen> createState() => _SpeakersScreenState();
}

class _SpeakersScreenState extends State<SpeakersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final favorites = context.read<FavoritesStore>();
      final store = context.read<SpeakersStore>();
      await favorites.load();
      await store.load();
      if (store.speakers.isEmpty) {
        await store.discover();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpeakersStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenSoundTouch'),
        actions: [
          IconButton(
            onPressed: store.isDiscovering ? null : () => store.discover(),
            icon: store.isDiscovering
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Re-scan network',
          ),
        ],
      ),
      body: store.speakers.isEmpty && !store.isDiscovering
          ? const _EmptyState()
          : ListView.separated(
              itemCount: store.speakers.length,
              separatorBuilder: (_, _) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final s = store.speakers[i];
                return ListTile(
                  leading: const Icon(Icons.speaker),
                  title: Text(s.name),
                  subtitle: Text('${s.host}:${s.port}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.remove(s),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SpeakerDetailScreen(speaker: s),
                  )),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add by IP'),
        onPressed: () => _showAddManualDialog(context),
      ),
    );
  }

  Future<void> _showAddManualDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: 'My SoundTouch');
    final ipCtrl = TextEditingController();
    final store = context.read<SpeakersStore>();

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add speaker manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: ipCtrl,
              decoration: const InputDecoration(
                  labelText: 'IP address', hintText: '192.168.1.42'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (added == true && ipCtrl.text.trim().isNotEmpty) {
      await store.addManual(Speaker(
        name: nameCtrl.text.trim().isEmpty ? ipCtrl.text.trim() : nameCtrl.text.trim(),
        host: ipCtrl.text.trim(),
      ));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speaker, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No SoundTouch speakers found yet.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the speaker is on the same Wi-Fi network. '
              'Tap the refresh icon to scan again, or use "Add by IP".',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
