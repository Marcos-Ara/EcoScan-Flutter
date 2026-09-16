param([string]$WebConfig = '..\EcoScan-AI-main\config.js')
$ErrorActionPreference = 'Stop'
$config = Get-Content -Raw -LiteralPath $WebConfig
$catalogUrl = [regex]::Match($config, "ECOSCAN_SUPABASE_URL = '([^']+)'").Groups[1].Value
$catalogKey = [regex]::Match($config, "ECOSCAN_SUPABASE_ANON_KEY = '([^']+)'").Groups[1].Value
if (-not $catalogUrl.StartsWith('https://') -or -not $catalogKey) { throw 'Configuração pública ausente.' }
$result = @{ generatedAt = [DateTime]::UtcNow.ToString('o'); source = 'Supabase EcoScan — catálogo público' }
$tables = @{
  objects = @('ecoscan_object_master', 'object_id,object_name,detection_class,is_active,is_ambiguous,material_name,category_name,bin_name,recommendation,preparation_instructions,special_waste,variant_count')
  variants = @('ecoscan_variant_master', 'variant_id,object_id,material_name,category_name,bin_name,recommendation,preparation_instructions')
  aliases = @('object_aliases', 'object_id,variant_id,normalized_alias,is_active')
}
foreach ($key in $tables.Keys) {
  $table = $tables[$key][0]
  $fields = $tables[$key][1]
  $all = @()
  $offset = 0
  do {
    $url = "$catalogUrl/rest/v1/$($table)?select=$fields&limit=500&offset=$offset"
    $page = Invoke-RestMethod -Uri $url -Headers @{apikey=$catalogKey} -TimeoutSec 25
    $all += $page
    $offset += $page.Count
  } while ($page.Count -eq 500)
  $result[$key] = $all
  Write-Output "$key : $($all.Count)"
}
$assetDirectory = Join-Path $PSScriptRoot '..\assets\data'
New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
$result | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $assetDirectory 'catalog.json') -Encoding utf8
