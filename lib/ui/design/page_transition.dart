import 'package:flutter/material.dart';

import 'motion.dart';

/// App-wide page transition: fade + gentle scale-in, transitioning the
/// actual incoming page directly.
///
/// Deliberately NOT using `animations` package's FadeThrough/SharedAxis
/// builders (or Flutter's own page-transition-theme builders that rely on
/// them): those cross-fade through a solid `Theme.of(context).canvasColor`
/// filled box between the outgoing and incoming page. Against a vivid,
/// user-chosen accent theme, that neutral fill box reads as an ugly white/
/// flat flash. This transition never inserts an intermediate solid box.
Route<T> appPageRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.medium,
    reverseTransitionDuration: Motion.medium,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.gentle);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
