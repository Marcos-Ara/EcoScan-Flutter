# Firebase / Google — configuração atual

Projeto usado por esta base:

```text
EcoScan AI
ecoscan-ai-e961f
```

## Web

A base já está alinhada com:

```text
FIREBASE_PROJECT_ID=ecoscan-ai-e961f
FIREBASE_AUTH_DOMAIN=ecoscan-ai-e961f.firebaseapp.com
GOOGLE_WEB_CLIENT_ID=1403190965-t4i39s47ojq3p1jrolhbenq349tpph45.apps.googleusercontent.com
```

O arquivo local `config/mobile.json` contém os identificadores públicos usados no build. Não coloque `client secret`, conta de serviço ou chave administrativa nesse arquivo.

Origem OAuth usada no desenvolvimento:

```text
http://localhost:7357
```

Domínios Firebase autorizados principais:

```text
localhost
ecoscan-ai-e961f.firebaseapp.com
ecoscan-ai-e961f.web.app
```

## Rodar

```powershell
.\tools\run_web.ps1
```

ou:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --web-header "Cross-Origin-Opener-Policy=same-origin-allow-popups" --dart-define-from-file=config/mobile.json
```

## Android

Para o Google Sign-In nativo, registre `br.com.ecoscan.ecoscan_mobile` no mesmo projeto Firebase e adicione SHA-1/SHA-256 das assinaturas usadas. O ID OAuth Web acima é usado como `serverClientId`.

## iOS

Registre o bundle ID do Runner no mesmo projeto, preencha `GOOGLE_IOS_CLIENT_ID` e configure o `REVERSED_CLIENT_ID` no `Info.plist`. A compilação iOS exige Mac/Xcode.

## Segurança

A API key Web do Firebase e o OAuth Client ID são identificadores de cliente e aparecem no app. Isso não substitui regras de segurança. Nunca inclua:

- client secret OAuth;
- service account JSON;
- chave administrativa;
- senha pessoal.
