# EcoScan AI 2.3.0 — Visitante + Mapa + Scanner

## Modo visitante

- A tela de login agora oferece **Continuar sem conta**.
- O modo visitante não cria usuário no Supabase e não chama autenticação anônima remota.
- O histórico do visitante usa o namespace local `guest-local`, separado das contas reais.
- Ao sair do modo visitante, o app volta para o login normalmente.
- Login por e-mail e Google continuam usando Supabase Auth sem alterações no fluxo OAuth já validado.

## Scanner

### Web

- O modo ao vivo mantém COCO-SSD `lite_mobilenet_v2` para reduzir latência.
- Fotos/galeria usam COCO-SSD `mobilenet_v2`, que prioriza precisão.
- Depois da detecção, a classificação MobileNet v2 é executada no recorte do objeto, com margem para preservar bordas.
- Se o recorte estiver fraco, a foto inteira é usada como segunda evidência.
- O classificador preserva as pontuações reais dos modelos; não aumenta confiança artificialmente.
- Conflitos entre `tv` e evidências de `cell phone`/`cellular telephone` são resolvidos conservadoramente.
- Uma caixa extremamente vertical rotulada como TV pode ser rejeitada como inconsistente em vez de ser exibida como televisão com falsa certeza.

### Android/iOS

- ML Kit Object Detection localiza primeiro o objeto mais proeminente em `DetectionMode.single`.
- ML Kit Image Labeling classifica o recorte do objeto.
- A imagem completa é usada apenas como fallback quando o recorte não produz evidência suficiente.
- O detector e o classificador rodam no aparelho, sem Firebase.

## EcoPontos e mapa

- Os estilos `Ruas` e `Escuro` usam **OpenFreeMap** com vector tiles, sem API key.
- Foi removido o basemap CARTO que passou a exibir `API KEY REQUIRED`.
- Satélite continua disponível via Esri World Imagery.
- A busca de EcoPontos foi separada do basemap: se a fonte de pontos estiver temporariamente fora do ar, o mapa continua funcionando.
- Overpass usa consultas menores, sequenciais e com raio limitado, reduzindo `504` e carga nos servidores públicos.
- Quando Overpass falha ou não retorna pontos, o app tenta uma busca Nominatim limitada à área visível.
- Resultados ficam em cache por 60 minutos e os pontos já carregados não são apagados por uma falha temporária.
- Arrastar o mapa não dispara consultas continuamente: toque em atualizar para buscar na nova área.

## Versão

`2.3.0+13`

## Verificação local recomendada

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json
```
