import 'package:flutter/material.dart';
import 'puzzle_game.dart';
class DocumentationPage extends StatelessWidget {
  const DocumentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' 21 Juillet 17:00'),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PuzzleGame()),
        ),
        child: ListView(
          children: [
            _buildDocItem(Icons.inbox, 'Boite à Images '),
            _buildDocItem(Icons.photo_library, 'Ouvrir une de  vos photos'),
            _buildDocItem(Icons.shuffle, 'Mélanger le Puzzle'),
            _buildDocItem(Icons.download, 'Sauver  le Puzzle   '),
            _buildDocItem(Icons.info, 'Afficher cette documentation'),
            const Text('Tapez n\'importe où pour commencer le jeu',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(IconData icon, String explanation) {
    return ListTile(
      leading: Icon(icon),
      title: Text(explanation),
    );
  }
}
