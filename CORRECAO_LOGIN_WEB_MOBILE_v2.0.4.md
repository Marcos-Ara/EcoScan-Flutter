# Correção do login Google no navegador móvel — v2.0.4

## Sintoma corrigido

No Chrome Android, o botão Google podia abrir uma aba/janela do Google e terminar em tela branca ou `ERR_CACHE_MISS / Confirm Form Resubmission`, mesmo funcionando no desktop.

## Mudança principal

A versão Web não depende mais do `google_sign_in_web` para inicializar o fluxo interativo. O botão Web usa diretamente Google Identity Services por `google_identity_services_web` e habilita `use_fedcm_for_button` quando o navegador oferece suporte.

Com FedCM, Chrome Android moderno usa a interface de autenticação controlada pelo navegador e não precisa depender da mesma troca de popup/aba que causava o problema.

O token Google retornado continua sendo trocado pelo mesmo Firebase Authentication (`accounts:signInWithIdp`), portanto o restante da sessão do EcoScan não mudou.

Android/iOS nativos continuam usando `google_sign_in`.

## Arquivos alterados

- `lib/services/firebase_session.dart`
- `lib/widgets/google_sign_in_action.dart`
- `lib/widgets/google_sign_in_action_stub.dart`
- `lib/widgets/google_sign_in_action_web.dart`
- `lib/widgets/google_sign_in_types.dart` (novo)
- `pubspec.yaml`
- `pubspec.lock`
- `firebase.json`
- `tools/run_web.ps1`

## Teste Web local

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome --web-hostname localhost --web-port 7357 --web-header "Cross-Origin-Opener-Policy=same-origin-allow-popups" --web-header "Referrer-Policy=no-referrer-when-downgrade" --dart-define-from-file=config/mobile.json
```

## Publicar

```powershell
flutter build web --no-wasm-dry-run --dart-define-from-file=config/mobile.json
firebase.cmd deploy --only hosting
```

Depois do deploy, no celular, feche as abas antigas do EcoScan e teste novamente pelo link do Hosting. Se houver uma versão antiga em cache, limpe os dados do site ou use uma aba anônima no primeiro teste.
