$ErrorActionPreference = 'Stop'

Write-Host '1/4 - Limpando build antigo...'
flutter clean

Write-Host '2/4 - Baixando dependencias...'
flutter pub get

Write-Host '3/4 - Analise estatica...'
flutter analyze

Write-Host '4/4 - Testes automatizados...'
flutter test

Write-Host 'Verificacao concluida. Para abrir no Chrome execute: .\tools\run_web.ps1'
