# Verificação da base 2.3.0

## Verificado neste ambiente

- `web/scanner.js`: sintaxe JavaScript válida (`node --check`).
- Testes Node do scanner/integrações estáticas: **11/11 passaram**.
- Imports relativos Dart: nenhum arquivo interno ausente.
- Imports `package:ecoscan_mobile/...`: nenhum arquivo interno ausente.
- `config/mobile.json`, `assets/data/catalog.json` e `web/manifest.json`: JSON válido.
- `pubspec.yaml`: YAML válido.
- Assets declarados no `pubspec.yaml`: presentes.
- Google OAuth: apenas uma chamada `signInWithOAuth()` no runtime.
- Firebase Auth/SDK: nenhuma referência de runtime.
- CARTO `basemaps.cartocdn.com`: removido do runtime.
- `tile.openstreetmap.org`: não usado diretamente como basemap do runtime.
- OpenFreeMap: configurado nos estilos Ruas/Escuro.
- Arquivos `.bak`: removidos.

## Testes incluídos

Os testes Web cobrem, entre outros:

- não carregar modelos de IA antes de abrir o scanner;
- evitar fila de inferências simultâneas no modo ao vivo;
- priorizar celular central sobre objeto de fundo;
- não exibir `tv` para foto vertical de smartphone quando existe evidência de telefone;
- rejeitar uma caixa extremamente vertical como TV quando a evidência é inconsistente;
- preservar a confiança medida pelo modelo;
- confirmar que o basemap CARTO com API key foi removido;
- confirmar a presença do modo visitante e do controlador do mapa.

## Verificação que precisa rodar no PC com Flutter

Este ambiente não possui Flutter/Dart SDK, por isso `flutter analyze` e `flutter test` não foram executados aqui.
No PC com Flutter 3.47.4 / Dart 3.13.3, execute:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

Depois teste Web:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json
```
