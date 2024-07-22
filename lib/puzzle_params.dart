import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'puzzle_state.dart';

class DifficultySettingsScreen extends ConsumerStatefulWidget {
  const DifficultySettingsScreen({super.key});

  @override
  _DifficultySettingsScreenState createState() => _DifficultySettingsScreenState();
}

class _DifficultySettingsScreenState extends ConsumerState<DifficultySettingsScreen> {
  bool isRedecouping = false;
  String lesParams = "Paramétrage";
  String reDecoupage = "reDecoupage en cours.....";

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(puzzleProvider);
    String leTitre = isRedecouping ? reDecoupage : lesParams;

    return Scaffold(
      appBar: AppBar(title: Text(leTitre)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cubes par Ligne: ${puzzleState.difficultyCols}'),
            Slider(
              value: puzzleState.difficultyCols.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: puzzleState.difficultyCols.toString(),
              onChanged: (double value) {
                ref.read(puzzleProvider.notifier).setDifficulty(value.toInt(), puzzleState.difficultyRows);
              },
            ),
            const SizedBox(height: 20),
            Text('Cubes par Colonne: ${puzzleState.difficultyRows}'),
            Slider(
              value: puzzleState.difficultyRows.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: puzzleState.difficultyRows.toString(),
              onChanged: (double value) {
                ref.read(puzzleProvider.notifier).setDifficulty(puzzleState.difficultyCols, value.toInt());
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text('Appliquer'),
                  onPressed: () async {
                    setState(() {
                      isRedecouping = true;
                    });
                    await ref.read(puzzleProvider.notifier).applyNewDifficulty();
                    setState(() {
                      isRedecouping = false;
                    });
                    Navigator.of(context).pop(); // Retourne à l'écran principal
                  },
                ),
                ElevatedButton(
                  child: const Text('Réinitialiser'),
                  onPressed: () {
                    ref.read(puzzleProvider.notifier).resetToOptimalGridSize();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}