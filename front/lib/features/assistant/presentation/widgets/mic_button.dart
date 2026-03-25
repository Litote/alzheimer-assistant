import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';

class MicButton extends StatelessWidget {
  const MicButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      builder: (context, state) {
        final config = _configFor(state);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: config.semanticLabel,
              button: true,
              enabled: config.enabled,
              child: GestureDetector(
                onTap: config.enabled
                    ? () => context
                        .read<AssistantBloc>()
                        .add(const AssistantEvent.startListening())
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.backgroundColor,
                    boxShadow: config.enabled
                        ? [
                            BoxShadow(
                              color: config.backgroundColor.withAlpha(100),
                              blurRadius: 24,
                              spreadRadius: 4,
                            )
                          ]
                        : [],
                  ),
                  child: Center(child: _buildIcon(state, config)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                config.label,
                key: ValueKey(config.label),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIcon(AssistantState state, _ButtonConfig config) {
    if (state is Processing) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }
    return Icon(config.icon, color: Colors.white, size: 40);
  }

  _ButtonConfig _configFor(AssistantState state) => switch (state) {
        Idle() => _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: const Color(0xFF5B8DEF),
            label: 'Appuyez pour parler',
            semanticLabel: 'Bouton microphone. Appuyez pour parler à l\'assistant.',
            enabled: true,
          ),
        Listening() => _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: const Color(0xFFEF5B5B),
            label: 'Écoute en cours…',
            semanticLabel: 'Écoute en cours. L\'assistant vous écoute.',
            enabled: false,
          ),
        Processing() => _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: const Color(0xFF9B8DEF),
            label: 'Traitement…',
            semanticLabel: 'Traitement en cours. Veuillez patienter.',
            enabled: false,
          ),
        Speaking() => _ButtonConfig(
            icon: Icons.volume_up,
            backgroundColor: const Color(0xFF5BCEEF),
            label: 'En train de répondre…',
            semanticLabel: 'L\'assistant répond.',
            enabled: false,
          ),
        AssistantError() => _ButtonConfig(
            icon: Icons.refresh,
            backgroundColor: const Color(0xFFEF8D5B),
            label: 'Appuyez pour réessayer',
            semanticLabel: 'Une erreur est survenue. Appuyez pour réessayer.',
            enabled: true,
          ),
        _ => _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: const Color(0xFF5B8DEF),
            label: '',
            semanticLabel: '',
            enabled: false,
          ),
      };
}

class _ButtonConfig {
  const _ButtonConfig({
    required this.icon,
    required this.backgroundColor,
    required this.label,
    required this.semanticLabel,
    required this.enabled,
  });

  final IconData icon;
  final Color backgroundColor;
  final String label;
  final String semanticLabel;
  final bool enabled;
}
