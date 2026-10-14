import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/app_info.dart';
import 'package:pixel_pvr/core/pixel_assets.dart';
import 'package:pixel_pvr/core/services/enlaces_service.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/widgets/pixel_box.dart';
import 'package:pixel_pvr/core/widgets/pixel_button.dart';
import 'package:provider/provider.dart';

/// Pantalla informativa: qué es la app, cómo se hizo, funciones, enlaces a
/// Todo PDF / DylonTech y agradecimientos.
class AcercaDePage extends StatelessWidget {
  const AcercaDePage({super.key});

  Future<void> _abrir(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final enlaces = context.read<EnlacesService>();

    final abierto = await enlaces.abrir(url);
    if (!abierto) {
      messenger.showSnackBar(
        const SnackBar(content: Text('NO SE PUDO ABRIR EL ENLACE')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ACERCA DE')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PixelBox(
                child: Column(
                  children: [
                    Image.asset(
                      PixelAssets.logo,
                      width: 96,
                      height: 96,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppInfo.nombre.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: PixelTheme.titulo(
                        size: 16,
                        color: PixelColors.cian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'v${AppInfo.version}',
                      style: PixelTheme.cuerpo(
                        size: 20,
                        color: PixelColors.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _Seccion(
                titulo: 'QUE ES',
                color: PixelColors.magenta,
                parrafos: [
                  'PixelPDF es un escaner de documentos con estetica retro '
                      'pixel art: pasa una hoja por la camara, ajusta la imagen '
                      'y guardala en tu vault.',
                  'Puedes exportar a PDF, JPG o PNG, y ahora tambien firmar tus '
                      'PDFs y escribir sobre ellos con cuadros de texto.',
                ],
              ),
              const SizedBox(height: 16),
              const _Seccion(
                titulo: 'CREADA CON IA',
                color: PixelColors.amarillo,
                parrafos: [
                  'Esta aplicacion fue creada con asistencia de inteligencia '
                      'artificial (GitHub Copilot) como parte de un proyecto de '
                      'DylonTech.',
                  'El diseno, el codigo y los textos se revisaron y ajustaron a '
                      'mano antes de publicarse.',
                ],
              ),
              const SizedBox(height: 16),
              const _Seccion(
                titulo: 'FUNCIONES',
                color: PixelColors.cian,
                vineta: [
                  'Escaner con la camara del telefono',
                  'Filtros retro: color, grises, blanco y negro y pixel art',
                  'Recorte manual y zoom en el editor',
                  'Vault local: tus documentos no salen del dispositivo',
                  'Exportacion a PDF, JPG y PNG',
                  'Firmar PDFs con el dedo o con una imagen de firma',
                  'Cuadros de texto sobre cualquier PDF o imagen',
                  'Compartir el documento exportado',
                ],
              ),
              const SizedBox(height: 16),
              _BloqueEnlaces(onAbrir: (url) => _abrir(context, url)),
              const SizedBox(height: 16),
              const _Seccion(
                titulo: 'AGRADECIMIENTOS',
                color: PixelColors.verde,
                parrafos: [
                  'Gracias a la comunidad de Flutter y a los paquetes de codigo '
                      'abierto que hacen esto posible: cunning_document_scanner, '
                      'image_cropper, image, pdf, printing, hive, share_plus, '
                      'google_fonts, file_picker y url_launcher.',
                  'Y gracias a las personas que usan la app, proponen ideas y '
                      'reportan fallos.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.color,
    this.parrafos = const [],
    this.vineta = const [],
  });

  final String titulo;
  final Color color;
  final List<String> parrafos;
  final List<String> vineta;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: PixelTheme.titulo(size: 11, color: color)),
          const SizedBox(height: 10),
          for (final parrafo in parrafos) ...[
            Text(parrafo, style: PixelTheme.cuerpo(size: 22)),
            const SizedBox(height: 8),
          ],
          for (final punto in vineta) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('> ', style: PixelTheme.cuerpo(size: 22, color: color)),
                Expanded(
                  child: Text(punto, style: PixelTheme.cuerpo(size: 22)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _BloqueEnlaces extends StatelessWidget {
  const _BloqueEnlaces({required this.onAbrir});

  final ValueChanged<String> onAbrir;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODO PDF Y DYLONTECH',
            style: PixelTheme.titulo(size: 11, color: PixelColors.amarillo),
          ),
          const SizedBox(height: 10),
          Text(
            'Si quieres editar tus PDFs u otros archivos desde el navegador, '
            'visita los sitios de DylonTech:',
            style: PixelTheme.cuerpo(size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            AppInfo.urlTodoPdf,
            style: PixelTheme.cuerpo(size: 20, color: PixelColors.cian),
          ),
          Text(
            AppInfo.urlDylontech,
            style: PixelTheme.cuerpo(size: 20, color: PixelColors.cian),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PixelButton(
                label: 'TODO PDF',
                icon: Icons.open_in_new,
                color: PixelColors.magenta,
                onPressed: () => onAbrir(AppInfo.urlTodoPdf),
              ),
              PixelButton(
                label: 'DYLONTECH',
                icon: Icons.open_in_new,
                color: PixelColors.cian,
                onPressed: () => onAbrir(AppInfo.urlDylontech),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
