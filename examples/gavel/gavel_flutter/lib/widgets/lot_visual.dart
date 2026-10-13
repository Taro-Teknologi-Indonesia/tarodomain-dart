import 'package:flutter/material.dart';

/// A lot's emoji on its color: the visual when there is no photo, or when
/// the photo fails to load.
class TileVisual extends StatelessWidget {
  const TileVisual({required this.emoji, required this.color, super.key});

  final String emoji;

  /// `#RRGGBB`.
  final String color;

  /// [hex] (`#RRGGBB`) as an opaque color, grey if it doesn't parse.
  static Color parse(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value == null ? Colors.grey : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: parse(color),
    child: Center(
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: FittedBox(child: Text(emoji)),
      ),
    ),
  );
}

/// A lot's photo, falling back to its [TileVisual] when there is none or it
/// fails to load.
class LotVisual extends StatelessWidget {
  const LotVisual({
    required this.imageUrl,
    required this.emoji,
    required this.color,
    super.key,
  });

  final String? imageUrl;
  final String emoji;
  final String color;

  @override
  Widget build(BuildContext context) {
    final tile = TileVisual(emoji: emoji, color: color);
    final url = imageUrl;
    if (url == null || url.isEmpty) return tile;
    return Image.network(
      url,
      key: ValueKey(url),
      fit: BoxFit.cover,
      // Photos hosted without CORS headers still show, through an <img>.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => tile,
      loadingBuilder: (_, child, progress) => progress == null ? child : tile,
    );
  }
}
