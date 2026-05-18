import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomReorderableDelayed extends ReorderableDelayedDragStartListener {
  final Duration delay;

  const CustomReorderableDelayed({
    super.key,
    required this.delay,
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(debugOwner: this, delay: delay);
  }
}
