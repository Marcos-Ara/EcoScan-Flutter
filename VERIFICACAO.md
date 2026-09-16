# Verificação da entrega — 16/09/2026

## Resultado dos testes do código

- Flutter 3.47.4 / Dart 3.13.3, Windows.
- flutter analyze --no-pub: No issues found.
- flutter test --no-pub --dart-define=EXPORT_PREVIEWS=true: 31 testes aprovados.
- Intro, login, início escuro/claro e perfil renderizados e inspecionados em verification/previews.
- Testes de interface em larguras de 360 e 390 pixels, com rolagem para telas longas.

## Comparação de telas com a web

| Web fornecida | Base Flutter |
| --- | --- |
| Splash/intro | SessionGate, identidade de setas/folha e abertura animada |
| Login | AuthScreen: e-mail, senha, Google e recuperação |
| Cadastro | AuthScreen: nome, e-mail, senha e confirmação |
| Verificação de e-mail | VerificationScreen: verificar, reenviar e sair |
| Início | HomeScreen: usuário, foto, contadores e atalhos |
| Câmera | ScannerScreen: câmera, leitura ao vivo, captura e galeria |
| Histórico e detalhe | HistoryScreen e DetectionDetailScreen |
| Estatísticas | StatsScreen |
| Aprender | LearnScreen |
| Conquistas | AchievementsScreen, níveis e oito medalhas |
| EcoPontos | EcoPointsScreen, novas áreas e preservação dos pontos |
| Criadores | CreatorsScreen |
| Perfil | ProfileScreen: foto, nome, e-mail, senha e recuperação |
| Configurações | SettingsScreen: tema, avisos internos, sons e saída |

A recuperação de senha é uma ação da tela de login, como na web. O layout foi adaptado para Flutter, não copiado pixel a pixel. O nome do objeto e a decomposição foram removidos dos resultados, conforme solicitado.

## O que os testes cobrem

- Cadastro, solicitação de confirmação, login sem liberar e-mail não verificado.
- Recuperação, alteração de e-mail e troca de senha com reautenticação.
- Renovação da sessão, senha inválida, falta de rede e configuração Google ausente.
- Histórico/foto separados por conta e limpeza da sessão.
- Distâncias, limite de área, soma dos pontos ao pesquisar outra área, reordenação e ausência de duplicação.
- Catálogo real completo, prioridades de coleta especial e rótulos exatos.
- Embalagens ambíguas não são automaticamente tratadas como plástico.
- Imagem inválida não produz resultado falso.
- Redimensionamento real de foto, preservação do arquivo original e ligação com o serviço de classificação.
- Intro antes do login, cadastro, início em dois temas, galeria com câmera negada e abertura das telas de conteúdo/conta.

Nos testes de autenticação, as respostas Firebase são simuladas; nos testes de scanner, a resposta nativa ML Kit é simulada. Isso testa os fluxos e evita alterar contas reais, mas NÃO mede a precisão do modelo ou o comportamento físico da câmera.

## Limitações e validação ainda necessária

1. Não foi feito teste físico da câmera, foco, flash, rotação e galeria em um celular nesta entrega. Use o roteiro de GUIA_INSTALACAO.md.
2. Login real, mensagens de confirmação/recuperação e alteração de dados dependem do Firebase configurado. Não foram criadas contas ou enviados e-mails reais para validar produção.
3. Google requer OAuth nativo e assinaturas, ausentes nos arquivos enviados. Consulte CONFIGURACAO_FIREBASE.md.
4. O modelo é o classificador genérico do ML Kit, complementado pelo catálogo; não um modelo especializado treinado para resíduos. Materiais ambíguos precisam de confirmação.
5. Fotos/histórico não sincronizam entre navegador e celular. A foto pessoal antiga não estava nos ZIPs.
6. EcoPontos dependem de bases públicas e conexão. A busca consulta a área do mapa, até 25 km de raio por consulta, sem prometer todos os locais existentes.
7. iOS foi preparado, mas não compilado/testado em Mac/iPhone.
8. Avisos são internos ao app; esta base não implementa push remoto.

## Android

- `flutter build apk --release --no-pub --target-platform android-arm64`: concluído com sucesso.
- APK ARM64 gerado com 52,0 MB, Android mínimo API 24.
- O APK usa assinatura de desenvolvimento para teste; não é uma assinatura de publicação da Play Store.
- A compilação apresentou apenas o aviso do SDK sobre formato XML 4, sem impedir a geração.

Testes aprovados e análise limpa não significam garantia de ausência de todos os erros em todos os aparelhos.
