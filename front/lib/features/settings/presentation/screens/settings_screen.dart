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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final elevenLabs = await widget.settingsService.getUseElevenLabs();
    final textMode = await widget.settingsService.getUseTextMode();
    setState(() {
      _useElevenLabs = elevenLabs;
      _useTextMode = textMode;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres avancés'),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(
                20,
              ), // Marges globales plus grande pour tap
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _useElevenLabs
                          ? theme.colorScheme.primary.withAlpha(100)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip
                      .hardEdge, // Essentiel pour que l'InkWell suive les arrondis
                  child: InkWell(
                    // Rend toute la surface de la carte cliquable
                    onTap: () async {
                      final newValue = !_useElevenLabs;
                      await widget.settingsService.setUseElevenLabs(newValue);
                      setState(() => _useElevenLabs = newValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(
                        24.0,
                      ), // Zone de frappe géante
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Voix Haute Qualité',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _useElevenLabs,
                                onChanged: (value) async {
                                  await widget.settingsService.setUseElevenLabs(
                                    value,
                                  );
                                  setState(() => _useElevenLabs = value);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Utilise une voix de synthèse très naturelle et chaleureuse (ElevenLabs) au lieu de la voix standard du téléphone.\n\nPrend effet à la prochaine conversation.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24), // Grand espace entre les réglages
                // ─── CARTE 2 : MODE SÉCURISÉ (Texte) ─────────────────────────
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _useTextMode
                          ? theme.colorScheme.primary.withAlpha(100)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () async {
                      final newValue = !_useTextMode;
                      await widget.settingsService.setUseTextMode(newValue);
                      setState(() => _useTextMode = newValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Mode Alterné (Texte)',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _useTextMode,
                                onChanged: (value) async {
                                  await widget.settingsService.setUseTextMode(
                                    value,
                                  );
                                  setState(() => _useTextMode = value);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Désactive le flux audio continu.\nLe téléphone attendra patiemment que vous ayez terminé de parler avant d\'envoyer votre message.\n\nRecommandé si l\'assistant a tendance à vous couper la parole trop vite.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
