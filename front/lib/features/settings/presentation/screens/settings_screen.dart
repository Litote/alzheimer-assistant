import 'package:flutter/material.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsService,
    required this.authService,
  });

  final SettingsService settingsService;
  final AuthService authService;

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres avancés'),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _UserInfoCard(authService: widget.authService),
                const SizedBox(height: 24),
                _SettingCard(
                  title: 'Voix Haute Qualité',
                  description:
                      'Utilise une voix de synthèse très naturelle et chaleureuse '
                      '(ElevenLabs) au lieu de la voix standard du téléphone.\n\n'
                      'Prend effet à la prochaine conversation.',
                  value: _useElevenLabs,
                  theme: theme,
                  onToggle: (value) async {
                    await widget.settingsService.setUseElevenLabs(value);
                    setState(() => _useElevenLabs = value);
                  },
                ),
                const SizedBox(height: 24),
                _SettingCard(
                  title: 'Mode Alterné (Texte)',
                  description:
                      'Désactive le flux audio continu.\n'
                      'Le téléphone attendra patiemment que vous ayez terminé '
                      'de parler avant d\'envoyer votre message.\n\n'
                      'Recommandé si l\'assistant a tendance à vous couper la parole trop vite.',
                  value: _useTextMode,
                  theme: theme,
                  onToggle: (value) async {
                    await widget.settingsService.setUseTextMode(value);
                    setState(() => _useTextMode = value);
                  },
                ),
                const SizedBox(height: 24),
                _SettingCard(
                  title: 'Mode WebRTC (LiveKit)',
                  description:
                      'Utilise LiveKit pour la communication audio en temps réel. '
                      'Nécessite que le serveur supporte LiveKit.\n\n'
                      'Prend effet à la prochaine conversation.',
                  value: _useLiveKit,
                  theme: theme,
                  onToggle: (value) async {
                    await widget.settingsService.setUseLiveKit(value);
                    setState(() => _useLiveKit = value);
                  },
                ),
                const SizedBox(height: 48),
                _SignOutButton(authService: widget.authService),
              ],
            ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authService.currentUser;
    final email = user?.email ?? user?.userMetadata?['email'] as String?;
    final name = user?.userMetadata?['full_name'] as String?;
    final id = user?.id ?? '—';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Compte connecté',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (name != null) ...[
              _InfoRow(label: 'Nom', value: name, theme: theme),
              const SizedBox(height: 6),
            ],
            if (email != null) ...[
              _InfoRow(label: 'Email', value: email, theme: theme),
              const SizedBox(height: 6),
            ],
            _InfoRow(label: 'ID', value: id, theme: theme, mono: true),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
    this.mono = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: mono
                ? theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
          ),
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.authService});

  final AuthService authService;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter avec votre compte Google pour utiliser l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      key: const Key('sign-out-button'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.error,
        side: BorderSide(color: theme.colorScheme.error.withAlpha(120)),
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
      ),
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.logout),
      label: const Text('Se déconnecter'),
    );
  }
}

/// Full-width tappable card for a single setting toggle.
/// Both the card body and the switch itself toggle the value.
class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.description,
    required this.value,
    required this.theme,
    required this.onToggle,
  });

  final String title;
  final String description;
  final bool value;
  final ThemeData theme;
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: value
              ? theme.colorScheme.primary.withAlpha(100)
              : Colors.transparent,
          width: 2,
        ),
      ),
      // Required so the InkWell ripple respects the rounded corners.
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onToggle(!value),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
