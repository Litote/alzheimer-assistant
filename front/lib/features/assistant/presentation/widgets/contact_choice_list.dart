import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

/// Contacts proposed after an ambiguous `call_phone` request.
///
/// Tapping a card calls that contact; the user can still answer by voice.
/// Renders nothing when no choice is pending.
class ContactChoiceList extends StatelessWidget {
  const ContactChoiceList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AssistantBloc, AssistantState>(
      buildWhen: (prev, curr) =>
          !listEquals(contactChoicesOf(prev), contactChoicesOf(curr)),
      builder: (context, state) {
        final choices = contactChoicesOf(state);
        if (choices.isEmpty) return const SizedBox.shrink();
        // A single scrollable list (title and cancel included) so that it
        // never overflows on small screens.
        return ListView(
          children: [
            Text(
              'Qui voulez-vous appeler ?',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            for (final candidate in choices) ...[
              _ContactCard(
                candidate: candidate,
                showNumber: _hasHomonym(choices, candidate),
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: TextButton(
                onPressed: () => context
                    .read<AssistantBloc>()
                    .add(const AssistantEvent.contactChoiceCancelled()),
                child: Text('Annuler', style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
        );
      },
    );
  }

  static bool _hasHomonym(List<PhoneCandidate> choices, PhoneCandidate c) =>
      choices.where((o) => o.displayName == c.displayName).length > 1;
}

/// Contacts pending a choice in [state], empty when none.
List<PhoneCandidate> contactChoicesOf(AssistantState state) => switch (state) {
      Idle(:final contactChoices) => contactChoices,
      Listening(:final contactChoices) => contactChoices,
      Speaking(:final contactChoices) => contactChoices,
      _ => const [],
    };

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.candidate, required this.showNumber});

  final PhoneCandidate candidate;

  /// Shows the end of the number to tell apart contacts sharing a name.
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = candidate.number;
    final numberHint =
        '… ${number.length > 4 ? number.substring(number.length - 4) : number}';
    return Semantics(
      button: true,
      label: 'Appeler ${candidate.displayName}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context
              .read<AssistantBloc>()
              .add(AssistantEvent.contactChosen(candidate)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      _initials(candidate.displayName),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          candidate.displayName,
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (showNumber)
                          Text(
                            numberHint,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.phone,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
