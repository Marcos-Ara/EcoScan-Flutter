# Contas Firebase e Google

## E-mail e senha — mesmo projeto da web

Projeto original: ecoscan-b8b02. Domínio: ecoscan-b8b02.firebaseapp.com. A chave pública está em lib/core/backend_config.dart, retirada da configuração web enviada.

O serviço lib/services/firebase_session.dart implementa:

- cadastro e nome;
- login por e-mail/senha;
- envio/reenvio e consulta de confirmação do e-mail;
- recuperação de senha;
- alteração do nome;
- mudança de e-mail com confirmação do novo endereço;
- reautenticação e mudança de senha;
- restauração/renovação e encerramento da sessão.

No console Firebase do seu projeto, verifique Authentication → Sign-in method → E-mail/senha e os modelos de e-mail. As contas existentes continuam no mesmo projeto. O aplicativo usa a API REST oficial, sem inventar IDs nativos Firebase e sem exigir google-services.json para este fluxo de e-mail.

Se você restringiu a chave pública somente a origens web, revise a configuração para a aplicação móvel conforme as orientações do Firebase/Google. Não exponha credenciais administrativas para tentar corrigir o acesso.

O refresh token fica no armazenamento seguro do sistema (Android/iOS). Senhas não são persistidas pelo aplicativo. A entrada na área interna exige conta verificada.

## Google — configuração ainda necessária

O ZIP da web não trazia identificadores OAuth nativos nem a assinatura Android. Portanto, a tela está presente, mas tocar em Continuar com Google informa essa pendência até você configurar.

### Android

1. No mesmo projeto Firebase/Google Cloud, habilite o provedor Google.
2. Registre o aplicativo Android com applicationId br.com.ecoscan.ecoscan_mobile.
3. Obtenha SHA-1/SHA-256 da assinatura usada para instalar o APK, por exemplo com a tarefa signingReport do Gradle no seu ambiente. Cadastre as impressões no projeto.
4. Configure o cliente OAuth Android com esse pacote e SHA-1.
5. Obtenha o ID do cliente OAuth do tipo Web do mesmo projeto. Não é a chave de API nem o ID do cliente Android.
6. Copie config/mobile.example.json para config/mobile.json e preencha GOOGLE_WEB_CLIENT_ID.
7. Execute/compile novamente passando --dart-define-from-file=config/mobile.json.

Como o client ID Web é fornecido explicitamente ao plugin Google, esta base não utiliza o plugin Gradle google-services. Os clientes OAuth Android/Web e as assinaturas continuam necessários. A assinatura do APK de teste pode ser diferente da gerada no seu computador; configure o SHA correspondente a cada uma. Para produção, use o SHA da assinatura de produção/Play conforme o caso.

### iOS

1. Registre o bundle ID br.com.ecoscan.ecoscanMobile no mesmo projeto (confira o Runner no Xcode caso o altere).
2. Preencha GOOGLE_IOS_CLIENT_ID e GOOGLE_WEB_CLIENT_ID.
3. Em ios/Runner/Info.plist, adicione CFBundleURLTypes/CFBundleURLSchemes com o REVERSED_CLIENT_ID do cliente iOS. Exemplo de formato, não de credencial real: com.googleusercontent.apps.SEUID.
4. Configure a assinatura Apple no Xcode e teste em iPhone.

Nunca coloque client secret, chave service_account, chave administrativa ou senha pessoal dentro do app. Os identificadores OAuth e a chave pública do cliente não substituem regras de acesso e configuração dos serviços.

## Dados e fotos

O projeto web guardava histórico e foto do usuário no navegador. Esta entrega mantém os dados locais, agora isolados por UID Firebase. Não foi criado um backend de sincronização de fotos/histórico. Escolha novamente sua foto no perfil do celular; ela não constava dos arquivos do projeto.

O catálogo público de materiais usado na web foi exportado para assets/data/catalog.json e acompanha o app. Isso evita uma consulta de rede a cada foto. Para renovar o catálogo, tools/export_catalog.ps1 recebe -WebConfig com o caminho do config.js original; o script usa apenas consultas de leitura. A configuração Supabase do app não faz sincronização automática.

## Referências oficiais

- [Firebase Auth REST](https://firebase.google.com/docs/reference/rest/auth)
- [Google Sign-In para Flutter](https://pub.dev/packages/google_sign_in)
- [Configuração Android do Google Sign-In](https://pub.dev/packages/google_sign_in_android)
- [Configuração iOS do Google Sign-In](https://pub.dev/packages/google_sign_in_ios)
- [Armazenamento seguro](https://pub.dev/packages/flutter_secure_storage)
