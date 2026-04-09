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
          Listening(imageUrl: final img) when img.isNotEmpty =>
            ('', false, 'Photo — appuyez pour agrandir'),
          Listening(interimTranscript: final t) when t.isNotEmpty =>
            (t, false, 'Vous dites : $t'),
          Listening(statusLabel: final l) when l.isNotEmpty =>
            (l, false, 'En cours : $l'),
          Listening(welcomeText: final w) when w.isNotEmpty =>
            (w, false, 'Capacités de l\'assistant : $w'),
          // When an image is displayed, suppress all text so only the image
          // (and its tap hint) appears.
          Speaking(imageUrl: final img) when img.isNotEmpty =>
            ('', false, 'Photo — appuyez pour agrandir'),
          Idle(imageUrl: final img) when img.isNotEmpty =>
            ('', false, 'Photo — appuyez pour agrandir'),
          Speaking(responseText: final r) when r.isNotEmpty =>
            (r, false, 'Réponse de l\'assistant : $r'),
          Speaking(userTranscript: final u) when u.isNotEmpty =>
            (u, false, 'Vous avez dit : $u'),
          AssistantError(message: final m) =>
            (m, true, 'Erreur : $m'),
          _ => ('', false, ''),
        };

        final imageUrl = switch (state) {
          Speaking(:final imageUrl) => imageUrl,
          Listening(:final imageUrl) => imageUrl,
          Idle(:final imageUrl) => imageUrl,
          _ => '',
        };

        if (text.isEmpty && imageUrl.isEmpty) return const SizedBox.shrink();

        // Image in Speaking state: fill the Expanded area from HomeScreen.
        if (imageUrl.isNotEmpty) {
          return _AnimatedBubble(
            text: text,
            imageUrl: imageUrl,
            isError: isError,
            semanticLabel: semanticLabel,
            fillHeight: true,
          );
        }

        // Text only: center within the Expanded area.
        return Center(
          child: _AnimatedBubble(
            text: text,
            imageUrl: imageUrl,
            isError: isError,
            semanticLabel: semanticLabel,
          ),
        );
      },
    );
  }
}

// ── Full-screen image viewer ──────────────────────────────────────────────

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            semanticLabel: 'Photo en plein écran',
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, _, __) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated bubble ───────────────────────────────────────────────────────
//
// Two modes:
//   fillHeight=false (default) — min-size card for text content, must be
//     wrapped in Center by the caller so it stays vertically centered.
//   fillHeight=true — card expands to fill the parent (used when an image is
//     displayed so it occupies all the space between header and mic button).

class _AnimatedBubble extends StatefulWidget {
  const _AnimatedBubble({
    required this.text,
    required this.imageUrl,
    required this.isError,
    required this.semanticLabel,
    this.fillHeight = false,
  });
  final String text;
  final String imageUrl;
  final bool isError;
  final String semanticLabel;
  final bool fillHeight;

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
      begin: const Offset(0, 0.04),
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
              child: widget.fillHeight
                  ? _buildImageContent(context, theme)
                  : _buildTextContent(theme),
            ),
          ),
        ),
      ),
    );
  }

  /// Full-height layout: image fills the column via [Expanded], hint below.
  Widget _buildImageContent(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    _FullScreenImagePage(imageUrl: widget.imageUrl),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                semanticLabel: 'Photo',
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, _, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.zoom_in,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Appuyez pour agrandir',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact layout: min-size card for text content.
  Widget _buildTextContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.text.isNotEmpty)
          Text(
            widget.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
              fontStyle:
                  widget.isError ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
