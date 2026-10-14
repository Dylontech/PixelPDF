import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/services/archivos_service.dart';
import 'package:pixel_pvr/core/services/compartir_service.dart';
import 'package:pixel_pvr/core/services/enlaces_service.dart';
import 'package:pixel_pvr/core/services/file_storage_service.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/features/annotate/data/services/firma_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/fuente_documento_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/pdf_anotado_service.dart';
import 'package:pixel_pvr/features/annotate/domain/usecases/exportar_documento_anotado.dart';
import 'package:pixel_pvr/features/editor/data/services/image_processing_service.dart';
import 'package:pixel_pvr/features/export/data/services/pdf_export_service.dart';
import 'package:pixel_pvr/features/export/domain/usecases/exportar_documento.dart';
import 'package:pixel_pvr/features/scanner/data/services/escaner_service.dart';
import 'package:pixel_pvr/features/vault/data/datasources/documento_local_datasource.dart';
import 'package:pixel_pvr/features/vault/data/repositories/documento_repository_impl.dart';
import 'package:pixel_pvr/features/vault/domain/repositories/documento_repository.dart';
import 'package:pixel_pvr/features/vault/presentation/pages/vault_page.dart';
import 'package:pixel_pvr/features/vault/presentation/viewmodels/vault_viewmodel.dart';
import 'package:provider/provider.dart';

/// Composition root: el único sitio donde los contratos se enlazan con sus
/// implementaciones. Cambiar documentos locales por Firebase es cambiar las
/// dos líneas del `Provider<DocumentoRepository>`.
class PixelPvrApp extends StatelessWidget {
  const PixelPvrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Infraestructura
        Provider<FileStorageService>(create: (_) => FileStorageService()),
        Provider<ImageProcessingService>(
          create: (_) => ImageProcessingService(),
        ),
        Provider<PdfExportService>(create: (_) => PdfExportService()),
        Provider<EscanerService>(create: (_) => NativoEscanerService()),
        Provider<CompartirService>(create: (_) => const CompartirService()),
        Provider<EnlacesService>(create: (_) => const EnlacesService()),
        Provider<ArchivosService>(create: (_) => const ArchivosService()),

        // Firma y anotaciones
        Provider<FuenteDocumentoService>(
          create: (_) => const FuenteDocumentoService(),
        ),
        Provider<FirmaService>(create: (_) => const FirmaService()),
        Provider<PdfAnotadoService>(create: (_) => const PdfAnotadoService()),

        // Repositorio (punto de extensión para Firebase en el futuro)
        Provider<DocumentoRepository>(
          create: (c) => DocumentoRepositoryImpl(
            DocumentoLocalDataSource(),
            c.read<FileStorageService>(),
          ),
        ),

        // Casos de uso
        Provider<ExportarDocumento>(
          create: (c) => ExportarDocumento(
            repositorio: c.read<DocumentoRepository>(),
            almacenamiento: c.read<FileStorageService>(),
            imagen: c.read<ImageProcessingService>(),
            pdf: c.read<PdfExportService>(),
          ),
        ),
        Provider<ExportarDocumentoAnotado>(
          create: (c) => ExportarDocumentoAnotado(
            repositorio: c.read<DocumentoRepository>(),
            almacenamiento: c.read<FileStorageService>(),
            imagen: c.read<ImageProcessingService>(),
            pdf: c.read<PdfAnotadoService>(),
          ),
        ),

        // ViewModels globales
        ChangeNotifierProvider<VaultViewModel>(
          create: (c) =>
              VaultViewModel(c.read<DocumentoRepository>())..cargar(),
        ),
      ],
      child: MaterialApp(
        title: 'PixelPDF',
        debugShowCheckedModeBanner: false,
        theme: PixelTheme.build(),
        home: const VaultPage(),
      ),
    );
  }
}
