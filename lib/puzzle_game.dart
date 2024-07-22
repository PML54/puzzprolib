import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'pmlsoft.dart';
import 'puzzle_state.dart';
import 'puzzle_params.dart';
import 'utils/function_counter.dart';

final FunctionCounter _counter = FunctionCounter();

class PuzzleBoard extends ConsumerWidget {
  const PuzzleBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(puzzleProvider);
    final correctPieces = ref.read(puzzleProvider.notifier).countCorrectPieces();
    final isComplete = correctPieces == puzzleState.pieces.length;
    _counter.increment('build PuzzleBoard');

    if (!puzzleState.isInitialized || puzzleState.columns == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = AppBar().preferredSize.height;
    final availableHeight = screenSize.height - appBarHeight;
    final imageAspectRatio = puzzleState.imageSize.width / puzzleState.imageSize.height;

    double puzzleWidth, puzzleHeight;
    if (imageAspectRatio > screenSize.width / availableHeight) {
      puzzleWidth = screenSize.width;
      puzzleHeight = screenSize.width / imageAspectRatio;
    } else {
      puzzleHeight = availableHeight;
      puzzleWidth = availableHeight * imageAspectRatio;
    }

    double pieceWidth = puzzleWidth / puzzleState.columns;
    double pieceHeight = puzzleHeight / puzzleState.rows;

    Widget buildCompletionText(PuzzleState puzzleState) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                puzzleState.currentImageTitle,
                style: const TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: puzzleWidth,
            height: puzzleHeight,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: puzzleState.columns,
                childAspectRatio: pieceWidth / pieceHeight,
              ),
              itemCount: puzzleState.pieces.length,
              itemBuilder: (context, index) {
                final pieceIndex = puzzleState.currentArrangement[index];
                return DragTarget<int>(
                  onAcceptWithDetails: (details) {
                    ref.read(puzzleProvider.notifier).swapPieces(details.data, index);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Draggable<int>(
                      data: index,
                      feedback: Image.memory(
                        puzzleState.pieces[pieceIndex],
                        width: pieceWidth,
                        height: pieceHeight,
                        fit: BoxFit.cover,
                      ),
                      childWhenDragging: Container(
                        width: pieceWidth,
                        height: pieceHeight,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.5),
                        ),
                        child: Image.memory(
                          puzzleState.pieces[pieceIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (isComplete)
          Positioned(
            left: 20,
            top: 20,
            child: Draggable<String>(
              feedback: buildCompletionText(puzzleState),
              childWhenDragging: Container(),
              child: buildCompletionText(puzzleState),
            ),
          ),
      ],
    );
  }
}

class PuzzleGame extends ConsumerStatefulWidget {
  const PuzzleGame({super.key});

  @override
  ConsumerState<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends ConsumerState<PuzzleGame> {
  bool _showFullImage = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRandomImage(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleFullImage() {
    setState(() {
      _showFullImage = true;
    });

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _showFullImage = false;
      });
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      _loadCustomImage(imageBytes, image.name);
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final Uint8List photoBytes = await photo.readAsBytes();
      _loadCustomImage(photoBytes, 'Photo_${DateTime.now().toIso8601String()}.jpg');
    }
  }

  Future<void> _loadCustomImage(Uint8List imageBytes, String imageName) async {
    ref.read(puzzleProvider.notifier).setLoading(true);
    ref.read(puzzleProvider.notifier).setImageTitle(imageName);
    ref.read(puzzleProvider.notifier).resetSwapCount();

    try {
      final Stopwatch stopwatch = Stopwatch()..start();

      final loadingTime = stopwatch.elapsed;
      stopwatch.stop();
      stopwatch.reset();

      stopwatch.start();
      await ref.read(puzzleProvider.notifier).initializePuzzle(
        imageBytes,
        imageBytes,
        imageName,
        loadingTime,
        Duration.zero,
        false,
        'Custom',
      );

      final initializationTime = stopwatch.elapsed;
      stopwatch.stop();

      ref.read(puzzleProvider.notifier).shufflePieces();
      ref.read(puzzleProvider.notifier).setPuzzleReady(true);

      ref.read(puzzleProvider.notifier).updateProcessingTimes({
        'loading': loadingTime,
        'initialization': initializationTime,
      });
    } catch (e) {
      print("Erreur lors du chargement de l'image: $e");
      ref.read(puzzleProvider.notifier).setError("Erreur lors du chargement de l'image");
    } finally {
      ref.read(puzzleProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(puzzleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(puzzleState.isLoading ? "Découpage en cours...v7.2107" : ""),
            const SizedBox(width: 10),
            if (!puzzleState.isLoading) ...[
              Tooltip(
                message: puzzleState.currentImageTitle,
                child: Text(
                  '${ref.read(puzzleProvider.notifier).countCorrectPieces()} / ${puzzleState.pieces.length}',
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Résolu en  ${puzzleState.minimalMoves})',
                child: Text(
                  '${puzzleState.swapCount} Coups',
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!puzzleState.isLoading) ...[
            IconButton(
              icon: const Icon(Icons.inbox, color: Colors.greenAccent),
              onPressed: () => _loadRandomImage(context),
              tooltip: 'Boite à Images',
              iconSize: 35.0,
            ),
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _pickImage,
              tooltip: 'Choisir une image',
              iconSize: 35.0,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _takePhoto,
              tooltip: 'Prendre une photo',
              iconSize: 35.0,
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: _toggleFullImage,
              tooltip: 'Voir le puzzle',
              iconSize: 35.0,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DifficultySettingsScreen()),
                );
              },
            ),
    /*        IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('22/07 08:10'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Taille originale: ${puzzleState.originalImageSize} bytes'),
                          Text('Dimensions originales: ${puzzleState.originalImageDimensions.width.round()}x${puzzleState.originalImageDimensions.height.round()}'),
                          Text('Taille optimisée: ${puzzleState.optimizedImageSize} bytes'),
                          Text('Dimensions optimisées: ${puzzleState.optimizedImageDimensions.width.round()}x${puzzleState.optimizedImageDimensions.height.round()}'),
                          Text('Chargement: ${puzzleState.processingTimes['loading']?.inMilliseconds}ms'),
                          Text('Optimisation: ${puzzleState.processingTimes['optimization']?.inMilliseconds}ms'),
                          Text('Initialisation: ${puzzleState.processingTimes['initialization']?.inMilliseconds}ms'),
                          Text('Décodage: ${puzzleState.processingTimes['decoding']?.inMilliseconds}ms'),
                          Text('Redimensionnement: ${puzzleState.processingTimes['resizing']?.inMilliseconds}ms'),
                          Text('Création des pièces: ${puzzleState.processingTimes['pieces_creation']?.inMilliseconds}ms'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Fermer'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),*/
          ],
        ],
      ),
      body: Stack(
        children: [
          if (_showFullImage)
            Center(
              child: Image.memory(
                puzzleState.fullImage!,
                fit: BoxFit.contain,
              ),
            )
          else if (puzzleState.isInitialized)
            const PuzzleBoard()
          else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _loadRandomImage(BuildContext context) async {
    _counter.increment('_loadRandomImage');
    final random = Random();
    final randomImage = imageList[random.nextInt(imageList.length)];
    ref.read(puzzleProvider.notifier).setLoading(true);
    ref.read(puzzleProvider.notifier).setImageTitle(randomImage['name']!);
    ref.read(puzzleProvider.notifier).resetSwapCount();

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final String assetPath = 'assets/${randomImage['file']}';
      final ByteData data = await DefaultAssetBundle.of(context).load(assetPath);
      final Uint8List imageBytes = data.buffer.asUint8List();

      final loadingTime = stopwatch.elapsed;
      stopwatch.stop();
      stopwatch.reset();

      final optimizedImageBytes = imageBytes;
      const optimizationTime = Duration.zero;

      stopwatch.start();
      await ref.read(puzzleProvider.notifier).initializePuzzle(
        imageBytes,
        optimizedImageBytes,
        randomImage['name']!,
        loadingTime,
        optimizationTime,
        true,
        randomImage['categ']!,
      );

      final initializationTime = stopwatch.elapsed;
      stopwatch.stop();

      ref.read(puzzleProvider.notifier).shufflePieces();
      ref.read(puzzleProvider.notifier).setPuzzleReady(true);

      ref.read(puzzleProvider.notifier).updateProcessingTimes({
        'loading': loadingTime,
        'optimization': optimizationTime,
        'initialization': initializationTime,
      });
    } catch (e) {
      print("Erreur lors du chargement de l'image: $e");
      ref.read(puzzleProvider.notifier).setError("Erreur lors du chargement de l'image");
    } finally {
      ref.read(puzzleProvider.notifier).setLoading(false);
    }
  }
}