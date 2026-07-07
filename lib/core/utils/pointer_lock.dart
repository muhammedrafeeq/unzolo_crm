// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void lockCanvasPointers() {
  if (kIsWeb) {
    try {
      html.document.body?.style.pointerEvents = 'none';
    } catch (e) {
      // safe fallback
    }
  }
}

void unlockCanvasPointers() {
  if (kIsWeb) {
    try {
      html.document.body?.style.pointerEvents = 'auto';
    } catch (e) {
      // safe fallback
    }
  }
}
