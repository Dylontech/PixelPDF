# Pixel PVR

Escáner de documentos móvil con estética **retro pixel art** (8/16 bits).
Flutter + Clean Architecture + MVVM, con persistencia local en Hive y el
escáner nativo de la plataforma (ML Kit en Android, VisionKit en iOS).

La especificación completa (paleta, tipografías, flujo de pantallas, roadmap)
está en [`PIXEL_PDF_ANOTACIONES.md`](PIXEL_PDF_ANOTACIONES.md).

---

## Estado de este repositorio

| Parte | Estado |
|-------|--------|
| Código de la app (`lib/`, 23 archivos por feature y capa) | ✅ escrito |
| Pruebas (`test/`, 6 archivos) | ✅ escritas |
| Dependencias (`pubspec.yaml`) y fuentes en `assets/fonts/` | ✅ listo |
| Esqueleto de plataformas (`android/`, `ios/`) | ⏳ lo genera `flutter create` |
| Verificación (`analyze`, `test`, `build apk`, `run`) | ⏳ pendiente: **este equipo no tiene el SDK de Flutter** |

El paso que falta se resuelve ejecutando un único script (ver abajo). No se
generó antes porque `flutter create` escribe cientos de archivos dependientes de
la versión del SDK, y este equipo no tiene ninguno instalado.

---

## Requisitos

- **Flutter 3.47.x** (o superior). El tema usa `AppBarThemeData`, disponible
  desde Flutter 3.32; `share_plus` 13 exige además Flutter ≥ 3.38.1 y Dart ≥ 3.10.
- **Java 17+** y **Android SDK** con `platforms;android-36` y `build-tools`
  (necesarios solo para compilar el APK).
- **Dispositivo Android físico** con Google Play Services: el escáner ML Kit no
  funciona de forma fiable en emulador.

> ⚠️ Espacio en disco: el SDK de Flutter más los artefactos de Android, las
> cachés de Gradle y las salidas de build ocupan del orden de **3 GB**. En este
> equipo quedaban 4.2 GB libres (disco al 99 %), así que conviene liberar espacio
> antes de instalar.

---

## Puesta en marcha

```bash
./tool/preparar_proyecto.sh
```

Ese script:

1. Comprueba que Flutter está en el `PATH` (si no, explica cómo instalarlo).
2. Genera `android/` e `ios/` con
   `flutter create --project-name pixel_pvr --org com.dylontech.pixelpvr --platforms=android,ios .`
3. Borra el `test/widget_test.dart` de plantilla (instancia una `MyApp` que en
   este proyecto no existe y rompería `flutter test`).
4. Aplica la configuración de Android e iOS que necesita el proyecto (siguiente
   apartado).
5. Ejecuta `flutter pub get`.

Es **idempotente**: se puede volver a ejecutar sin duplicar nada, y si no
encuentra un patrón esperado avisa en lugar de corromper el archivo.

Después:

```bash
flutter analyze          # debe salir sin errores
flutter test             # 6 archivos de pruebas
flutter build apk --debug
flutter run -d <dispositivo>
```

---

## Configuración de plataformas (lo que aplica el script)

| Plataforma | Cambio | Por qué |
|------------|--------|---------|
| Android | `minSdk = 24` | `cunning_document_scanner` 3.x subió el mínimo a 24 (ML Kit document scanner). El `.md` decía 21 y está desactualizado. |
| Android | `compileSdk = 36` | `image_cropper` 10+ declara `compileSdkVersion 36`; la app no puede ir por detrás. |
| Android | `<uses-permission android:name="android.permission.CAMERA"/>` | El escáner nativo abre la cámara. |
| Android | `UCropActivity` con `android:theme="@style/Ucrop.CropTheme"` | `image_cropper` ≥ 9 requiere declarar la actividad y usar un tema propio (migración de la v9.0.0). |
| Android | `res/values/styles.xml` con `Ucrop.CropTheme` | El estilo que referencia la actividad anterior. |
| Android | `android:label="Pixel PVR"` | Nombre visible de la app. |
| Android | (no aplicado) `values-v35/styles.xml` | `image_cropper` 10 la revirtió: **no debe existir**. |
| iOS | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` | iOS termina el proceso si se pide la cámara sin esta clave. |
| iOS | `CFBundleAllowMixedLocalizations` | Para que el escáner y la hoja de compartir salgan en el idioma del sistema. |
| iOS | `platform :ios, '13.0'` en el `Podfile` | VisionKit y `cunning_document_scanner` lo exigen. |

### Si el script avisa de que no encuentra un patrón

La plantilla de `flutter create` cambia entre versiones de Flutter. Los cambios
son estos y se pueden hacer a mano:

- `android/app/build.gradle.kts`: `minSdk = flutter.minSdkVersion` → `24` y
  `compileSdk = flutter.compileSdkVersion` → `36`.
- `android/app/src/main/AndroidManifest.xml`: añadir el permiso de cámara como
  hijo de `<manifest>` y la actividad `com.yalantis.ucrop.UCropActivity` (con
  `screenOrientation="portrait"` y `theme="@style/Ucrop.CropTheme"`) antes de
  `</application>`.
- `android/app/src/main/res/values/styles.xml`: `<style name="Ucrop.CropTheme"
  parent="Theme.AppCompat.Light.NoActionBar"/>` dentro de `<resources>`.
- `ios/Runner/Info.plist`: las tres claves de la tabla.
- `ios/Podfile`: descomentar `platform :ios, '13.0'`.

**Conflicto de manifest merger**: `cunning_document_scanner` 3.0.3 declara
`android:dataExtractionRules` y `android:fullBackupContent` en su propio
manifest. La plantilla de Flutter no los declara, así que no hay choque; si algún
día añades reglas de backup propias, el build fallará pidiendo
`tools:replace="android:dataExtractionRules,android:fullBackupContent"` en la
etiqueta `<application>`.

---

## Pruebas

```bash
flutter test
```

| Archivo | Qué cubre |
|---------|-----------|
| `test/core/formatters_test.dart` | Fecha, tamaño y nombre automático. |
| `test/features/vault/documento_escaneado_test.dart` | Round-trip `toMap`/`fromMap`, `schemaVersion` y tolerancia a enums desconocidos. |
| `test/features/vault/documento_local_datasource_test.dart` | Hive real sobre un directorio temporal: orden descendente, JSON guardado y borrado. |
| `test/features/export/exportar_documento_test.dart` | Extensión por formato, paso por JPG cuando el destino es PDF, archivo + miniatura + registro. |
| `test/features/editor/editor_viewmodel_test.dart` | Caché de filtros, invalidación al recortar y caminos de error. |
| `test/features/vault/vault_page_test.dart` | Estados vacío / cargando / con datos / error, menú de la tarjeta y borrado. |
| `test/soporte/fakes.dart` | Dobles de repositorio, almacenamiento, procesado, PDF y escáner (no es un test). |

Los tests de widget desactivan la descarga de fuentes
(`GoogleFonts.config.allowRuntimeFetching = false`) porque las dos tipografías
están empaquetadas en `assets/fonts/`. Si `flutter test` se queja de que no
encuentra `PressStart2P-Regular.ttf`, comprueba que
`analysis_options.yaml` no excluya `assets/` y que el bloque `assets:` de
`pubspec.yaml` siga ahí.

---

## Estructura

```
lib/
├── main.dart                     # Hive.initFlutter + openBox + runApp
├── app.dart                      # Composition root (MultiProvider)
├── core/
│   ├── theme/                    # pixel_colors.dart, pixel_theme.dart
│   ├── widgets/                  # pixel_box, pixel_button, pixel_fab, pixel_dialog
│   ├── services/                 # file_storage_service, compartir_service
│   └── utils/formatters.dart
└── features/
    ├── vault/                    # domain (entidad + contrato) / data (Hive) / presentation
    ├── scanner/                  # EscanerService abstracto + implementación nativa
    ├── editor/                   # filtros en isolates + VM + página
    └── export/                   # PdfExportService + caso de uso ExportarDocumento
```

Regla de dependencias: `presentation → domain ← data`. `domain` no importa
Flutter, Hive ni plugins. `app.dart` es el único punto donde los contratos se
enlazan con implementaciones (y por tanto el único sitio a tocar para enchufar
Firebase, como describe la sección 7.4 del `.md`).

`pixel_pdf_codigo_completo.dart`, en la raíz, es el fuente monolítico de
referencia del que se repartió el código; está excluido del análisis en
`analysis_options.yaml` para no duplicar diagnósticos.

---

## Qué falta por verificar

Nada de esto se pudo comprobar en este equipo porque no hay SDK de Flutter:

1. `flutter analyze` / `flutter test` / `flutter build apk --debug`.
2. Ejecución en dispositivo físico. Lista de comprobación manual:
   1. Estado vacío «INSERT COIN»; 2. el FAB abre el escáner; 3. captura con
   detección de bordes; 4. el editor muestra la vista previa; 5. los 5 filtros
   cambian la imagen; 6. volver a un filtro ya usado es instantáneo (caché);
   7. RECORTAR abre uCrop con los colores retro; 8. tras recortar el filtro se
   recalcula; 9. los tres formatos; 10. GUARDAR muestra «LEVEL CLEAR!» con el
   tamaño; 11. COMPARTIR abre la hoja del sistema; 12. al volver, la tarjeta
   muestra miniatura/formato/fecha, BORRAR la elimina y el vault sobrevive al
   cierre de la app.
3. iOS: solo está configurado; compilar requiere macOS.

### Riesgos conocidos al primer build

- **`share_plus`**: si el SDK instalado es anterior a Flutter 3.38.1, `pub get`
  fallará. Alternativa: fijar `share_plus: ^10.1.0` y ajustar
  `lib/core/services/compartir_service.dart`, que es el **único** archivo que usa
  su API (`SharePlus.instance.share` / `Share.shareXFiles`).
- **`hive` / `hive_flutter`** son paquetes antiguos (2022) pero siguen
  resolviendo; si dieran problemas con un SDK muy nuevo, el reemplazo está
  aislado en `documento_local_datasource.dart`.
- **Fuentes**: `google_fonts` busca el `.ttf` dentro de los assets antes de
  intentar la red, así que la app funciona sin conexión desde el primer arranque.

---

## Limitaciones del MVP

Multipágina, renombrado, búsqueda, guardado en galería, B/N adaptativo, OCR y
perspectiva manual con OpenCV quedan fuera de esta entrega. Están listados con su
camino de mejora en la sección 9 de [`PIXEL_PDF_ANOTACIONES.md`](PIXEL_PDF_ANOTACIONES.md).

> Nota: la carpeta se llama `PixelPDF` pero el paquete y la app se llaman
> `pixel_pvr` / «Pixel PVR», como el código y la especificación originales.
