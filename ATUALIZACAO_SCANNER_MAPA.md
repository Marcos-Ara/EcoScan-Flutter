# EcoScan — atualização Scanner + EcoPontos

## O que foi corrigido

- O mapa abre por padrão com OpenStreetMap, sem chave de API.
- O estilo escuro usa CARTO sem chave e o satélite usa Esri.
- O `ListTile background color or ink splashes may be invisible` foi corrigido com um `Material` próprio no painel de EcoPontos.
- Web Scanner agora usa TensorFlow.js no navegador (COCO-SSD + MobileNet) e não depende de chave de API.
- Android/iOS continuam usando Google ML Kit nativo.
- Google Sign-In Web é inicializado uma única vez.
- Versão incrementada para `2.0.1+3` para facilitar atualização Android.

## Testar Web

```powershell
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json
```

Na primeira análise Web os modelos de IA são baixados, então o primeiro scan pode demorar alguns segundos.

## Publicar Web

```powershell
flutter build web --no-wasm-dry-run --dart-define-from-file=config/mobile.json
firebase.cmd deploy --only hosting
```

## Atualizar o app Android instalado

Conecte o celular com Depuração USB e confirme:

```powershell
flutter devices
```

Depois execute (substitua o ID):

```powershell
flutter run -d ID_DO_CELULAR --dart-define-from-file=config/mobile.json
```

Para gerar APK:

```powershell
flutter build apk --release --dart-define-from-file=config/mobile.json
```

APK gerado em `build\app\outputs\flutter-apk\app-release.apk`.

> O projeto ainda usa a chave de debug para builds release. Se o app antigo foi instalado a partir de outro PC, a assinatura pode ser diferente. Nesse caso o Android não permite atualizar por cima: desinstale a versão antiga uma vez ou configure uma chave de assinatura release fixa para os próximos builds.
