# EcoScan AI — configuração Supabase

A base usa um único backend para autenticação e banco: Supabase.

## 1. Authentication > Providers > Google

Ative o provedor Google e configure o **Client ID Web** e o **Client Secret** do Google Cloud.
No Google Cloud, adicione como URI de redirecionamento autorizado o callback exibido pelo próprio Supabase, no formato:

`https://tekyqhtodsbeqbrvdtqs.supabase.co/auth/v1/callback`

## 2. Authentication > URL Configuration

Adicione os endereços do site que serão usados em produção/desenvolvimento e também o deep link mobile:

`io.supabase.ecoscan://login-callback/`

Para desenvolvimento Web, adicione o origin usado pelo Flutter, por exemplo:

`http://localhost:7357`

Adicione também o domínio final onde o Web App será publicado.

## 3. E-mail e senha

Em Authentication > Providers > Email, mantenha Email habilitado.
Se **Confirm email** estiver ligado, novos usuários precisam confirmar o e-mail antes de entrar.

## 4. Banco de conhecimento

O scanner resolve primeiro pelo catálogo local `assets/data/catalog.json` para responder rápido e continuar funcionando offline. Quando um rótulo não fica resolvido localmente, ele tenta a RPC já existente:

`public.find_ecoscan_object(p_alias text)`

Assim o Supabase refina a classificação sem virar um ponto obrigatório de latência/falha para toda foto.
Garanta que a role `authenticated` tenha permissão para executar a função e que as tabelas/views usadas por ela tenham RLS/policies adequadas.

## 5. Build

Use:

`flutter pub get`

Web:

`flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define-from-file=config/mobile.json`

Android APK:

`flutter build apk --release --dart-define-from-file=config/mobile.json`

Nunca coloque `service_role` no aplicativo. Use somente a publishable key.

## 6. Google OAuth sem duplicidade

O app usa somente `Supabase.auth.signInWithOAuth(OAuthProvider.google)`. Não há Firebase Auth nem `google_sign_in` nesta base. O botão possui trava contra clique duplo e o estado de sessão é controlado pelo `onAuthStateChange` do Supabase.

No Google Cloud, o URI de redirecionamento autorizado deve ser exatamente:

`https://tekyqhtodsbeqbrvdtqs.supabase.co/auth/v1/callback`

No Supabase, mantenha `http://localhost:7357` entre as Redirect URLs durante o desenvolvimento web.


## Erro `Unable to exchange external code`

Esse erro não é causado pela tela Flutter. Ele acontece no servidor do Supabase quando o Google já devolveu um `code`, mas o Supabase não consegue trocá-lo por tokens. Confira:

1. Authentication > Providers > Google no Supabase: Client ID deve ser o ID do cliente OAuth **Web** e terminar em `.apps.googleusercontent.com`.
2. Client Secret deve pertencer exatamente ao mesmo cliente Web.
3. Google Cloud > cliente OAuth Web > Authorized redirect URIs deve conter exatamente `https://tekyqhtodsbeqbrvdtqs.supabase.co/auth/v1/callback`.
4. Se houver vários Client IDs no Supabase, o Web Client ID deve ficar primeiro.
5. Authentication > URL Configuration deve aceitar `http://localhost:7357` durante o desenvolvimento.

A versão 2.3.0 trata essa falha como erro recuperável e mantém o site utilizável.


## 7. Modo visitante

O botão **Continuar sem conta** é totalmente local. Ele não cria usuário anônimo no Supabase e não exige habilitar Anonymous Sign-Ins. O histórico do visitante usa um namespace local separado (`guest-local`). Ao entrar depois com uma conta real, a sessão Supabase continua independente.
