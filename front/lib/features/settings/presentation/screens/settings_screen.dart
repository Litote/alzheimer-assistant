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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await widget.settingsService.getUseElevenLabs();
    setState(() {
      _useElevenLabs = value;
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
                    'Utilise ElevenLabs pour la voix de Paul au lieu de la voix standard. '
                    'Prend effet à la prochaine conversation.',
                  ),
                  value: _useElevenLabs,
                  onChanged: (value) async {
                    await widget.settingsService.setUseElevenLabs(value);
                    setState(() => _useElevenLabs = value);
                  },
                ),
              ],
            ),
    );
  }
}
