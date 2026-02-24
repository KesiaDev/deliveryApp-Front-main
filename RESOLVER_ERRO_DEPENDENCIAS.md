# 🔧 Resolver Erro de Dependências

## ⚠️ Problema
Os pacotes adicionados recentemente não foram baixados, causando erros de compilação:
- `fl_chart` (gráficos)
- `local_auth` (biometria)
- `pdf` (exportação PDF)
- `printing` (impressão)
- `excel` (exportação Excel)
- `csv` (exportação CSV)

## ✅ Solução Rápida

### Opção 1: Script PowerShell (Mais Fácil) ⭐

1. Clique com o botão direito em `fix_dependencies.ps1`
2. Selecione "Executar com PowerShell"
3. Aguarde a conclusão

**OU** execute no PowerShell:
```powershell
cd c:\Users\User\Desktop\deliveryApp-Front-main
.\fix_dependencies.ps1
```

### Opção 2: Via Terminal/CMD

1. Abra o terminal na pasta do projeto:
   ```cmd
   cd c:\Users\User\Desktop\deliveryApp-Front-main
   ```

2. Execute os comandos:
   ```cmd
   flutter clean
   flutter pub get
   ```

3. Aguarde a conclusão e tente compilar novamente.

### Opção 3: Via IDE (VS Code/Cursor)

1. Abra o terminal integrado (Ctrl + ` ou Terminal > New Terminal)
2. Execute:
   ```bash
   flutter clean
   flutter pub get
   ```
3. Aguarde e tente compilar novamente (F5 ou Run)

## Verificação

Após executar `flutter pub get`, verifique se os pacotes foram instalados:

```bash
flutter pub deps | findstr "fl_chart local_auth pdf printing excel csv"
```

Se os pacotes aparecerem na lista, o problema foi resolvido.

## Se o problema persistir

1. Verifique sua conexão com a internet
2. Verifique se o Flutter está atualizado:
   ```bash
   flutter --version
   flutter upgrade
   ```
3. Tente limpar o cache do pub:
   ```bash
   flutter pub cache repair
   ```

## Nota sobre Biometria (Android)

Se após resolver as dependências ainda houver problemas com `local_auth`, pode ser necessário adicionar permissões no `AndroidManifest.xml`, mas isso não causa erros de compilação - apenas problemas em runtime.
