# Correção do login Google — Web + Android/iOS

## O bloqueio encontrado

Havia dois bloqueios independentes no código:

1. `FirebaseSession.signInGoogle()` recusava o login imediatamente quando `GOOGLE_WEB_CLIENT_ID` estava vazio. Por isso a tela mostrava a mensagem dizendo que o Google ainda precisava ser configurado.
2. Mesmo com o ID preenchido, a versão Web chamava `GoogleSignIn.instance.authenticate()`. No `google_sign_in` 7.x isso não é suportado no Web. O Web precisa usar o botão oficial do Google Identity Services (`google_sign_in_web.renderButton`) e receber o resultado por `authenticationEvents`.

A base foi alterada para:

- usar o botão GIS oficial apenas no Web;
- manter o botão original no Android/iOS;
- inicializar Google uma única vez;
- trocar o ID token Google por uma sessão Firebase pela API REST já usada pelo projeto;
- usar `Uri.base.origin` como `requestUri` no Web;
- mostrar erro de configuração sem bloquear silenciosamente;
- evitar `dart:io Platform.isIOS` dentro do serviço de autenticação Web;
- restaurar a pasta `web/`, ausente no ZIP recebido.

## Um dado externo continua obrigatório

O código recebido NÃO contém um OAuth Client ID do tipo **Web application**. Esse identificador é público, mas não pode ser inventado. Obtenha-o no mesmo projeto Google/Firebase usado pelo Firebase Authentication.

Preencha `config/mobile.json` (copie de `config/mobile.example.json`) com pelo menos:

```json
{
  "GOOGLE_WEB_CLIENT_ID": "SEU_ID.apps.googleusercontent.com"
}
```

Compile com:

```powershell
flutter pub get
flutter build web --dart-define-from-file=config/mobile.json
firebase.cmd deploy --only hosting
```

Para desenvolvimento local com Google Web, use uma porta fixa e cadastre essa origem no cliente OAuth:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json
```

Origem local a autorizar no cliente OAuth Web: `http://localhost:7357`.

## Atenção: Hosting e Authentication estão apontando para projetos diferentes

No ZIP recebido:

- `.firebaserc` / Firebase Hosting: `ecoscan-ai-e961f`
- `lib/core/backend_config.dart` / Firebase Authentication REST (padrão): `ecoscan-b8b02`

Isso pode ser proposital para manter as contas do projeto antigo. Se NÃO for proposital, compile passando também `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID` e `FIREBASE_AUTH_DOMAIN` do projeto correto (adicione esses campos ao seu `config/mobile.json`). Não troque apenas o domínio: a API key e o projeto de autenticação precisam corresponder.

Se o Auth continuar em `ecoscan-b8b02`, autorize no Firebase Authentication DESSE projeto o domínio onde o app está hospedado, por exemplo `ecoscan-ai-e961f.web.app`. As origens JavaScript também devem ser cadastradas no cliente OAuth Web que pertence ao mesmo projeto do Auth.

## Android

Sem `google-services.json`, a base continua usando `GOOGLE_WEB_CLIENT_ID` como `serverClientId`, que é um fluxo suportado pelo plugin. Ainda é obrigatório cadastrar o package `br.com.ecoscan.ecoscan_mobile` e os SHA-1/SHA-256 correspondentes à assinatura usada.

## Observações de Web fora do login

A autenticação foi corrigida sem remover recursos. Algumas telas do projeto usam APIs nativas (`dart:io`, arquivos locais e ML Kit). O login Web pode funcionar, mas scanner/histórico/foto podem exigir adaptação separada para uma experiência Web completa. O pacote `google_mlkit_image_labeling` não oferece implementação Web.
