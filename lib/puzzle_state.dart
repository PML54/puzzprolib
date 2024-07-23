import 'dart:math';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import 'utils/function_counter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;





final puzzleProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>(
        (ref) => PuzzleNotifier());
///Riverpod : Facilite les tests unitaires et d'intégration en permettant
/// de remplacer facilement les providers par des mocks.
class PuzzleConfiguration {
  final int nbLines;
  final int nbCols;
  final double ratio;
  final int nbPieces;

  PuzzleConfiguration(this.nbLines, this.nbCols, this.ratio, this.nbPieces);
}

///Définition :
///StateNotifier est une classe qui gère un état mutable de manière immutable.
/// Elle est conçue pour être utilisée avec Riverpod,
///Elle contient un état (state) qui peut être mis à jour.
///Chaque mise à jour de l'état crée une nouvelle instance de létat,
///respectant ainsi le principe d'immutabilité.

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  static const String VERSION_KEY = 'puzzle_resources_version';
  static const String CURRENT_VERSION = '1.0.0';
  static final List<PuzzleConfiguration> configurations = [
    PuzzleConfiguration(3, 5, 0.60, 16),
    PuzzleConfiguration(4, 5, 0.80, 16),
    PuzzleConfiguration(5, 4, 1.25, 20),
    PuzzleConfiguration(4, 3, 1.33, 12),
    PuzzleConfiguration(3, 2, 1.50, 6),
    PuzzleConfiguration(5, 3, 1.67, 15),
    PuzzleConfiguration(9, 5, 1.8, 45),
    PuzzleConfiguration(4, 2, 2.00, 8),
    PuzzleConfiguration(5, 2, 2.50, 10),
    PuzzleConfiguration(4, 4, 1.00, 16),
    PuzzleConfiguration(5, 4, 1.25, 20),
    PuzzleConfiguration(4, 3, 1.33, 12),
    PuzzleConfiguration(3, 2, 1.50, 6),
    PuzzleConfiguration(5, 3, 1.67, 15),
    PuzzleConfiguration(4, 2, 2.00, 8),
    PuzzleConfiguration(5, 2, 2.50, 10),
  ];
  final FunctionCounter _counter = FunctionCounter();

  PuzzleNotifier()
      : super(PuzzleState(
    isInitialized: false,
    pieces: [],
    columns: 0,
    rows: 0,
    imageSize: Size.zero,
    currentArrangement: [],
    hasSeenDocumentation: false,
  ));
  Future<void> applyNewDifficulty() async {
    if (state.fullImage != null) {
      // Ajout d'un délai artificiel pour rendre le changement visible
      await Future.delayed(const Duration(seconds: 2));

      await initializePuzzle(
        state.fullImage!,
        state.fullImage!,
        state.currentImageName ?? '',
        Duration.zero,
        Duration.zero,
        true,
        state.categ,
      );
      shufflePieces();
    }
  }
  int countCorrectPieces() {
    _counter.increment('countCorrectPieces');
    return state.currentArrangement
        .asMap()
        .entries
        .where((entry) => entry.key == entry.value)
        .length;
  }


  Map<String, Duration> getDetailedProcessingTimes() {
    return Map.from(state.processingTimes);
  }

  // Ajoutez cette méthode pour accéder aux compteurs
  Map<String, int> getFunctionCounts() {
    return _counter.getAllCounts();
  }

  Duration getTotalProcessingTime() {
    return state.processingTimes.values
        .fold(Duration.zero, (prev, curr) => prev + curr);
  }

  Future<void> initialize() async {
    _counter.increment('initialize');
  }

  Future<void> initializePuzzle(
      Uint8List originalImageBytes,
      Uint8List optimizedImageBytes,
      String imageName,
      Duration loadingTime,
      Duration optimizationTime,
      bool isAssetImage, // Nouveau paramètre
      String category,
      ) async {
    _counter.increment('initializePuzzle');
    final Stopwatch totalStopwatch = Stopwatch()..start();
    final Map<String, Duration> detailedTimes = {};

    // Utilisez directement originalImageBytes si c'est une image d'asset
    final imageToUse = isAssetImage ? originalImageBytes : optimizedImageBytes;
    // On  va prendre original
    final decodeStopwatch = Stopwatch()..start();
    //final image = img.decodeImage(imageToUse);

    // Elle prend des données d'image brutes (généralement sous forme de Uint8List)
    // et les convertit en un objet Image utilisable.
    final image = await compute(img.decodeImage, imageToUse);
    if (image == null) {
      throw Exception("Impossible de décoder l'image");
    }

    detailedTimes['decoding'] = decodeStopwatch.elapsed;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final aspectRatio = image.width / image.height;

    int columns, rows;
    if (state.useCustomGridSize) {
      columns = state.difficultyCols;
      rows = state.difficultyRows;
    } else {
      (columns, rows) = _determineOptimalGridSize(aspectRatio, 3, 5);
    }


    int pieceHeight = image.height~/rows;
    int pieceWidth = image.width~/columns;


    final adjustedImage = removeExcessPixels(image, columns, rows);


    // Créer les pièces du puzzle
    final piecesStopwatch = Stopwatch()..start();

    final pieces = await compute(_createPuzzlePieces, {
      'image': image,
      'rows': rows,
      'columns': columns,
      'pieceheight': pieceHeight,
      'piecewidth': pieceWidth,
    });

    detailedTimes['pieces_creation'] = piecesStopwatch.elapsed;

    final arrangement = List.generate(pieces.length, (index) => index);
    final totalInitializationTime = totalStopwatch.elapsed;

    // Mesure du temps de mise à jour de l'état
    final updateStateStopwatch = Stopwatch()..start();
    state = state.copyWith(
      isInitialized: true,
      pieces: pieces,
      columns: columns,
      rows: rows,
      imageSize: imageSize,
      currentArrangement: arrangement,
      currentImageName: imageName,
      currentImageTitle: imageName,
      fullImage: imageToUse,
      swapCount: 0,
      minimalMoves: 0,
      originalImageSize: originalImageBytes.length,
      optimizedImageSize:
      isAssetImage ? originalImageBytes.length : optimizedImageBytes.length,
      originalImageDimensions:
      Size(image.width.toDouble(), image.height.toDouble()),
      optimizedImageDimensions:
      Size(image.width.toDouble(), image.height.toDouble()),
      processingTimes: {
        'loading': loadingTime,
        'optimization': isAssetImage ? Duration.zero : optimizationTime,
        'initialization': totalInitializationTime,
        ...detailedTimes,
        'state_update': updateStateStopwatch.elapsed,
      },
      categ: category,
    );

    print('Detailed initialization times:');
    detailedTimes.forEach((key, value) {
      print('$key: ${value.inMilliseconds}ms');
    });
    print(
        'Total initialization time: ${totalInitializationTime.inMilliseconds}ms');
  }


  bool isGameComplete() {
    _counter.increment('isGameComplete');
    for (int i = 0; i < state.currentArrangement.length; i++) {
      if (state.currentArrangement[i] != i) {
        return false;
      }
    }
    return true;
  }
  bool isPuzzleComplete() {
    return state.currentArrangement
        .asMap()
        .entries
        .every((entry) => entry.key == entry.value);
  }

  Future<Map<String, dynamic>?> loadMetadata() async {
    _counter.increment('loadMetadata');
    return null;

    // ... (le code de loadMetadata reste ici)
  }

  //<PML>  pas dans la version
  Future<Uint8List> optimizeImage(Uint8List imageBytes,
      {int quality = 75}) async {
    return await compute(
            (Map<String, dynamic> args) => _optimizeImage(imageBytes, quality),
        {'imageBytes': imageBytes, 'quality': quality});
  }

  img.Image removeColumnsAndRows(
      img.Image source,
      int columnsToRemove,
      int rowsToRemove,
      {
        RemoveDirection columnDirection = RemoveDirection.fromEnd,
        RemoveDirection rowDirection = RemoveDirection.fromEnd
      }
      ) {
    int newWidth = source.width - columnsToRemove;
    int newHeight = source.height - rowsToRemove;

    img.Image result = img.Image(width: newWidth, height: newHeight);

    int xOffset = columnDirection == RemoveDirection.fromStart ? columnsToRemove : 0;
    int yOffset = rowDirection == RemoveDirection.fromStart ? rowsToRemove : 0;

    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        result.setPixel(x, y, source.getPixel(x + xOffset, y + yOffset));
      }
    }

    return result;
  }

  //

  img.Image removeExcessPixels(img.Image image, int columns, int rows) {
    int baseWidth = image.width ~/ columns;
    int baseHeight = image.height ~/ rows;

    int newWidth = baseWidth * columns;
    int newHeight = baseHeight * rows;

    // Créer une nouvelle image avec les dimensions ajustées
    img.Image adjustedImage = img.Image(width: newWidth, height: newHeight);

    // Copier les pixels de l'image originale vers la nouvelle image
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        adjustedImage.setPixel(x, y, image.getPixel(x, image.height - newHeight + y));
      }
    }

    return adjustedImage;
  }
  void resetSwapCount() {
    state = state.copyWith(swapCount: 0);
  }

// Dans votre méthode d'initialisation du puzzle
  //
  Future<void> reconstructPuzzle(
      int columns,
      int rows,
      List<int> currentArrangement,
      int swapCount,
      Uint8List imageBytes,
      String imageTitle,
      ) async {
    setLoading(true);

    try {
      final optimizedImageBytes = await optimizeImage(imageBytes, quality: 75);
      final image = await compute(img.decodeImage, optimizedImageBytes);

      if (image == null) {
        throw Exception("Impossible de décoder l'image");
      }

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      int pieceHeight = image.height ~/ rows;
      int pieceWidth = image.width ~/ columns;

      final pieces = await compute(_createPuzzlePieces, {
        'image': image,
        'rows': rows,
        'columns': columns,
        'pieceheight': pieceHeight,
        'piecewidth': pieceWidth,
      });

      state = state.copyWith(
        isInitialized: true,
        pieces: pieces,
        columns: columns,
        rows: rows,
        imageSize: imageSize,
        currentArrangement: currentArrangement,
        currentImageName: imageTitle,
        currentImageTitle: imageTitle,
        fullImage: imageBytes,
        swapCount: swapCount,
        originalImageSize: imageBytes.length,
        optimizedImageSize: optimizedImageBytes.length,
        originalImageDimensions: Size(image.width.toDouble(), image.height.toDouble()),
        optimizedImageDimensions: Size(image.width.toDouble(), image.height.toDouble()),
      );

      setLoading(false);
    } catch (e) {
      print("Erreur lors de la reconstruction du puzzle: $e");
      setError("Erreur lors de la reconstruction du puzzle");
      setLoading(false);
    }
  }
  Future<void> saveMetadata(String imageName) async {
    _counter.increment('saveMetadata');
  }

  Future<void> savePuzzleState([String? imageName]) async {
    _counter.increment('savePuzzleState');
  }
void setCategory(String category) {
    _counter.increment('setCategory');
    state = state.copyWith(categ: category);
  }

  // Dans la classe PuzzleNotifier, ajoutez ces méthodes :
  void setColumns(int columns) {
    state = state.copyWith(columns: columns);
  }

  void setDifficulty(int cols, int rows) {
    state = state.copyWith(
        difficultyCols: cols,
        difficultyRows: rows,
        useCustomGridSize: true
    );
  }

  void resetToOptimalGridSize() {
    state = state.copyWith(useCustomGridSize: false);
  }


  void setDocumentationSeen() {
    _counter.increment('setDocumentationSeen');
    // ... (le code de setDocumentationSeen reste ici)
  }

  void setError(String errorMessage) {
    _counter.increment('setError');
    state = state.copyWith(error: errorMessage);
  }

  void setImageTitle(String title) {
    _counter.increment('setImageTitle');
    state = state.copyWith(currentImageTitle: title);
  }

  void setLoading(bool isLoading) {
    _counter.increment('setLoading');
    if (state.isLoading != isLoading) {

      state = state.copyWith(isLoading: isLoading);
    }
  }
  void setPuzzleReady(bool ready) {
    _counter.increment('setPuzzleReady');
    state = state.copyWith(isInitialized: ready);
  }

  void setRows(int rows) {
    state = state.copyWith(rows: rows);
  }

  void shufflePieces() {
    _counter.increment('shufflePieces');
    final random = Random();
    final n = state.pieces.length;
    int baseSwapCount = n;
    int additionalSwaps =
    random.nextInt((n / 4).round() + 1); // +1 pour inclure n/4
    int swapCount = baseSwapCount + additionalSwaps;

    List<int> newArrangement = List.generate(n, (index) => index);

    for (int i = 0; i < swapCount; i++) {
      int index1 = random.nextInt(n);
      int index2 = random.nextInt(n);
      while (index2 == index1) {
        index2 = random.nextInt(n);
      }

      // Swap
      int temp = newArrangement[index1];
      newArrangement[index1] = newArrangement[index2];
      newArrangement[index2] = temp;
    }

    state = state.copyWith(
      currentArrangement: newArrangement,
      minimalMoves: swapCount,
      swapCount: 0, // Réinitialiser le compteur de coups effectués
    );
  }

  void swapPieces(int index1, int index2) {
    _counter.increment('swapPieces');
    final newArrangement = List<int>.from(state.currentArrangement);
    final temp = newArrangement[index1];
    newArrangement[index1] = newArrangement[index2];
    newArrangement[index2] = temp;
    // Met à jour l'état avec le nouvel arrangement et incrémente le compteur de coups
    state = state.copyWith(
      currentArrangement: newArrangement,
      swapCount: state.swapCount + 1,
    );
  }

  void updateProcessingTimes(Map<String, Duration> times) {
    state =
        state.copyWith(processingTimes: {...state.processingTimes, ...times});
  }

  void updatePuzzleState() {
    _counter.increment('updatePuzzleState');
    savePuzzleState();
  }

  List<Uint8List> _createPuzzlePieces(Map<String, dynamic> params) {
    final img.Image image = params['image'];
    final int rows = params['rows'];
    final int columns = params['columns'];
    final int pieceHeight = params['pieceheight'];
    final int pieceWidth = params['piecewidth'];

    final pieces = <Uint8List>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final piece = img.copyCrop(
          image,
          x: x * pieceWidth,
          y: y * pieceHeight,
          width: pieceWidth,
          height: pieceHeight,
        );
        pieces.add(Uint8List.fromList(img.encodePng(piece)));
      }
    }
    return pieces;
  }
  (int columns, int rows) _determineOptimalGridSize(
      double aspectRatio, int minColumns, int maxColumns) {
    int bestColumns = minColumns;
    int bestRows = (minColumns / aspectRatio).round();
    double bestError = double.infinity;

    for (int testColumns = minColumns;
    testColumns <= maxColumns;
    testColumns++) {
      int testRows = (testColumns / aspectRatio).round();

      // Assurer un minimum de 3 lignes
      testRows = testRows < 3 ? 3 : testRows;

      double currentRatio = testColumns / testRows;
      double error = (currentRatio - aspectRatio).abs();

      if (error < bestError) {
        bestError = error;
        bestColumns = testColumns;
        bestRows = testRows;
      }
    }

    // Ajuster pour éviter les grilles 3x3 et 5x5 si nécessaire
    if (bestRows == 5 && bestColumns == 5) {
      bestRows = 4;
      bestColumns = 4;
    }
    if (bestRows == 3 && bestColumns == 3) {
      bestRows = 4;
      bestColumns = 4;
    }
    if (bestRows >5) bestRows=5;
    if (bestColumns >5) bestColumns=5;
    return (bestColumns, bestRows);
  }

  Uint8List _optimizeImage(Uint8List imageBytes, int quality) {
    _counter.increment('_optimizeImage');
    print("Taille originale: ${imageBytes.length} bytes");

    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Impossible de décoder l'image originale");
    }

// Supprimer les métadonnées EXIF
    //originalImage.exif.clear();

    // Réencoder l'image avec la qualité spécifiée
    final optimizedBytes = img.encodeJpg(originalImage, quality: quality);
    print("Taille après optimisation: ${optimizedBytes.length} bytes");

    return Uint8List.fromList(optimizedBytes);
  }

  static Future<Uint8List> _embedMetadataInImage(Map<String, dynamic> params) async {
    final imageBytes = params['image'] as Uint8List;
    final metadata = params['metadata'] as String;

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception("Impossible de décoder l'image");
    }

    img.drawString(
      image,
      'PUZZLE_METADATA:$metadata',
      font: img.arial14,
      x: 10,
      y: 10,
      color: img.ColorRgba8(255, 255, 255, 100),
    );

    return Uint8List.fromList(img.encodePng(image));
  }



  Future<void> loadSavedPuzzle() async {
    try {
      // Charger l'image sauvegardée
      final savedImageBytes = await _loadSavedImageLocally('puzzle_save.png');
      if (savedImageBytes == null) {
        throw Exception('Aucune sauvegarde trouvée');
      }

      // Extraire les métadonnées de l'image
      final metadata = await compute(_extractMetadataFromImage, savedImageBytes);

      // Reconstruire le puzzle à partir des métadonnées
      await reconstructPuzzle(
        metadata?['columns'],
        metadata!['rows'],
        List<int>.from(metadata['currentArrangement']),
        metadata['swapCount'],
        savedImageBytes,
        metadata['imageTitle'],
      );

      print('Puzzle chargé avec succès');
    } catch (e) {
      print('Erreur lors du chargement du puzzle sauvegardé: $e');
      setError('Erreur lors du chargement du puzzle sauvegardé');
    }
  }

  Future<Uint8List?> _loadSavedImageLocally(String fileName) async {
    // Implémenter le chargement local ici
    // Similaire à _saveImageLocally, cela dépendra de la plateforme

    if (kIsWeb) {
      final base64Image = html.window.localStorage[fileName];
      if (base64Image != null) {
        return base64Decode(base64Image);
      }
    } else {
      // Exemple pour mobile/desktop
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/$fileName');
      // if (await file.exists()) {
      //   return await file.readAsBytes();
      // }
    }
    return null;
  }


  // New
  static const String METADATA_TAG = 'PuzzleAppMetadata';

  Future<void> savePuzzleStateWithImage() async {
    try {
      final currentImage = await generateCurrentImage();
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'imageTitle': state.currentImageTitle,
        'columns': state.columns,
        'rows': state.rows,
        'currentArrangement': state.currentArrangement,
        'swapCount': state.swapCount,
        'minimalMoves': state.minimalMoves,
      };
      final metadataJson = jsonEncode(metadata);
      final imageWithMetadata = await compute(_embedMetadataInImage, {
        'image': currentImage,
        'metadata': metadataJson,
      });
      await _saveImageLocally(imageWithMetadata, 'puzzle_save.png');
      print('Puzzle sauvegardé avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde du puzzle: $e');
      setError('Erreur lors de la sauvegarde du puzzle');
    }
  }

  Future<Uint8List> generateCurrentImage() async {
    final image = img.Image(
      width: state.imageSize.width.toInt(),
      height: state.imageSize.height.toInt(),
    );
    final pieceWidth = state.imageSize.width ~/ state.columns;
    final pieceHeight = state.imageSize.height ~/ state.rows;

    for (int i = 0; i < state.currentArrangement.length; i++) {
      final pieceIndex = state.currentArrangement[i];
      final pieceImageBytes = state.pieces[pieceIndex];
      final pieceImage = img.decodePng(pieceImageBytes);
      if (pieceImage != null) {
        final x = (i % state.columns) * pieceWidth;
        final y = (i ~/ state.columns) * pieceHeight;
        img.compositeImage(
          image,
          pieceImage,
          dstX: x.toInt(),
          dstY: y.toInt(),
        );
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  Future<void> _saveImageLocally(Uint8List imageBytes, String fileName) async {
    if (kIsWeb) {
      // Exemple pour le web
      final base64Image = base64Encode(imageBytes);
      html.window.localStorage[fileName] = base64Image;
      // Utilisez une méthode appropriée pour sauvegarder sur le web
      // Par exemple, avec IndexedDB ou localStorage
    } else {
      // Exemple pour mobile/desktop (nécessite le package path_provider)
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/$fileName');
      // await file.writeAsBytes(imageBytes);
    }
  }
  Future<void> loadPuzzleFromImage(Uint8List imageBytes) async {
    try {
      final metadata = await compute(_extractMetadataFromImage, imageBytes);
      if (metadata != null) {
        await reconstructPuzzle(
          metadata['columns'] as int? ?? 3,
          metadata['rows'] as int? ?? 3,
          List<int>.from(metadata['currentArrangement'] as List<dynamic>? ?? []),
          metadata['swapCount'] as int? ?? 0,
          imageBytes,
          metadata['imageTitle'] as String? ?? 'Puzzle chargé',
        );
        print('Puzzle chargé avec succès');
      } else {
        await initializePuzzle(imageBytes, imageBytes, 'Nouvelle Image', Duration.zero, Duration.zero, false, 'Custom');
        print('Nouvelle image chargée comme puzzle');
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');
      setError('Erreur lors du chargement de l\'image');
    }
  }


  Future<bool> isPuzzleImage(Uint8List imageBytes) async {
    try {
      final metadata = await compute(_extractMetadataFromImage, imageBytes);
      return metadata != null;
    } catch (e) {
      print('Erreur lors de la vérification des métadonnées: $e');
      return false;
    }
  }
  static Map<String, dynamic>? _extractMetadataFromImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final metadataString = String.fromCharCodes(image.getBytes());
    final metadataStart = metadataString.indexOf('PUZZLE_METADATA:');
    if (metadataStart == -1) return null;

    final metadataEnd = metadataString.indexOf('\n', metadataStart);
    final metadataJson = metadataString.substring(metadataStart + 16, metadataEnd != -1 ? metadataEnd : metadataString.length);

    try {
      return jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du décodage des métadonnées: $e');
      return null;
    }
  }



}



class PuzzleState {
  final bool isInitialized;
  final List<Uint8List> pieces;
  final int columns;
  final int rows;
  final int difficultyCols;
  final int difficultyRows;
  final bool useCustomGridSize;  // Ajout de ce champ
  final Size imageSize;
  final List<int> currentArrangement;
  final Uint8List? shuffledImage;
  final Uint8List? fullImage;
  final String? currentImageName;
  final String currentImageTitle;
  final bool hasSeenDocumentation;
  final String? error;
  final int swapCount;
  final int minimalMoves;
  final int originalImageSize;
  final int optimizedImageSize;
  final Size originalImageDimensions;
  final Size optimizedImageDimensions;
  final bool isLoading;
  final String categ;
  final Map<String, Duration> processingTimes;

  PuzzleState({
    required this.isInitialized,
    required this.pieces,
    this.columns = 1,
    this.rows = 1,
    this.difficultyCols = 4,  // valeur par défaut
    this.difficultyRows = 4,  // valeur par défaut
    this.useCustomGridSize = false,

    required this.imageSize,
    required this.currentArrangement,
    this.shuffledImage,
    this.fullImage,
    this.currentImageName,
    this.currentImageTitle = '',
    required this.hasSeenDocumentation,
    this.error,
    this.swapCount = 0,
    this.minimalMoves = 0,
    this.originalImageSize = 0,
    this.optimizedImageSize = 0,
    this.originalImageDimensions = Size.zero,
    this.optimizedImageDimensions = Size.zero,
    this.isLoading = false,
    this.categ = '',
    this.processingTimes = const {},
  });

  PuzzleState copyWith({
    bool? isInitialized,
    List<Uint8List>? pieces,
    int? columns,
    int? rows,
    int? difficultyCols,
    int? difficultyRows,
    bool? useCustomGridSize,
    Size? imageSize,
    List<int>? currentArrangement,
    Uint8List? shuffledImage,
    Uint8List? fullImage,
    String? currentImageName,
    String? currentImageTitle,
    bool? hasSeenDocumentation,
    String? error,
    int? swapCount,
    int? minimalMoves,
    int? originalImageSize,
    int? optimizedImageSize,
    Size? originalImageDimensions,
    Size? optimizedImageDimensions,
    bool? isLoading,
    String? categ,
    Map<String, Duration>? processingTimes,
  }) {
    return PuzzleState(
      isInitialized: isInitialized ?? this.isInitialized,
      pieces: pieces ?? this.pieces,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      difficultyCols: difficultyCols ?? this.difficultyCols,
      difficultyRows: difficultyRows ?? this.difficultyRows,
      useCustomGridSize: useCustomGridSize ?? this.useCustomGridSize,  // Inclusion dans le retour
      imageSize: imageSize ?? this.imageSize,
      currentArrangement: currentArrangement ?? this.currentArrangement,
      shuffledImage: shuffledImage ?? this.shuffledImage,
      fullImage: fullImage ?? this.fullImage,
      currentImageName: currentImageName ?? this.currentImageName,
      currentImageTitle: currentImageTitle ?? this.currentImageTitle,
      hasSeenDocumentation: hasSeenDocumentation ?? this.hasSeenDocumentation,
      error: error ?? this.error,
      swapCount: swapCount ?? this.swapCount,
      minimalMoves: minimalMoves ?? this.minimalMoves,
      originalImageSize: originalImageSize ?? this.originalImageSize,
      optimizedImageSize: optimizedImageSize ?? this.optimizedImageSize,
      originalImageDimensions:
      originalImageDimensions ?? this.originalImageDimensions,
      optimizedImageDimensions:
      optimizedImageDimensions ?? this.optimizedImageDimensions,
      isLoading: isLoading ?? this.isLoading,
      categ: categ ?? this.categ,
      processingTimes: processingTimes ?? this.processingTimes,
    );
  }
}

///StateNotifierProvider :
/// Utilisé pour des états plus complexes avec une logique de mise à jour encapsulée.
enum RemoveDirection { fromStart, fromEnd }

///Encapsulation : Le notifier encapsule toute la logique de gestion de l'état du puzzle.
/// Séparation des préoccupations : L'état (PuzzleState) est séparé de la logique qui le modifie (PuzzleNotifier).
/// Accès aux méthodes : .notifier permet d'accéder aux méthodes qui ne sont pas directement dans l'état,
/// comme countCorrectPieces().

/// En résumé, le notifier du puzzleProvider est l'objet qui contient toute la logique pour manipuler et
/// interroger l'état du puzzle. C'est le "cerveau" derrière la gestion de l'état de votre puzzle dans
/// le contexte de Riverpod.