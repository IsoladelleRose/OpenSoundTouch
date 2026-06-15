import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/speakers_screen.dart';
import 'state/favorites_store.dart';
import 'state/speakers_store.dart';

void main() {
  runApp(const OpenSoundTouchApp());
}

class OpenSoundTouchApp extends StatelessWidget {
  const OpenSoundTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpeakersStore()),
        ChangeNotifierProvider(create: (_) => FavoritesStore()),
      ],
      child: MaterialApp(
        title: 'OpenSoundTouch',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SpeakersScreen(),
      ),
    );
  }
}
