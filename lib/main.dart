import 'package:flutter/material.dart';
import 'folders_screen.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  try {
    await helper.init();
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Could not open local storage. Restart the app and check the logs.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }
  runApp(DirectoryApp(helper: helper));
}

class DirectoryApp extends StatelessWidget {
  const DirectoryApp({super.key, required this.helper});

  final DatabaseHelper helper;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Festival Roster',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: RosterScreen(helper: helper),
    );
  }
}

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key, required this.helper});

  final DatabaseHelper helper;

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  List<Map<String, dynamic>> _rows = [];
  int _count = 0;
  bool _initialLoadDone = false;
  bool _busy = false; // one flag disables every DB-related control
  String? _readError; // set when a read fails
  String? _message; // text feedback for the last action
  int? _selectedId; // ID of the row being edited (null = Add mode)

  @override
  void initState() {
    super.initState();
    _refreshOnly();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ---------- Reading ----------

  /// Queries rows + count. Returns null on success or an error string.
  Future<String?> _reload() async {
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();
      if (!mounted) return null;
      setState(() {
        _rows = rows;
        _count = count;
        _readError = null;
        _initialLoadDone = true;
      });
      return null;
    } catch (error, stackTrace) {
      debugPrint('Read failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _readError = 'Could not read the roster. Tap Refresh to retry.';
          _initialLoadDone = true;
        });
      }
      return 'read failed';
    }
  }

  /// Used by initState and the Refresh button.
  Future<void> _refreshOnly() async {
    if (_busy && _initialLoadDone) return;
    setState(() {
      _busy = true;
    });
    try {
      await _reload();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ---------- Validation ----------

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a name (spaces only is not allowed).';
    }
    return null;
  }

  String? _validateAge(String? value) {
    final age = int.tryParse((value ?? '').trim());
    if (age == null) return 'Enter a whole number (no decimals or letters).';
    if (age < 0 || age > 130) return 'Age must be from 0 to 130.';
    return null;
  }

  // ---------- Add / Update ----------

  Future<void> _save() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final editingId = _selectedId;

    setState(() {
      _busy = true;
      _message = null;
    });

    String message;
    bool clearForm = false;
    bool clearSelection = false;

    try {
      if (editingId == null) {
        final id = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });
        message = 'Added "$name", age $age, with ID $id.';
        clearForm = true;
      } else {
        final updated = await widget.helper.update({
          DatabaseHelper.columnId: editingId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });
        if (updated == 1) {
          message = 'Updated ID $editingId: "$name", age $age '
              '($updated row affected).';
          clearForm = true;
          clearSelection = true;
        } else {
          message = 'ID $editingId was not found ($updated rows affected). '
              'It may have been deleted. Reloading the list.';
          clearSelection = true; // row is gone; keep typed input
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Write failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _busy = false;
          _message = 'Could not save. Your input was kept; please try again.';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      if (clearForm) {
        _nameController.clear();
        _ageController.clear();
        _formKey.currentState?.reset();
      }
      if (clearSelection) _selectedId = null;
    });

    try {
      final refreshError = await _reload();
      if (mounted) {
        setState(() {
          _message = refreshError == null
              ? message
              : 'Saved, but refresh failed. Tap Refresh to reload the list.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ---------- Edit ----------

  void _startEdit(Map<String, dynamic> row) {
    if (_busy) return;
    setState(() {
      _selectedId = row[DatabaseHelper.columnId] as int;
      _nameController.text = row[DatabaseHelper.columnName] as String;
      _ageController.text = '${row[DatabaseHelper.columnAge]}';
      _message = 'Editing ID $_selectedId.';
    });
  }

  void _cancelEdit() {
    if (_busy) return;
    setState(() {
      _selectedId = null;
      _nameController.clear();
      _ageController.clear();
      _formKey.currentState?.reset();
      _message = 'Edit canceled. Nothing was changed.';
    });
  }

  // ---------- Delete ----------

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    if (_busy) return;
    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete guest?'),
        content: Text('Delete ID $id ("$name")? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      if (mounted) {
        setState(() {
          _message = 'Deletion canceled. Nothing was changed.';
        });
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    String message;
    try {
      final deleted = await widget.helper.delete(id);
      message = deleted == 1
          ? 'Deleted ID $id ("$name") ($deleted row affected).'
          : 'ID $id was not found ($deleted rows affected). Reloading the list.';
      if (mounted && _selectedId == id) {
        setState(() {
          _selectedId = null;
          _nameController.clear();
          _ageController.clear();
          _formKey.currentState?.reset();
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Delete failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _busy = false;
          _message = 'Could not delete ID $id. Please try again.';
        });
      }
      return;
    }

    try {
      final refreshError = await _reload();
      if (mounted) {
        setState(() {
          _message = refreshError == null
              ? message
              : 'Deleted, but refresh failed. Tap Refresh to reload the list.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final editing = _selectedId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Festival Roster'),
        actions: [
          IconButton(
            tooltip: 'Card catalogue',
            icon: const Icon(Icons.folder),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FoldersScreen(helper: widget.helper),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing ? 'Edit guest (ID $_selectedId)' : 'Add a guest',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ageController,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Age (0-130)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      validator: _validateAge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _busy ? null : _save,
                          child: Text(editing ? 'Save' : 'Add'),
                        ),
                        OutlinedButton(
                          onPressed: (_busy || !editing) ? null : _cancelEdit,
                          child: const Text('Cancel edit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _refreshOnly,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_message!),
                ),
              Text(
                'Guests: $_count',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (!_initialLoadDone) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_readError != null) {
      return Center(child: Text(_readError!, textAlign: TextAlign.center));
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No festival guests yet. Add the first pumpkin-patch pal!',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Stack(
      children: [
        ListView.separated(
          itemCount: _rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = _rows[index];
            final id = row[DatabaseHelper.columnId];
            return ListTile(
              title: Text('${row[DatabaseHelper.columnName]}'),
              subtitle: Text('ID: $id  |  Age: ${row[DatabaseHelper.columnAge]}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit ID $id',
                    icon: const Icon(Icons.edit),
                    onPressed: _busy ? null : () => _startEdit(row),
                  ),
                  IconButton(
                    tooltip: 'Delete ID $id',
                    icon: const Icon(Icons.delete),
                    onPressed: _busy ? null : () => _confirmDelete(row),
                  ),
                ],
              ),
            );
          },
        ),
        if (_busy)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}