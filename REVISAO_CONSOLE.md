# Revisão de console e mapa — 17/09/2026

## Corrigido / tratado na base

### Flutter Web viewport

Foi removida a tag `viewport` manual de `web/index.html`. O Flutter Web controla essa configuração e antes emitia o aviso de substituição da tag.

### Google Sign-In

- inicialização protegida por um único `Future`, evitando chamadas concorrentes a `GoogleSignIn.initialize()`;
- cliente OAuth Web colocado na meta tag oficial `google-signin-client_id`;
- no Web, `initialize()` deixa o plugin ler o ID dessa meta tag;
- Firebase Auth, API key, project ID e auth domain agora apontam ao mesmo projeto `ecoscan-ai-e961f`;
- Firebase Hosting envia `Cross-Origin-Opener-Policy: same-origin-allow-popups`;
- o script `tools/run_web.ps1` envia o mesmo cabeçalho no servidor local.

### EcoPontos / console 429 e 504

O mapa já usava `flutter_map`; a integração foi mantida na versão 8.3.2.

Os erros vinham da camada de descoberta de POIs, não do `flutter_map`: os mirrors Overpass eram consultados em paralelo e alguns respondiam 429/504. Nesta revisão:

- o Web não chama Overpass;
- busca automática a cada movimento do mapa foi removida no Web;
- o usuário move o mapa e toca em atualizar para a nova área;
- resultados têm cache curto;
- Android/iOS consultam mirrors Overpass sequencialmente e param quando encontram resultado.

### Scanner Web

`google_mlkit_image_labeling` é Android/iOS. A base antiga podia chegar ao MethodChannel do ML Kit no navegador. Agora:

- o Web não instancia/chama o labeler;
- câmera e galeria continuam funcionando;
- a foto é normalizada localmente;
- o usuário confirma o material manualmente;
- foco/exposição/flash nativos não são chamados no navegador;
- a foto do histórico Web é salva como miniatura local em data URL.

### Imagens locais no Web

Histórico, avatar e foto do perfil agora aceitam data URL / URL Web, evitando operações de arquivo nativas quando a aplicação está no navegador.

## Verificação local recomendada

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
.\tools\run_web.ps1
```

Depois teste:

1. login com Google;
2. câmera (permissão do site habilitada);
3. galeria;
4. confirmação manual de material no Web;
5. abrir Mapa, mover e usar o botão atualizar;
6. abrir DevTools e confirmar que não existem chamadas Web para `overpass-api.de`;
7. gerar build e publicar no Firebase Hosting.

## Observação sobre DevTools

Logs informativos do próprio Google Identity Services (`GSI_LOGGER`) podem aparecer em modo debug. O foco desta revisão é remover inicializações duplicadas e falhas de rede/aplicação. Em release, o volume de logs de debug é menor.
