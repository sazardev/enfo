import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'music_catalog.dart';

/// Cover art for the media session: a simple gradient per song, drawn once
/// and cached as a PNG whose `file://` URI goes into the [MediaItem].
class MusicArt {
  const MusicArt._();

  static final Map<String, Uri> _cache = {};

  static Future<Uri?> uriFor(MusicTrack track) async {
    final cached = _cache[track.asset];
    if (cached != null) return cached;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/enfo_cover_${track.asset.hashCode.toUnsigned(32)}.png',
      );
      if (!await file.exists()) {
        await file.writeAsBytes(await _render(track), flush: true);
      }
      final uri = Uri.file(file.path);
      _cache[track.asset] = uri;
      return uri;
    } catch (_) {
      // No artwork is fine: the notification falls back to the icon.
      return null;
    }
  }

  static Future<Uint8List> _render(MusicTrack track) async {
    const size = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, size, size);
    final colors = _palette(track);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          colors,
        ),
    );
    canvas.drawCircle(
      Offset(size * 0.78, size * 0.24),
      size * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      Offset(size * 0.18, size * 0.86),
      size * 0.38,
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    final title = TextPainter(
      text: TextSpan(
        text: track.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: size - 96);
    title.paint(
      canvas,
      Offset((size - title.width) / 2, size - title.height - 96),
    );

    final artist = TextPainter(
      text: TextSpan(
        text: track.artist,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 30,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size - 96);
    artist.paint(
      canvas,
      Offset((size - artist.width) / 2, size - artist.height - 44),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return data!.buffer.asUint8List();
  }

  static List<Color> _palette(MusicTrack track) {
    final hue = (track.title.hashCode.abs() % 360).toDouble();
    return [
      HSLColor.fromAHSL(1, hue, 0.55, 0.42).toColor(),
      HSLColor.fromAHSL(1, (hue + 42) % 360, 0.60, 0.22).toColor(),
    ];
  }
}
