import 'package:flutter/material.dart';

Widget build3DGlbViewer() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Image.asset(
        'Imagens/bio_crate_3d.png',
        fit: BoxFit.contain,
        height: 160,
      ),
    ),
  );
}
