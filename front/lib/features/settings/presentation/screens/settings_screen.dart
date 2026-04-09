import 'package:flutter/material.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useElevenLabs = false;
  bool _useTextMode = false;
  bool _useLiveKit = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final elevenLabs = await widget.settingsService.getUseElevenLabs();
    final textMode = await widget.settingsService.getUseTextMode();
    final liveKit = await widget.settingsService.getUseLiveKit();
    setState(() {
      _useElevenLabs = elevenLabs;
      _useTextMode = textMode;
      _useLiveKit = liveKit;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres avancés')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Synthèse vocale ElevenLabs'),
                  subtitle: const Text(
                    'Utilise ElevenLabs pour la voix de synthèse au lieu de la voix standard. '
                    'Prend effet à la prochaine conversation.',
                  ),
                  value: _useElevenLabs,
                  onChanged: (value) async {
                    await widget.settingsService.setUseElevenLabs(value);
                    setState(() => _useElevenLabs = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Mode texte'),
                  subtitle: const Text(
                    'Utilise la reconnaissance vocale de l\'appareil pour transcrire '
                    'votre message avant de l\'envoyer. '
                    'Prend effet à la prochaine conversation.',
                  ),
                  value: _useTextMode,
                  onChanged: (value) async {
                    await widget.settingsService.setUseTextMode(value);
                    setState(() => _useTextMode = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Mode LiveKit (WebRTC)'),
                  subtitle: const Text(
                    'Utilise LiveKit pour la communication audio en temps réel. '
                    'Nécessite que le serveur supporte LiveKit. '
                    'Prend effet à la prochaine conversation.',
                  ),
                  value: _useLiveKit,
                  onChanged: (value) async {
                    await widget.settingsService.setUseLiveKit(value);
                    setState(() => _useLiveKit = value);
                  },
                ),
              ],
            ),
    );
  }
}
