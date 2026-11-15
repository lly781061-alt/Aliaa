name: Build APK
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Generate Android project and keep our code
        run: |
          cp lib/main.dart /tmp/main.dart
          cp lib/store.dart /tmp/store.dart
          cp lib/export.dart /tmp/export.dart
          cp pubspec.yaml /tmp/pubspec.yaml
          flutter create --platforms=android --project-name shop_pro .
          cp /tmp/main.dart lib/main.dart
          cp /tmp/store.dart lib/store.dart
          cp /tmp/export.dart lib/export.dart
          cp /tmp/pubspec.yaml pubspec.yaml
      - name: Download Arabic font for PDF files
        run: |
          mkdir -p assets/fonts
          curl -fL --retry 3 -o assets/fonts/Amiri-Regular.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/amiri/Amiri-Regular.ttf || echo "font download failed"
          curl -fL --retry 3 -o assets/fonts/Amiri-Bold.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/amiri/Amiri-Bold.ttf || echo "font download failed"
          ls -la assets/fonts
      - name: Force compileSdk 36 for all modules
        run: |
          mkdir -p ~/.gradle/init.d
          cat > ~/.gradle/init.d/compilesdk.gradle <<'EOT'
          allprojects {
            afterEvaluate { p ->
              def a = p.extensions.findByName('android')
              if (a != null) { a.compileSdk = 36 }
            }
            tasks.configureEach { t ->
              if (t.name.startsWith('lint')) { t.enabled = false }
            }
          }
          EOT
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: shop-pro-apk
          path: build/app/outputs/flutter-apk/app-release.apk
