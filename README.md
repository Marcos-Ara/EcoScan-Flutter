# EcoScan AI — Flutter

Base Flutter completa para Web, Android e iOS, com autenticação Firebase/Google, scanner, histórico e EcoPontos.

## Estado atual

- Firebase Auth/Hosting alinhados ao projeto `ecoscan-ai-e961f`.
- Google Sign-In Web configurado com o cliente OAuth do mesmo projeto.
- `flutter_map 8.3.2` usado no mapa de EcoPontos com `TileLayer` + `MarkerLayer`.
- Câmera Web suportada pelo pacote `camera`; em Web é necessário HTTPS ou `localhost`.
- ML Kit continua apenas em Android/iOS. No navegador a foto/galeria funciona e o usuário confirma o material manualmente, sem chamar o plugin ML Kit incompatível com Web.
- Histórico Web guarda uma miniatura local; Android/iOS continuam guardando arquivo local.

## Verificar a base antes de rodar

```powershell
.\tools\verify.ps1
```

O script executa `flutter clean`, `flutter pub get`, `flutter analyze` e `flutter test`.

## Rodar no Chrome

A forma recomendada é usar o script incluído:

```powershell
.\tools\run_web.ps1
```

Equivalente a:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --web-header "Cross-Origin-Opener-Policy=same-origin-allow-popups" --dart-define-from-file=config/mobile.json
```

A porta `7357` precisa continuar autorizada no cliente OAuth Web como:

```text
http://localhost:7357
```

## Build Web e Firebase Hosting

```powershell
.\tools\build_web.ps1
firebase.cmd deploy --only hosting
```

O `firebase.json` já envia `Cross-Origin-Opener-Policy: same-origin-allow-popups` em produção para o fluxo de login Google.

## EcoPontos com flutter_map

O mapa usa:

```yaml
flutter_map: ^8.3.2
latlong2: ^0.10.1
```

No Web, a descoberta de EcoPontos evita os mirrors públicos Overpass que estavam retornando `429 Too Many Requests` e `504 Gateway Timeout`. A busca usa uma consulta leve e só atualiza outra área quando o usuário toca em atualizar, evitando rajadas de requisições durante o movimento do mapa.

Em Android/iOS, a busca detalhada por Overpass continua disponível como fallback, agora de forma sequencial e com cache, sem disparar todos os mirrors ao mesmo tempo.

## Scanner

### Android / iOS

- câmera e galeria;
- ML Kit Image Labeling;
- classificação pelo catálogo do EcoScan;
- captura manual e análise automática ao vivo;
- histórico com foto local.

### Web

- câmera e galeria;
- normalização local da foto;
- confirmação manual do material;
- histórico com miniatura local;
- sem chamada ao ML Kit, porque `google_mlkit_image_labeling` não oferece suporte Web.

## Estrutura principal

- `lib/core`: configuração e tema.
- `lib/screens`: telas.
- `lib/services`: Firebase, scanner e busca de EcoPontos.
- `lib/state`: estado local e controlador do mapa.
- `lib/widgets`: componentes reutilizáveis e imagens multiplataforma.
- `config/mobile.json`: configuração local usada com `--dart-define-from-file`.
- `tools/run_web.ps1`: execução Web com host/porta/cabeçalho corretos.
- `tools/build_web.ps1`: build Web.

Consulte também `REVISAO_CONSOLE.md` para as correções aplicadas nesta revisão.
