# Google Login — correção consolidada

O fluxo Web usa `google_sign_in 7.x` com o botão oficial do Google Identity Services.

## O que ficou configurado

- cliente OAuth Web do projeto `ecoscan-ai-e961f`;
- origem local `http://localhost:7357` autorizada no cliente OAuth;
- domínio Firebase Hosting autorizado;
- cliente ID também presente na meta tag oficial de `web/index.html`;
- inicialização de `GoogleSignIn.instance` protegida para acontecer uma única vez;
- `authenticationEvents` recebe o login Web e troca o ID token pelo token do Firebase Auth REST.

## Teste local

```powershell
.\tools\run_web.ps1
```

Se o botão abrir a conta Google mas não entrar no EcoScan, confira no DevTools a chamada:

```text
identitytoolkit.googleapis.com/v1/accounts:signInWithIdp
```

Ela deve usar a API key do mesmo projeto `ecoscan-ai-e961f`.

## Produção

```powershell
.\tools\build_web.ps1
firebase.cmd deploy --only hosting
```

O Hosting já inclui o cabeçalho `Cross-Origin-Opener-Policy: same-origin-allow-popups`.
