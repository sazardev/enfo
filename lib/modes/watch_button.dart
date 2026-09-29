import 'package:flutter/material.dart';

/// A FilledButton trimmed to fit a watch's narrow control row (the theme's
/// generous pill padding doesn't).
final ButtonStyle watchButtonStyle = FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
);
