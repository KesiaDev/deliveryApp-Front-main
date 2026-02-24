@echo off
echo Limpando cache do Flutter...
flutter clean

echo.
echo Baixando dependencias...
flutter pub get

echo.
echo Verificando dependencias...
flutter pub deps

echo.
echo Concluido! Tente compilar novamente.

pause
