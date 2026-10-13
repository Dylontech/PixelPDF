#!/usr/bin/env bash
# =============================================================================
#  Pixel PVR — preparación del proyecto
#
#  Hace las tres cosas que no se pueden dejar "escritas de antemano" porque
#  dependen del SDK de Flutter instalado:
#
#    1. Genera el esqueleto de plataformas (android/, ios/) con `flutter create`.
#    2. Aplica la configuración específica de cada plataforma que necesita el
#       proyecto (ver más abajo el porqué de cada línea).
#    3. Resuelve dependencias.
#
#  Es idempotente: se puede volver a ejecutar sin duplicar nada.
#  Cada cambio comprueba antes si ya estaba aplicado y avisa si no encuentra el
#  patrón esperado en lugar de corromper el archivo.
# =============================================================================
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

NOMBRE_PROYECTO="pixel_pvr"
ORG="com.dylontech.pixelpvr"
ETIQUETA="Pixel PVR"

echo "==> Pixel PVR: preparando proyecto en $RAIZ"

# -----------------------------------------------------------------------------
# 0. ¿Está Flutter?
# -----------------------------------------------------------------------------
if ! command -v flutter >/dev/null 2>&1; then
  cat <<'FIN'
ERROR: no se encuentra el SDK de Flutter en el PATH.

Instálalo (el SDK ocupa ~1.5 GB y las cachés de Gradle otro tanto) y vuelve a
ejecutar este script:

  git clone --depth 1 -b stable https://github.com/flutter/flutter.git ~/development/flutter
  export PATH="$HOME/development/flutter/bin:$PATH"
  flutter doctor --android-licenses

Alternativa con la extensión de VS Code: "Flutter: New Project" descarga el SDK.
FIN
  exit 1
fi

echo "    Flutter: $(flutter --version 2>&1 | head -n 1 || true)"

# -----------------------------------------------------------------------------
# 1. Esqueleto de plataformas
# -----------------------------------------------------------------------------
if [[ ! -d android || ! -d ios ]]; then
  echo "==> Generando android/ e ios/ (flutter create)"
  flutter create \
    --project-name "$NOMBRE_PROYECTO" \
    --org "$ORG" \
    --platforms=android,ios \
    .
else
  echo "==> android/ e ios/ ya existen: no se toca el esqueleto"
fi

# `flutter create` deja un widget_test.dart de plantilla que instancia una app
# "MyApp" que en este proyecto no existe: rompería `flutter test`.
if [[ -f test/widget_test.dart ]]; then
  rm -f test/widget_test.dart
  echo "==> Eliminado test/widget_test.dart (plantilla incompatible)"
fi

# -----------------------------------------------------------------------------
# 2. Utilidades
# -----------------------------------------------------------------------------
aplicar() {
  # aplicar <archivo> <patrón literal> <reemplazo literal> <descripción>
  local archivo="$1" patron="$2" reemplazo="$3" desc="$4"
  if [[ ! -f "$archivo" ]]; then
    echo "    ! falta $archivo -> se omite: $desc"
    return 0
  fi
  if ! grep -qF -- "$patron" "$archivo"; then
    echo "    = ya aplicado o patrón distinto: $desc"
    return 0
  fi
  perl -0pi -e "s{\Q$patron\E}{$reemplazo}" "$archivo"
  echo "    + $desc"
}

insertar_antes() {
  # insertar_antes <archivo> <patrón literal> <texto a insertar> <descripción>
  local archivo="$1" patron="$2" texto="$3" desc="$4"
  if [[ ! -f "$archivo" ]]; then
    echo "    ! falta $archivo -> se omite: $desc"
    return 0
  fi
  if grep -qF -- "$(printf '%s' "$texto" | head -1 | sed 's/^[[:space:]]*//')" "$archivo"; then
    echo "    = ya aplicado: $desc"
    return 0
  fi
  if ! grep -qF -- "$patron" "$archivo"; then
    echo "    ! patrón no encontrado en $(basename "$archivo") -> revisa a mano: $desc"
    return 0
  fi
  perl -0pi -e "s{\Q$patron\E}{$texto\Q$patron\E}" "$archivo"
  echo "    + $desc"
}

# -----------------------------------------------------------------------------
# 3. Android
# -----------------------------------------------------------------------------
if [[ -d android ]]; then
  echo "==> Configurando Android"

  GRADLE="android/app/build.gradle.kts"
  [[ -f "$GRADLE" ]] || GRADLE="android/app/build.gradle"

  if [[ "$GRADLE" == *.kts ]]; then
    # minSdk 24: cunning_document_scanner 3.x lo exige (ML Kit).
    aplicar "$GRADLE" "minSdk = flutter.minSdkVersion" "minSdk = 24" "minSdk 24"
    aplicar "$GRADLE" "minSdkVersion flutter.minSdkVersion" "minSdkVersion 24" "minSdk 24"
    # compileSdk 36: image_cropper 13 lo declara y la app no puede ir por detrás.
    aplicar "$GRADLE" "compileSdk = flutter.compileSdkVersion" "compileSdk = 36" "compileSdk 36"
  else
    aplicar "$GRADLE" "minSdkVersion flutter.minSdkVersion" "minSdkVersion 24" "minSdk 24"
    aplicar "$GRADLE" "compileSdkVersion flutter.compileSdkVersion" "compileSdkVersion 36" "compileSdk 36"
  fi

  MANIFEST="android/app/src/main/AndroidManifest.xml"
  if [[ -f "$MANIFEST" ]]; then
    # Permiso de cámara para el escáner nativo.
    seguir=$'\\n    <uses-permission android:name="android.permission.CAMERA"/>'
    if grep -q 'android.permission.CAMERA' "$MANIFEST"; then
      echo "    = ya aplicado: permiso de cámara"
    else
      perl -0pi -e "s{(<manifest\b[^>]*>)}{\$1$seguir}" "$MANIFEST"
      echo "    + permiso de cámara"
    fi

    # Actividad de uCrop: image_cropper la necesita declarada con este tema.
    if grep -q 'com.yalantis.ucrop.UCropActivity' "$MANIFEST"; then
      echo "    = ya aplicado: UCropActivity"
    else
      # OJO: en el reemplazo de Perl hay que escapar la arroba (\@style). Sin la
      # barra, Perl interpola @style como un array vacío y la borra.
      perl -0pi -e 's{(\n[[:space:]]*</application>)}{\n        <activity\n            android:name="com.yalantis.ucrop.UCropActivity"\n            android:screenOrientation="portrait"\n            android:theme="\@style/Ucrop.CropTheme"/>$1}' "$MANIFEST"
      echo "    + UCropActivity"
    fi

    aplicar "$MANIFEST" 'android:label="'"$NOMBRE_PROYECTO"'"' \
      'android:label="'"$ETIQUETA"'"' "etiqueta visible \"$ETIQUETA\""
  fi

  # Tema que exige uCrop desde image_cropper 9.0.0.
  ESTILOS="android/app/src/main/res/values/styles.xml"
  if [[ -f "$ESTILOS" ]]; then
    insertar_antes "$ESTILOS" "</resources>" \
'    <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar"/>
' "tema Ucrop.CropTheme"
  else
    mkdir -p "$(dirname "$ESTILOS")"
    cat > "$ESTILOS" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- image_cropper (uCrop) exige un tema propio para UCropActivity. -->
    <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar"/>
</resources>
XML
    echo "    + creado res/values/styles.xml con Ucrop.CropTheme"
  fi
fi

# -----------------------------------------------------------------------------
# 4. iOS (solo configuración: compilar requiere macOS)
# -----------------------------------------------------------------------------
if [[ -d ios ]]; then
  echo "==> Configurando iOS (no verificado: hace falta macOS)"

  PLIST="ios/Runner/Info.plist"
  if [[ -f "$PLIST" ]]; then
    if grep -q 'NSCameraUsageDescription' "$PLIST"; then
      echo "    = ya aplicado: claves de Info.plist"
    else
      perl -0pi -e 's{(?:\n?)(</dict>[ \t]*\n</plist>)}{\n\t<key>NSCameraUsageDescription</key>\n\t<string>Pixel PVR necesita la camara para escanear documentos.</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Pixel PVR necesita acceso a tus fotos para importar documentos.</string>\n\t<key>CFBundleAllowMixedLocalizations</key>\n\t<true/>\n$1}' "$PLIST"
      echo "    + NSCameraUsageDescription / NSPhotoLibraryUsageDescription / CFBundleAllowMixedLocalizations"
    fi
  fi

  # VisionKit y el escáner piden iOS 13+.
  aplicar "ios/Podfile" "# platform :ios, '13.0'" "platform :ios, '13.0'" \
    "Podfile con platform :ios, '13.0'"
fi

# -----------------------------------------------------------------------------
# 5. Dependencias
# -----------------------------------------------------------------------------
echo "==> flutter pub get"
flutter pub get

cat <<'FIN'

==> Listo. Siguientes pasos:

  flutter analyze                 # debe salir sin errores
  flutter test                    # pruebas unitarias y de widget
  flutter build apk --debug       # valida manifest, Gradle y plugins nativos
  flutter run -d <dispositivo>    # escáner real: hace falta teléfono físico

Recordatorio: cunning_document_scanner e image_cropper NO soportan Linux ni
Windows, así que `flutter run -d linux` no compila (es esperado).
FIN
