Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resolvendo Dependências do Flutter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Limpando cache do Flutter..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao limpar cache" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Baixando dependências..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao baixar dependências" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/3] Verificando pacotes instalados..." -ForegroundColor Yellow
flutter pub deps | Select-String -Pattern "fl_chart|local_auth|pdf|printing|excel|csv"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Concluído! Tente compilar novamente." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
