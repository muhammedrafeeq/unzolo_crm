// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void lockCanvasPointers() {
  try {
    html.document.body?.style.pointerEvents = 'none';
  } catch (_) {}
}

void unlockCanvasPointers() {
  try {
    html.document.body?.style.pointerEvents = 'auto';
  } catch (_) {}
}
