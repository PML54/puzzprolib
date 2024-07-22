import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'puzzle_state.dart';

class DifficultySettingsScreen extends ConsumerWidget {
  const DifficultySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(puzzleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de difficulté'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre de colonnes: ${puzzleState.columns}'),
            Slider(
              value: puzzleState.columns.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              label: puzzleState.columns.toString(),
              onChanged: (double value) {
                ref.read(puzzleProvider.notifier).setColumns(value.toInt());
              },
            ),
            const SizedBox(height: 20),
            Text('Nombre de lignes: ${puzzleState.rows}'),
            Slider(
              value: puzzleState.rows.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              label: puzzleState.rows.toString(),
              onChanged: (double value) {
                ref.read(puzzleProvider.notifier).setRows(value.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }
}