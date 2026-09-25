# EcoScan AI — Flutter + Supabase 2.3.0

EcoScan AI identifica objetos/resíduos por câmera ou foto, orienta o descarte e mostra EcoPontos próximos.

## O que mudou na 2.3.0

- **Modo visitante:** botão `Continuar sem conta`, sem criar usuário no Supabase.
- **Scanner orientado ao objeto:** primeiro localiza o objeto, depois classifica o recorte para reduzir interferência do fundo.
- **Web:** COCO-SSD `mobilenet_v2` em fotos + MobileNet v2 no recorte; o modo ao vivo mantém o modelo leve.
- **Android/iOS:** ML Kit Object Detection + Image Labeling no recorte do objeto.
- **Conflitos celular/TV:** evidência específica de telefone vence rótulos genéricos conflitantes; resultados incoerentes podem virar inconclusivos em vez de exibir um nome errado.
- **Mapa sem API key:** OpenFreeMap + `flutter_map_vector_tiles` nos estilos Ruas/Escuro.
- **EcoPontos mais resilientes:** Overpass com consulta pequena/fallback sequencial + Nominatim limitado à área + cache de 60 minutos.

Consulte `ATUALIZACAO_2.3.0.md` para os detalhes.

## Backend único

A aplicação usa **Supabase** para autenticação e banco de conhecimento.

- E-mail/senha: Supabase Auth.
- Google: Supabase OAuth (`OAuthProvider.google`).
- Sessão: `supabase_flutter` + `onAuthStateChange`.
- Banco de resíduos: RPC `find_ecoscan_object(p_alias text)` como refinamento quando o catálogo local não resolve.
- Catálogo rápido/offline: `assets/data/catalog.json`.
- Firebase Auth/SDK e `google_sign_in` não são usados.
- O modo visitante é **local** e não cria uma sessão anônima remota.

## Scanner

- `lib/services/scan_service.dart`: pipeline Android/iOS e coordenação Web.
- `web/scanner.js`: TensorFlow.js no navegador.
- `lib/services/waste_classifier.dart`: regras de resolução, confiança e descarte.
- `lib/services/material_catalog.dart`: catálogo local/offline.
- `lib/services/supabase_material_resolver.dart`: enriquecimento pelo Supabase quando necessário.

O app prefere responder **inconclusivo** quando a evidência é contraditória em vez de fabricar uma classificação/confiança.

## EcoPontos

- `lib/screens/map_screen.dart`: OpenFreeMap/Esri e interface do mapa.
- `lib/services/eco_point_service.dart`: Overpass/Nominatim/cache.
- `lib/state/eco_point_controller.dart`: localização, filtros e controle das pesquisas.

Os servidores públicos de pesquisa de lugares podem oscilar. Uma falha na busca de EcoPontos não derruba mais o basemap nem remove pontos já carregados.

## Google Login

No Google Cloud, o redirect autorizado deve ser exatamente:

`https://tekyqhtodsbeqbrvdtqs.supabase.co/auth/v1/callback`

No Supabase, durante desenvolvimento Web, mantenha `http://localhost:7357` em Authentication > URL Configuration > Redirect URLs.

Veja `SUPABASE_SETUP.md`.

## Configuração pública

`config/mobile.json` contém apenas configuração pública do cliente:

- `SUPABASE_URL`
- `SUPABASE_PUBLIC_KEY`
- `SUPABASE_MOBILE_REDIRECT`

Nunca coloque uma `service_role` no Flutter.

## Verificar a base

Abra no VS Code a pasta em que `pubspec.yaml` está na raiz e execute:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

## Rodar Web

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json
```

## Build Web release

```powershell
flutter build web --release --dart-define-from-file=config/mobile.json
```

## Gerar APK de teste

```powershell
flutter build apk --debug --dart-define-from-file=config/mobile.json
```

APK:

`build\app\outputs\flutter-apk\app-debug.apk`
