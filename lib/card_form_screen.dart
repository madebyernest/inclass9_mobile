import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'folder.dart';
import 'playing_card.dart';
import 'catalogue_repository.dart';

/// One form for both Add and Edit (existing == null means Add).
class CardFormScreen extends StatefulWidget {
  final DatabaseHelper helper;
  final List<Folder> folders;
  final int initialFolderId;
  final PlayingCard? existing;
  const CardFormScreen(
      {super.key, required this.helper, required this.folders, required this.initialFolderId, this.existing});
  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  late final CatalogueRepository _repo = CatalogueRepository(widget.helper);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _image;
  String? _suit;
  int? _folderId;
  bool _busy = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _image = TextEditingController(text: e?.imageRef ?? '');
    _suit = e?.suit;
    _folderId = e?.folderId ?? widget.initialFolderId;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return; // block duplicate submissions
    if (!_formKey.currentState!.validate()) return; // invalid: write nothing
    setState(() { _busy = true; _saveError = null; });

    final img = _image.text.trim();
    final card = PlayingCard(
      id: widget.existing?.id,
      title: _title.text.trim(),
      suit: _suit!,
      notes: _notes.text.trim(),
      imageRef: img.isEmpty ? null : img,
      folderId: _folderId!,
    );

    try {
      if (widget.existing == null) {
        final id = await _repo.insertCard(card);
        debugPrint('Inserted card id=$id');
      } else {
        final n = await _repo.updateCard(card);
        if (n == 0) throw StateError('That card no longer exists.');
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      // Keep the user's input; show the error.
      setState(() { _busy = false; _saveError = 'Save failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit card' : 'Add card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _suit,
              decoration: const InputDecoration(labelText: 'Suit *'),
              items: kSuits.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text('${e.value} ${e.key}')))
                  .toList(),
              onChanged: (v) => setState(() => _suit = v),
              validator: (v) => (v == null || !kSuits.containsKey(v)) ? 'Pick a suit' : null,
            ),
            DropdownButtonFormField<int>(
              initialValue: _folderId,
              decoration: const InputDecoration(labelText: 'Folder *'),
              items: widget.folders
                  .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                  .toList(),
              onChanged: (v) => setState(() => _folderId = v),
              validator: (v) =>
                  (v == null || !widget.folders.any((f) => f.id == v)) ? 'Pick a valid folder' : null,
            ),
            TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
            TextFormField(
                controller: _image,
                decoration: const InputDecoration(
                    labelText: 'Image reference (optional)', hintText: 'assets/... or https://...')),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context, false), // cancel writes nothing
                      child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? 'Saving…' : 'Save'))),
            ]),
          ]),
        ),
      ),
    );
  }
}