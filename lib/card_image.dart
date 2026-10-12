import 'package:flutter/material.dart';
import 'playing_card.dart';

/// Shows the image if it loads; otherwise a stable suit-symbol placeholder.
/// Never throws and never depends on the network for tests.
class CardImage extends StatelessWidget {
  final String? imageRef;
  final String suit;
  final double size;
  const CardImage({super.key, required this.imageRef, required this.suit, this.size = 48});

  Widget _placeholder() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        child: Text(kSuits[suit] ?? '?', style: TextStyle(fontSize: size * 0.6)),
      );

  @override
  Widget build(BuildContext context) {
    final ref = imageRef?.trim();
    if (ref == null || ref.isEmpty) return _placeholder();

    if (ref.startsWith('assets/')) {
      return Image.asset(ref, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    final uri = Uri.tryParse(ref);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(ref, width: size, height: size, fit: BoxFit.cover,
          loadingBuilder: (c, child, p) => p == null ? child : _placeholder(),
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder(); // malformed reference: keep it stored, just don't render
  }
}