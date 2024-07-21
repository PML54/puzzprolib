import 'package:test/test.dart';
import 'puzzle_state.dart';


void main() {
  group('PuzzleNotifier', () {
    late PuzzleNotifier notifier;

    setUp(() {
      // Cette fonction est appelée avant chaque test dans ce groupe
      notifier = PuzzleNotifier();
    });

    test('initial state should be correct', () {
      expect(notifier.state.isInitialized, false);
      expect(notifier.state.pieces, isEmpty);
      // ... autres assertions sur l'état initial
    });

    test('swapPieces should correctly swap two pieces', () {
      notifier.state = notifier.state.copyWith(
        currentArrangement: [0, 1, 2, 3],
        // ... autres propriétés nécessaires
      );

      notifier.swapPieces(0, 2);

      expect(notifier.state.currentArrangement, [2, 1, 0, 3]);
    });

    test('isGameComplete should return true when puzzle is solved', () {
      notifier.state = notifier.state.copyWith(
        currentArrangement: [0, 1, 2, 3],
        // ... autres propriétés nécessaires
      );

      expect(notifier.isGameComplete(), true);
    });

    // ... d'autres tests pour PuzzleNotifier
  });

  // Vous pouvez avoir d'autres groupes pour d'autres classes ou fonctionnalités
  group('PuzzleState', () {
    // Tests spécifiques à PuzzleState
  });
}