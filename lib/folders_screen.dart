import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'folder.dart';
import 'catalogue_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key, required this.helper});
  final DatabaseHelper helper;
  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  late final CatalogueRepository _repo = CatalogueRepository(widget.helper);
  List<Folder> _folders = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f = await _repo.getFoldersWithCounts();
      if (!mounted) return;
      setState(() { _folders = f; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load folders: $e'; });
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _addFolder() async {
    if (_busy) return;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(labelText: 'Folder name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null) return; // cancelled: nothing written
    if (name.isEmpty) { _snack('Folder name cannot be blank.'); return; }

    setState(() => _busy = true);
    try {
      final id = await _repo.insertFolder(name);
      debugPrint('Inserted folder id=$id'); // record real IDs for T2/T4
    } on DatabaseException catch (e) {
      _snack(e.isUniqueConstraintError() ? 'A folder named "$name" already exists.' : 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load(); // refresh is separate from the write
  }

  Future<void> _deleteFolder(Folder f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${f.name}"?'),
        content: Text('This also deletes its ${f.cardCount} card(s). This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || _busy) return;
    setState(() => _busy = true);
    try {
      final n = await _repo.deleteFolder(f.id!);
      _snack(n == 0 ? 'Nothing was deleted (folder not found).' : 'Deleted "${f.name}".');
    } catch (e) {
      _snack('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      floatingActionButton: FloatingActionButton(
          onPressed: _busy ? null : _addFolder, child: const Icon(Icons.create_new_folder)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _folders.isEmpty
                  ? const Center(child: Text('No folders yet. Tap + to add one.'))
                  : ListView.builder(
                      itemCount: _folders.length,
                      itemBuilder: (_, i) {
                        final f = _folders[i];
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(f.name),
                          subtitle: Text('${f.cardCount} card(s)'),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteFolder(f)),
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => CardsScreen(helper: widget.helper, folder: f, allFolders: _folders)));
                            _load(); // counts may have changed
                          },
                        );
                      },
                    ),
    );
  }
}