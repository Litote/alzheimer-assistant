import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';

class PermissionOnboardingScreen extends StatelessWidget {
  const PermissionOnboardingScreen({required this.service, super.key});

  final PermissionService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Bienvenue',
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Pour fonctionner, l'application a besoin de quelques permissions.",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _PermissionItem(
                icon: Icons.mic,
                title: 'Microphone',
                description: 'Pour vous écouter et comprendre vos demandes',
              ),
              const SizedBox(height: 24),
              _PermissionItem(
                icon: Icons.contacts,
                title: 'Contacts',
                description: 'Pour passer des appels téléphoniques',
              ),
              const SizedBox(height: 24),
              if (Platform.isIOS)
                _PermissionItem(
                  icon: Icons.record_voice_over,
                  title: 'Reconnaissance vocale',
                  description: 'Pour transcrire ce que vous dites',
                )
              else
                _PermissionItem(
                  icon: Icons.phone,
                  title: 'Téléphone',
                  description: 'Pour composer les numéros automatiquement',
                ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => _authorize(context),
                child: const Text('Autoriser les permissions'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _authorize(BuildContext context) async {
    await service.requestAll();
    await service.markOnboardingDone();
    if (context.mounted) {
      context.go('/');
    }
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
