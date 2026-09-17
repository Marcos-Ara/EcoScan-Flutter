# Scanner automático EcoScan

O scanner não pede mais que o usuário confirme o material.

Fluxo atual:

1. câmera ou galeria captura a imagem;
2. Web: TensorFlow.js (COCO-SSD + MobileNet) identifica o objeto;
3. Android/iOS: ML Kit identifica os rótulos;
4. o catálogo local e o WasteClassifier resolvem objeto -> material -> lixeira;
5. o app mostra automaticamente Objeto, Material, Confiança e Destino;
6. se a IA realmente não tiver evidência suficiente, o app pede outra foto em vez de inventar um material.

Não há API key para a IA do scanner Web.

## v2.0.2+4

- removida a escolha manual de material da tela Scanner;
- resultado mostra objeto detectado, material, confiança e lixeira;
- Web ganhou reforço de rótulos para garrafas/latas/papel e uma pista visual local para garrafas verdes/âmbar;
- scanner ao vivo fica habilitado também no Web quando a câmera do navegador está disponível;
- se a IA não tiver evidência suficiente, pede outra foto em vez de registrar um material inventado.
