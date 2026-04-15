import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/mic_button.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/widgets/response_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AssistantBloc>().add(const AssistantEvent.appResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _Header(),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: ResponseBubble(),
                      ),
                    ),
                    const MicButton(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                tooltip: 'Paramètres avancés',
                onPressed: () => context.push('/settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AssistantBloc, AssistantState>(
      buildWhen: (prev, curr) => curr != prev,
      builder: (context, state) {
        final subtitle = switch (state) {
          Idle() || AssistantError() =>
            'Appuyez sur le bouton pour me parler.',
          Starting() => '…',
          Connecting() => '…',
          Listening() => 'Je vous écoute…',
          Speaking() => 'Je vous réponds.',
        };

        return Column(
          children: [
            Text(
              'Bonjour, je suis là\npour vous aider',
              style: theme.textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                subtitle,
                key: ValueKey(subtitle),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
