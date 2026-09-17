# Checklist de verificação da revisão — 17/09/2026

## Inspeção aplicada

- dependência `flutter_map` confirmada em `8.3.2` no lockfile;
- dependência `camera` confirmada em `0.12.1`;
- dependência `google_sign_in` confirmada em `7.2.0`;
- Firebase Auth/Hosting e Google OAuth alinhados ao projeto `ecoscan-ai-e961f`;
- chamadas Overpass removidas do caminho Web;
- inicialização Google serializada;
- viewport duplicado removido;
- scanner Web impedido de chamar ML Kit nativo;
- histórico/avatar adaptados para imagens Web;
- erro de parâmetro duplicado no botão Galeria do scanner removido.

## Comandos para validação no PC com Flutter

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-hostname localhost --web-port 7357 --web-header "Cross-Origin-Opener-Policy=same-origin-allow-popups" --dart-define-from-file=config/mobile.json
```

## Build de produção

```powershell
flutter build web --dart-define-from-file=config/mobile.json
firebase.cmd deploy --only hosting
```

## Limitações conhecidas por plataforma

- ML Kit Image Labeling: Android/iOS, não Web.
- câmera Web: exige contexto seguro (HTTPS ou localhost) e permissão do navegador.
- EcoPontos dependem de dados públicos do OpenStreetMap; disponibilidade dos pontos varia por região.
- iOS precisa de Mac/Xcode para compilação e teste físico.

Esta revisão foi feita sobre a base enviada em 17/09/2026. Execute os comandos acima no ambiente Flutter local antes do deploy final.
