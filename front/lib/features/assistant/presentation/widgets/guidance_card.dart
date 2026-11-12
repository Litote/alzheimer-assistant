import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/domain/entities/guidance.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';

/// Current step of the walking guidance: where the user is going, the
/// direction to take and for how long.
///
/// The instruction is the exact text of the server, never the words of the
/// model. Renders nothing when no guidance is in progress.
class GuidanceCard extends StatelessWidget {
  const GuidanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocSelector<AssistantBloc, AssistantState, Guidance?>(
      selector: guidanceOf,
      builder: (context, guidance) {
        if (guidance == null) return const SizedBox.shrink();
        // Scrollable so that a long instruction never overflows on small screens.
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (guidance.destination.isNotEmpty) ...[
                  Text(
                    'Vers ${guidance.destination}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    maneuverIcon(guidance.maneuver),
                    key: const Key('guidance-maneuver'),
                    size: 80,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  guidance.instruction,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (guidance.distanceMeters >= 10) ...[
                  const SizedBox(height: 12),
                  Text(
                    'puis ${guidance.distanceMeters} mètres',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Step of the walking guidance in progress in [state], `null` when none.
Guidance? guidanceOf(AssistantState state) => switch (state) {
      Listening(:final guidance) => guidance,
      Speaking(:final guidance) => guidance,
      _ => null,
    };

/// Arrow for a manoeuvre of the routing service (`TURN_LEFT`, `UTURN_RIGHT`…).
/// Anything unknown is shown as "straight on".
IconData maneuverIcon(String maneuver) {
  if (maneuver.contains('UTURN')) return Icons.u_turn_left;
  if (maneuver.contains('LEFT')) return Icons.turn_left;
  if (maneuver.contains('RIGHT')) return Icons.turn_right;
  return Icons.straight;
}
