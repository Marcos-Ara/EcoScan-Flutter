# Como abrir e testar o EcoScan

## 1. Projeto não é o Flutter SDK

Extraia este projeto, por exemplo em C:\Projetos\EcoScan-Flutter. Instale o Flutter SDK em outra pasta, como C:\src\flutter. Não copie o app para dentro do SDK.

A pasta antiga mencionada em Desktop\Flutter App\flutter não estava disponível na verificação desta entrega. Foi usado Flutter 3.47.4 com Dart 3.13.3. O projeto exige Dart 3.13.3 ou compatível com a restrição do pubspec.yaml.

No Windows, prefira caminhos sem espaços para o projeto, SDK e cache de pacotes, pois ferramentas nativas de algumas dependências podem falhar com espaços.

## 2. Preparar Android

Instale o Android Studio e o Flutter SDK. No SDK Manager, instale Android SDK Platform 36, Build-Tools 36.0.0, Platform-Tools e Command-line Tools. O projeto usa NDK 28.2.13676358; o Gradle pode baixá-lo na primeira compilação após as licenças serem aceitas. Java 17 foi usado nesta entrega.

Adicione C:\src\flutter\bin ao Path e abra um novo terminal. Confira e leia/aceite as licenças Android:

~~~powershell
flutter doctor
flutter doctor --android-licenses
~~~

Sites oficiais: [Flutter](https://docs.flutter.dev/install) e [Android Studio](https://developer.android.com/studio).

## 3. Abrir a base

No Android Studio, use Open e escolha a pasta que contém pubspec.yaml. No terminal dessa pasta:

~~~powershell
flutter pub get
flutter analyze
flutter test
~~~

O primeiro download e a primeira compilação podem levar vários minutos. Não é necessário gerar outro projeto Flutter nem substituir a pasta lib de uma base antiga.

## 4. Rodar no celular

Ative Depuração USB no Android, conecte o cabo e autorize o computador no celular.

~~~powershell
flutter devices
flutter run
~~~

A sequência é: intro → login/cadastro → confirmação de e-mail → início. Uma conta já verificada com sessão válida pode entrar automaticamente após a intro. Use Configurações → Sair da Conta para testar o login novamente.

Autorize câmera ao abrir o scanner e localização ao abrir o mapa. Também é possível escolher uma imagem pela Galeria quando a câmera não está disponível.

## 5. Gerar o APK

Para um Android ARM64:

~~~powershell
flutter build apk --release --target-platform android-arm64
~~~

Para incluir mais arquiteturas Android:

~~~powershell
flutter build apk --release
~~~

O arquivo é criado em build\app\outputs\flutter-apk\app-release.apk. Android mínimo: 7.0/API 24.

A base usa assinatura de desenvolvimento para testes. Antes da Play Store, configure a chave de assinatura de produção, política de privacidade, configuração OAuth correspondente e faça testes reais. Não coloque chaves privadas no ZIP público.

## 6. Conectar contas

Leia CONFIGURACAO_FIREBASE.md. O e-mail usa a configuração pública do projeto original. Não há conta fictícia nem senha padrão. Não foram criadas contas ou enviados e-mails reais durante os testes automatizados.

Para fornecer os identificadores Google depois de configurá-los:

~~~powershell
flutter run --dart-define-from-file=config/mobile.json
flutter build apk --release --target-platform android-arm64 --dart-define-from-file=config/mobile.json
~~~

Crie mobile.json a partir de config/mobile.example.json. Um identificador vazio mantém o Google pendente; e-mail/senha continua disponível se habilitado no seu Firebase.

## 7. iPhone

É necessário Mac com Xcode, CocoaPods e uma conta de desenvolvimento Apple para instalação conforme o destino escolhido. A base inclui ios/, permissões de câmera, fotos e localização, chaveiro e Podfile com iOS mínimo 15.5.

No Mac:

~~~bash
flutter pub get
cd ios
pod install
cd ..
flutter run
~~~

Configure assinatura no Runner e, para Google, os IDs e o esquema de URL descritos no guia de Firebase. A compilação iOS não foi executada no Windows.

## 8. Roteiro de teste no seu aparelho

1. Abrir pela primeira vez: ver intro e login; cadastrar, confirmar e-mail e entrar.
2. Sair, entrar, recuperar senha e tentar senha incorreta.
3. Alterar foto e nome; fechar/abrir e conferir. Testar outra conta: ela não deve ver o histórico da primeira.
4. Abrir scanner: permitir câmera, testar foco, flash, girar o aparelho e trocar de tela.
5. Escanear um material isolado e bem iluminado. Testar plástico, papel, lata e uma embalagem ambígua.
6. Selecionar JPG/PNG da galeria, cancelar a seleção e retornar ao scanner.
7. Conferir material/lixeira, corrigir se necessário, salvar e abrir a foto no histórico.
8. Bloquear/desbloquear o celular com scanner aberto e verificar retomada.
9. Abrir EcoPontos, permitir localização, mover para outra área e conferir preservação dos pontos anteriores.
10. Conferir perfil, estatísticas, conquistas, aprendizado e temas claro/escuro.

## 9. Problemas comuns

- Câmera negada: habilite a permissão nas configurações do sistema; a galeria permanece como alternativa.
- Imagem não reconhecida: melhore a iluminação, enquadre um único material e confirme o tipo nos botões. A IA não determina a composição física apenas por aparência.
- Arquivo não suportado: use JPG/PNG. Fotos acima de 30 MB são recusadas.
- Login indisponível: confira conexão, provedor E-mail/senha no Firebase, chave pública e restrições aplicadas à API.
- Google pendente: não é resolvido trocando uma imagem ou senha; requer OAuth nativo e SHA da assinatura Android.
- Sem EcoPontos: confira internet/permissão e use Buscar nesta área. Os dados públicos podem estar incompletos ou temporariamente indisponíveis.
- Histórico diferente da web: ele era local no navegador; nesta base também é local, por conta e aparelho.
- Caminho com espaços: use diretórios simples. Em seguida execute flutter clean e flutter pub get dentro do projeto; nunca apague sua pasta Flutter inteira.
