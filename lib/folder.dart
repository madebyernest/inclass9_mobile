class Folder {
  final int? id;
  final String name;
  final String createdAt;
  final int cardCount; // only filled by getFoldersWithCounts()

  const Folder({this.id, required this.name, required this.createdAt, this.cardCount = 0});

  factory Folder.fromMap(Map<String, Object?> m) => Folder(
        id: m['id'] as int?,
        name: m['name'] as String,
        createdAt: m['created_at'] as String,
        cardCount: (m['card_count'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt,
      };
}