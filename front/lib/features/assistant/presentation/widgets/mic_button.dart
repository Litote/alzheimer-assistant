import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';

class MicButton extends StatefulWidget {
  const MicButton({super.key});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssistantBloc, AssistantState>(
      listener: (context, state) {
        if (state is Listening || state is Speaking || state is Starting || state is Connecting) {
          _controller.repeat(reverse: true);
        } else {
          _controller.stop();
          _controller.reset();
        }
      },
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
                child: ScaleTransition(
                  scale: _pulseAnimation,
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
                                color: config.backgroundColor.withAlpha(150),
                                blurRadius: 30,
                                spreadRadius: 6,
                              )
                            ]
                          : [],
                    ),
                    child: Center(child: _buildIcon(state, config)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                config.label,
                key: ValueKey(config.label),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: config.backgroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIcon(AssistantState state, _ButtonConfig config) {
    if (state is Connecting) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }
    if (state is Starting) {
      return const Icon(Icons.mic, color: Colors.white, size: 40);
    }
    return Icon(config.icon, color: Colors.white, size: 40);
  }

  _ButtonConfig _configFor(AssistantState state) => switch (state) {
        Idle() => const _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: Color(0xFF5B8DEF), // Bleu standard
            label: 'Appuyez pour parler',
            semanticLabel: 'Bouton microphone. Appuyez pour parler à l\'assistant.',
            enabled: true,
          ),
        Starting() => const _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: Color(0xFF81C784), // Vert clair (initialisation)
            label: 'Initialisation…',
            semanticLabel: 'Démarrage de l\'assistant.',
            enabled: true,
          ),
        Connecting() => const _ButtonConfig(
            icon: Icons.sync,
            backgroundColor: Color(0xFF4CAF50), // Vert (on reste en vert pendant la connexion)
            label: 'Connexion…',
            semanticLabel: 'Connexion en cours. Veuillez patienter.',
            enabled: true,
          ),
        Listening() => const _ButtonConfig(
            icon: Icons.mic,
            backgroundColor: Color(0xFF4CAF50), // Vert (priorité utilisateur)
            label: 'Je vous écoute…',
            semanticLabel: 'L\'assistant vous écoute.',
            enabled: true,
          ),
        Speaking() => const _ButtonConfig(
            icon: Icons.record_voice_over,
            backgroundColor: Color(0xFF2196F3), // Bleu vif (l'assistant parle)
            label: 'Réponse…',
            semanticLabel: 'L\'assistant répond. Vous pouvez lui couper la parole.',
            enabled: true,
          ),
        AssistantError() => const _ButtonConfig(
            icon: Icons.refresh,
            backgroundColor: Color(0xFFF44336), // Rouge
            label: 'Erreur. Appuyez pour réessayer',
            semanticLabel: 'Une erreur est survenue. Appuyez pour réessayer.',
            enabled: true,
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
