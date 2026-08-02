import 'package:flutter/material.dart';

/// A quick fade + gentle scale transition.
///
/// Compared to the platform-default slide transition this is noticeably
/// snappier (shorter duration, simpler compositing = fewer dropped frames)
/// while still feeling polished, which is why it's used for every push in
/// the app instead of the default [MaterialPageRoute].
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute({required Widget page, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Shorthand: `Navigator.of(context).push(fadeScaleRoute(const NextScreen()))`.
Route<T> fadeScaleRoute<T>(Widget page) => FadeScaleRoute<T>(page: page);
