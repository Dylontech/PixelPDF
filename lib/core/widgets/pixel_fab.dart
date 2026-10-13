import 'package:flutter/material.dart';

import '../theme/pixel_colors.dart';
import 'pixel_box.dart';

/// Botón flotante con forma de botón de consola (ícono de gamepad).
class PixelFab extends StatefulWidget {
  const PixelFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<PixelFab> createState() => _PixelFabState();
}

class _PixelFabState extends State<PixelFab> {
  bool _abajo = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Escanear documento',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _abajo = true),
        onTapUp: (_) => setState(() => _abajo = false),
        onTapCancel: () => setState(() => _abajo = false),
        onTap: widget.onPressed,
        child: Transform.translate(
          offset: _abajo ? const Offset(4, 4) : Offset.zero,
          child: PixelBox(
            color: PixelColors.magenta,
            pixel: 6,
            shadow: _abajo ? 2 : 6,
            padding: EdgeInsets.zero,
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: Icon(
                  Icons.sports_esports,
                  size: 34,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
