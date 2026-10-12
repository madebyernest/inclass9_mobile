import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'folder.dart';
import 'playing_card.dart';
import 'catalogue_repository.dart';
import 'card_image.dart';
import 'card_form_screen.dart';

class CardsScreen extends StatefulWidget {
  final DatabaseHelper helper;
  final Folder folder;
  final List<Folder> allFolders;
  const CardsScreen({super.key, required this.helper, required this.folder, required this.allFolders});
  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late final CatalogueRepository _repo = CatalogueRepository(widget.helper);
  List<PlayingCard> _cards = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _repo.getCards(widget.folder.id!); // filtered by ID
      if (!mounted) return;
      setState(() { _cards = c; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load cards: $e'; });
    }
  }

  Future<void> _openForm([PlayingCard? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => CardFormScreen(
              helper: widget.helper,
              folders: widget.allFolders,
              initialFolderId: widget.folder.id!,
              existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(PlayingCard c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${c.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await _repo.deleteCard(c.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(n == 0 ? 'Nothing deleted (card not found).' : 'Deleted "${c.title}".')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      floatingActionButton:
          FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _cards.isEmpty
                  ? const Center(child: Text('This folder has no cards yet.'))
                  : ListView.builder(
                      itemCount: _cards.length,
                      itemBuilder: (_, i) {
                        final c = _cards[i];
                        return ListTile(
                          leading: CardImage(imageRef: c.imageRef, suit: c.suit),
                          title: Text(c.title),
                          subtitle: Text('${kSuits[c.suit] ?? ''} ${c.suit}'
                              '${c.notes.isEmpty ? '' : ' · ${c.notes}'}'),
                          onTap: () => _openForm(c),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(c)),
                        );
                      },
                    ),
    );
  }
}