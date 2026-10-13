import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';

import 'pixel_box.dart';

/// Diálogo retro: caja escalonada, título en Press Start 2P y acciones como
/// botones arcade.
Future<void> mostrarPixelDialogo(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required List<Widget> acciones,
  Color colorTitulo = PixelColors.amarillo,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PixelBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: PixelTheme.titulo(size: 12, color: colorTitulo),
            ),
            const SizedBox(height: 12),
            Text(mensaje, style: PixelTheme.cuerpo(size: 20)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: acciones),
          ],
        ),
      ),
    ),
  );
}
