# EcoScan AI — verificação final v2.0.3+5

Esta revisão consolida o Scanner automático, o login Google/Firebase e o mapa com `flutter_map`.

## Scanner

- Não existe etapa de confirmação manual na interface do Scanner.
- Web: TensorFlow.js + COCO-SSD + MobileNet geram rótulos; o Dart converte os rótulos para material e lixeira.
- Android/iOS: ML Kit continua como classificador nativo.
- Se não houver evidência suficiente, o app não inventa um material: pede outra foto.
- Resultado conhecido mostra objeto detectado, material, confiança e destino/lixeira.

## Mapa

- `flutter_map 8.3.2`.
- OpenStreetMap/CARTO/Esri sem chave obrigatória de tiles.
- No Web, Overpass não é chamado; isso evita os erros recorrentes 429/504 no console.
- A lista de EcoPontos possui um `Material` próprio para não disparar a asserção de `ListTile`/`DecoratedBox`.

## Web / JavaScript

- Integração usa `dart:js_interop`, não `dart:js_util` legado.
- O JavaScript inline de `web/index.html` foi validado sintaticamente com Node.js.
- `ecoscanClassifyImage` é exposta em `window` e consumida pelo bridge Dart.

## Firebase/Google

- Hosting/Auth/Google estão alinhados ao projeto `ecoscan-ai-e961f`.
- `config/mobile.json` é lido via `--dart-define-from-file`.
- O arquivo está ignorado pelo Git para não ser enviado acidentalmente ao repositório.

## Verificações estruturais executadas nesta revisão

- `pubspec.yaml` parseado sem erro.
- JSONs (`mobile.json`, catálogo, manifest, firebase.json, .firebaserc) parseados sem erro.
- Assets/fonts declarados no `pubspec.yaml` existem.
- Imports/exports relativos do diretório `lib/` apontam para arquivos existentes.
- Balanceamento de `()`, `[]` e `{}` dos arquivos Dart verificado.
- Nenhum uso de `dart:js_util`, `dart:html` ou `dart:js` legado em `lib/`.
- Nenhuma mensagem de mapa exigindo chave de API permanece no código de execução.
- Nenhuma interface `Confirme o material` permanece no Scanner.

## Validação final no computador com Flutter

Execute:

```powershell
.\tools\verify.ps1
```

Ou manualmente:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

Teste Web:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json
```
