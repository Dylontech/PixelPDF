import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/app_info.dart';
import 'package:pixel_pvr/core/services/archivos_service.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/widgets/pixel_box.dart';
import 'package:pixel_pvr/core/widgets/pixel_button.dart';
import 'package:pixel_pvr/features/about/presentation/pages/acerca_de_page.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/fuente_documento.dart';
import 'package:pixel_pvr/features/annotate/presentation/pages/anotar_page.dart';
import 'package:provider/provider.dart';

/// Ajustes mínimos: sólo accesos que no viven en el vault. No inventa
/// preferencias que la app todavía no tiene.
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  Future<void> _abrirPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final archivos = context.read<ArchivosService>();

    final archivo = await archivos.elegir(
      extensiones: ['pdf'],
      titulo: 'Elige un PDF para firmar',
    );
    if (archivo == null) return;

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AnotarPage(
          fuente: FuenteDocumento.deBytes(
            nombre: archivo.nombre,
            formato: FormatoEntrada.pdf,
            bytes: archivo.bytes,
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
  }

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
                      'DOCUMENTOS',
                      style: PixelTheme.titulo(
                        size: 11,
                        color: PixelColors.cian,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Firma un PDF que ya tengas en el telefono: elige el '
                      'archivo, anade tu firma o un texto y guarda una copia '
                      'en tu vault.',
                      style: PixelTheme.cuerpo(size: 22),
                    ),
                    const SizedBox(height: 14),
                    PixelButton(
                      label: 'FIRMAR UN PDF',
                      icon: Icons.draw,
                      color: PixelColors.verde,
                      expanded: true,
                      onPressed: () => _abrirPdf(context),
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
            ],
          ),
        ),
      ),
    );
  }
}
