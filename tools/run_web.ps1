$ErrorActionPreference = 'Stop'

flutter run -d chrome `
  --web-hostname localhost `
  --web-port 7357 `
  --web-header "Cross-Origin-Opener-Policy=same-origin-allow-popups" `
  --web-header "Referrer-Policy=no-referrer-when-downgrade" `
  --dart-define-from-file=config/mobile.json
