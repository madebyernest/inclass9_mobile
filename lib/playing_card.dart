// Named PlayingCard (not Card) to avoid clashing with Flutter's Card widget.
const Map<String, String> kSuits = {
  'Spades': '♠',
  'Hearts': '♥',
  'Diamonds': '♦',
  'Clubs': '♣',
};

class PlayingCard {
  final int? id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;

  const PlayingCard({
    this.id,
    required this.title,
    required this.suit,
    this.notes = '',
    this.imageRef,
    required this.folderId,
  });

  factory PlayingCard.fromMap(Map<String, Object?> m) => PlayingCard(
        id: m['id'] as int?,
        title: m['title'] as String,
        suit: m['suit'] as String,
        notes: (m['notes'] as String?) ?? '',
        imageRef: m['image_ref'] as String?,
        folderId: m['folder_id'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef,
        'folder_id': folderId,
      };
}