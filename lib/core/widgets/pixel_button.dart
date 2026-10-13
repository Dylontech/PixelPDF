import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';

import 'pixel_box.dart';

/// Botón tipo arcade: al presionarlo se "hunde" (se mueve y pierde sombra).
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = PixelColors.magenta,
    this.textColor = Colors.black,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final bool expanded;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _abajo = false;

  void _set(bool v) {
    if (widget.onPressed == null) return;
    setState(() => _abajo = v);
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onPressed != null;
    final fondo = habilitado ? widget.color : PixelColors.superficieAlta;
    final texto = habilitado ? widget.textColor : PixelColors.textoSuave;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: Transform.translate(
          offset: _abajo ? const Offset(3, 3) : Offset.zero,
          child: PixelBox(
            color: fondo,
            shadow: _abajo ? 1 : 4,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisSize: widget.expanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: texto),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: PixelTheme.titulo(size: 10, color: texto),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
