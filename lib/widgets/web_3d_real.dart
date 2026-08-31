// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _isRegistered = false;

Widget build3DGlbViewer() {
  if (!_isRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      'kinetix-3d-glb-view',
      (int viewId) {
        final elem = html.Element.tag('kinetix-3d-viewer');
        elem.style.width = '100%';
        elem.style.height = '100%';
        elem.style.border = 'none';
        return elem;
      },
    );
    _isRegistered = true;
  }
  return const SizedBox(
    height: 180,
    width: double.infinity,
    child: HtmlElementView(viewType: 'kinetix-3d-glb-view'),
  );
}
