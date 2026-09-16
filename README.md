# EcoScan AI — Flutter 2.0

Aplicativo nativo para Android e iOS, atualizado a partir dos dois ZIPs fornecidos: a base Flutter e o EcoScan web completo.

## Comece aqui

1. Extraia a pasta EcoScan-Flutter.
2. Leia GUIA_INSTALACAO.md.
3. Para contas e Google, leia CONFIGURACAO_FIREBASE.md.
4. Consulte VERIFICACAO.md para saber o que foi testado e as limitações.

## Telas incluídas

Intro animada com a identidade verde da web; login; cadastro; confirmação de e-mail; recuperação de senha; início; scanner com câmera e galeria; histórico e detalhe de análise; estatísticas; aprendizado; conquistas; EcoPontos; criadores; perfil com foto, nome, e-mail e senha; configurações e saída da conta.

São telas Flutter nativas, adaptadas para o celular, não uma página web dentro do app. A fonte Outfit, as cores, os textos principais e a marca de setas/folha da web foram reaproveitados ou recriados em desenho nativo. Abertura e ícones Android/iOS usam essa marca.

## Scanner

- Câmera iniciada ao abrir o scanner; liberada ao sair ou colocar o app em segundo plano.
- Prévia sem esticar, foco por toque, foco/exposição automáticos, flash e troca de lente.
- Leitura periódica ao vivo e captura manual. Câmera e galeria usam o mesmo processamento.
- Orientação da imagem corrigida e tamanho reduzido em processamento separado da interface.
- Resultado: material, lixeira e instrução. Sem nome de objeto ou tempo de decomposição.
- Materiais ambíguos pedem confirmação; é possível corrigir o material antes de salvar.
- O modelo ML Kit é genérico. O catálogo da web complementa as regras, mas não é um modelo treinado para reconhecer composição. Não há promessa de acerto para qualquer objeto.
- Catálogo público incluído para leitura offline: 133 objetos, 9 variantes e 216 aliases, exportados em 16/09/2026.

## Contas e dados

O login por e-mail usa Firebase Authentication REST no mesmo projeto da web, ecoscan-b8b02. O app não abre a área interna sem uma conta verificada; uma sessão válida anterior pode ser recuperada automaticamente após a intro.

O Google possui tela e integração nativa, mas faltam os identificadores OAuth Android/iOS que não estavam nos arquivos recebidos. Consulte o guia.

Fotos, histórico e conquistas ficam neste aparelho, separados por conta. Tokens de sessão usam armazenamento seguro; senhas não são salvas pelo app. O histórico e as fotos guardados no navegador da web não migram automaticamente. Nenhuma foto pessoal estava incluída nos ZIPs: selecione-a novamente no perfil.

## EcoPontos

Busca ao mover o mapa, mantendo os pontos das áreas anteriores e reordenando por distância. Estilos escuro, ruas e satélite; filtros e abertura de rota externa. A cobertura depende dos locais cadastrados no OpenStreetMap; não equivale a todos os estabelecimentos do Google Maps nem garante completude de uma cidade.

## Estrutura

- lib/core: configuração pública e tema.
- lib/screens: todas as telas.
- lib/services: autenticação, scanner, catálogo e busca dos EcoPontos.
- lib/state: conta local, histórico e estado do mapa.
- lib/models: materiais, análises e EcoPontos.
- assets: catálogo e fonte licenciada.
- test: testes automatizados.
- tools: atualização do catálogo e geração de ícones.
- verification/previews: imagens das telas renderizadas nos testes.

Firebase/Google, localização, mapa e envios de e-mail dependem de serviços externos e de suas permissões. O reconhecimento da foto processada não envia a imagem para um servidor próprio.
