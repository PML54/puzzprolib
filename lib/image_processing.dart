/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:universal_html/html.dart' as html;

import 'package:flutter/foundation.dart';
import 'puzzle_state.dart';
import 'utils/function_counter.dart';
final FunctionCounter _counter = FunctionCounter();




Future<void> downloadCurrentImage(BuildContext context, WidgetRef ref) async {
  _counter.increment('downloadCurrentImage');
  try {
    final puzzleNotifier = ref.read(puzzleProvider.notifier);
    final image = await puzzleNotifier.generateCurrentImage();

    final blob = html.Blob([image]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'puzzle_current_state.png';
    html.document.body!.children.add(anchor);

    anchor.click();

    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

  } catch (e) {
    print('Erreur lors du téléchargement: $e');
  }
}


class ImageSplitParams {
  final img.Image image;
  final int columns;
  final int rows;

  ImageSplitParams(this.image, this.columns, this.rows);
}

class ShuffleImageParams {
  final List<Uint8List> pieces;
  final int columns;
  final int rows;
  final Size imageSize;

  ShuffleImageParams(this.pieces, this.columns, this.rows, this.imageSize);
}
*/
