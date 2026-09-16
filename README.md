# EcoScan AI — aplicativo Flutter

Base móvel nativa do EcoScan para Android e iOS.

## O que já funciona

- mapa em tela cheia com visual escuro, ruas ou satélite;
- localização do usuário e EcoPontos ordenados por proximidade;
- busca automática quando o mapa é movimentado;
- todos os pontos encontrados continuam no mapa, sem apagar os de áreas anteriores;
- consulta de reciclagem e descarte nos dados do OpenStreetMap;
- abertura da rota no aplicativo de mapas do celular;
- câmera nativa com foco automático, flash e troca de câmera;
- análise básica no próprio aparelho usando ML Kit;
- histórico local de fotos e orientações de descarte;
- interface preparada para receber perfil e uma API própria depois.

## Começar

Leia primeiro o arquivo [GUIA_INSTALACAO.md](GUIA_INSTALACAO.md). Ele explica a instalação do Android Studio, como abrir a base, testar no celular e gerar o APK.

Com o ambiente pronto, os comandos principais são:

```powershell
flutter pub get
flutter run
```

## Pastas principais

```text
lib/
  core/       tema e configurações
  models/     EcoPonto e histórico de análise
  screens/    início, mapa, scanner e histórico
  services/   busca OpenStreetMap e classificação
  state/      estado e armazenamento local
```

## Observações

- Android mínimo desta versão do Flutter: API 24 (Android 7.0).
- iOS mínimo: 15.5, exigido pela integração atual do ML Kit.
- A primeira abertura do mapa e do scanner solicita as permissões necessárias.
- Não há chave paga de mapas nesta base. Os dados vêm do OpenStreetMap.
- O reconhecimento atual é uma orientação inicial; antes de publicar, recomenda-se treinar ou conectar um modelo específico para resíduos brasileiros.
