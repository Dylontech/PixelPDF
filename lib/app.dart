import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/compartir_service.dart';
import 'core/services/file_storage_service.dart';
import 'core/theme/pixel_theme.dart';
import 'features/editor/data/services/image_processing_service.dart';
import 'features/export/data/services/pdf_export_service.dart';
import 'features/export/domain/usecases/exportar_documento.dart';
import 'features/scanner/data/services/escaner_service.dart';
import 'features/vault/data/datasources/documento_local_datasource.dart';
import 'features/vault/data/repositories/documento_repository_impl.dart';
import 'features/vault/domain/repositories/documento_repository.dart';
import 'features/vault/presentation/pages/vault_page.dart';
import 'features/vault/presentation/viewmodels/vault_viewmodel.dart';

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

        // ViewModels globales
        ChangeNotifierProvider<VaultViewModel>(
          create: (c) =>
              VaultViewModel(c.read<DocumentoRepository>())..cargar(),
        ),
      ],
      child: MaterialApp(
        title: 'Pixel PVR',
        debugShowCheckedModeBanner: false,
        theme: PixelTheme.build(),
        home: const VaultPage(),
      ),
    );
  }
}
