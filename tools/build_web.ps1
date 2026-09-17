$ErrorActionPreference = 'Stop'

flutter build web --no-wasm-dry-run --dart-define-from-file=config/mobile.json
