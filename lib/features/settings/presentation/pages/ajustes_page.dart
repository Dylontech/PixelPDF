import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/app_info.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/widgets/pixel_box.dart';
import 'package:pixel_pvr/core/widgets/pixel_button.dart';
import 'package:pixel_pvr/features/about/presentation/pages/acerca_de_page.dart';

/// Ajustes: por ahora sólo información. Queda reservado para opciones de
/// configuración futuras, así que no inventa preferencias que la app todavía
/// no tiene. La firma de PDFs vive en el menú de la cabecera del vault.
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AJUSTES')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PixelBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INFORMACION',
                      style: PixelTheme.titulo(
                        size: 11,
                        color: PixelColors.amarillo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${AppInfo.nombre} v${AppInfo.version}',
                      style: PixelTheme.cuerpo(size: 22),
                    ),
                    const SizedBox(height: 14),
                    PixelButton(
                      label: 'ACERCA DE',
                      icon: Icons.info_outline,
                      color: PixelColors.magenta,
                      expanded: true,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AcercaDePage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PixelBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROXIMAMENTE',
                      style: PixelTheme.titulo(
                        size: 11,
                        color: PixelColors.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Este espacio queda reservado para opciones de '
                      'configuracion futuras.',
                      style: PixelTheme.cuerpo(size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Para firmar un PDF o anadir texto, usa el menu de la '
                      'cabecera del vault.',
                      style: PixelTheme.cuerpo(
                        size: 20,
                        color: PixelColors.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
