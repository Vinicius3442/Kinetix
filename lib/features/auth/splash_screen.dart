import 'package:flutter/material.dart';

import '../../core/widgets/kx_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: KxBackground(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              KxLogo(height: 56),
              SizedBox(height: 28),
              SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ]),
          ),
        ),
      );
}
