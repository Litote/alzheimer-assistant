import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';

class ResponseBubble extends StatelessWidget {
  const ResponseBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      builder: (context, state) {
        final (text, isError, semanticLabel) = switch (state) {
          Listening(interimTranscript: final t) when t.isNotEmpty =>
            (t, false, 'Vous dites : $t'),
          Listening(statusLabel: final l) when l.isNotEmpty =>
            (l, false, 'En cours : $l'),
          Listening(welcomeText: final w) when w.isNotEmpty =>
            (w, false, 'Capacités de l\'assistant : $w'),
          Speaking(responseText: final t) =>
            (t, false, 'Réponse de l\'assistant : $t'),
          AssistantError(message: final m) =>
            (m, true, 'Erreur : $m'),
          _ => ('', false, ''),
        };

        if (text.isEmpty) return const SizedBox.shrink();

        return _AnimatedBubble(
          text: text,
          isError: isError,
          semanticLabel: semanticLabel,
        );
      },
    );
  }
}

class _AnimatedBubble extends StatefulWidget {
  const _AnimatedBubble({
    required this.text,
    required this.isError,
    required this.semanticLabel,
  });
  final String text;
  final bool isError;
  final String semanticLabel;

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: widget.semanticLabel,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Text(
                widget.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: widget.isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                  fontStyle: widget.isError ? FontStyle.italic : FontStyle.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
