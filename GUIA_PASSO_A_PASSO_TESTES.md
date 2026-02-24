# 🚀 Guia Passo a Passo - Como Testar o App (Para Iniciantes)

## 📋 Pré-requisitos

Antes de começar, você precisa ter instalado:

1. **Flutter SDK** - [Como instalar](https://docs.flutter.dev/get-started/install)
2. **Android Studio** ou **VS Code** com extensão Flutter
3. **Um dispositivo Android/iOS** ou **Emulador**

---

## 🔍 Passo 1: Verificar se o Flutter está Instalado

Abra o **PowerShell** (Windows) ou **Terminal** (Mac/Linux) e digite:

```bash
flutter --version
```

**O que esperar:**
- Deve mostrar a versão do Flutter (ex: Flutter 3.x.x)
- Se aparecer erro "comando não encontrado", você precisa instalar o Flutter primeiro

**Se não tiver Flutter instalado:**
1. Baixe em: https://docs.flutter.dev/get-started/install
2. Siga as instruções de instalação
3. Adicione o Flutter ao PATH do sistema

---

## 📂 Passo 2: Navegar até a Pasta do Projeto

No PowerShell, navegue até a pasta do projeto:

```bash
cd C:\Users\User\Desktop\deliveryApp-Front-main\deliveryApp-Front-main
```

**Dica:** Você pode também:
1. Abrir a pasta do projeto no Windows Explorer
2. Clicar com botão direito na pasta
3. Selecionar "Abrir no Terminal" ou "Abrir no PowerShell"

---

## 📦 Passo 3: Instalar as Dependências do Projeto

Este comando baixa todas as bibliotecas que o app precisa:

```bash
flutter pub get
```

**O que esperar:**
- Vai mostrar "Running pub get..." e depois "Got dependencies!"
- Pode demorar alguns minutos na primeira vez
- Se aparecer erro, verifique sua conexão com internet

**Exemplo de saída esperada:**
```
Running "flutter pub get" in delivery_front...
Resolving dependencies...
Got dependencies!
```

---

## 🔍 Passo 4: Verificar se Há Erros no Código

Antes de rodar, vamos verificar se há problemas:

```bash
flutter analyze
```

**O que esperar:**
- Se estiver tudo ok: "No issues found!"
- Se houver avisos: aparecerão listados (mas não impedem o app de rodar)
- Se houver erros: precisam ser corrigidos antes de continuar

**Exemplo de saída esperada:**
```
Analyzing delivery_front...
No issues found! (ran in 2.3s)
```

---

## 📱 Passo 5: Verificar Dispositivos Conectados

Antes de rodar, vamos ver quais dispositivos estão disponíveis:

```bash
flutter devices
```

**O que esperar:**
- Lista de dispositivos/emuladores disponíveis
- Exemplo:
  ```
  3 connected devices:
  
  sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
  Windows (desktop)           • windows       • windows-x64    • Microsoft Windows
  Chrome (web)                • chrome       • web-javascript • Google Chrome
  ```

**Se não aparecer nenhum dispositivo:**
- **Para Android:** Abra o Android Studio e inicie um emulador
- **Para iOS (Mac):** Abra o Xcode e inicie um simulador
- **Para Web:** Pode usar o Chrome diretamente

---

## 🚀 Passo 6: Executar o App

### Opção A: Rodar no Primeiro Dispositivo Disponível

```bash
flutter run
```

### Opção B: Escolher um Dispositivo Específico

Se você tem múltiplos dispositivos, pode escolher:

```bash
# Para Android
flutter run -d android

# Para iOS (apenas Mac)
flutter run -d ios

# Para Web
flutter run -d chrome

# Para Windows Desktop
flutter run -d windows
```

**O que esperar:**
- O Flutter vai compilar o app (pode demorar alguns minutos na primeira vez)
- Vai mostrar progresso: "Running Gradle task 'assembleDebug'..."
- Quando terminar, o app vai abrir automaticamente no dispositivo/emulador
- No terminal, você verá logs do app rodando

**Exemplo de saída:**
```
Launching lib\main.dart on sdk gphone64 arm64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app.apk...
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminar app mas manter processo)
c Clear the screen
q Quit (terminar app completamente)
```

---

## 🧪 Passo 7: Testar as Funcionalidades Básicas

### Teste 1: Verificar se o App Abriu Corretamente

**O que verificar:**
- ✅ O app abriu sem travar
- ✅ Apareceu a tela inicial (Splash Screen com logo)
- ✅ Não apareceu nenhuma tela de erro

**Se aparecer erro:**
- Anote a mensagem de erro
- Verifique os logs no terminal
- Veja a seção "Problemas Comuns" abaixo

---

### Teste 2: Testar o Fluxo de Login

**Passos:**
1. O app deve mostrar a tela de **Splash** primeiro
2. Depois deve ir para a tela de **Login** (se não estiver logado)
3. Tente fazer login:
   - **Com credenciais inválidas:** Deve mostrar mensagem de erro amigável
   - **Com credenciais válidas:** Deve entrar no app

**O que verificar:**
- ✅ Navegação entre telas funciona
- ✅ Mensagens de erro aparecem quando necessário
- ✅ Login funciona com credenciais corretas

---

### Teste 3: Testar Navegação no App

Depois de fazer login, teste os botões de navegação:

**Passos:**
1. Na tela inicial (Home), clique nos botões:
   - **Corridas** → Deve abrir tela de corridas
   - **Saldos** → Deve abrir tela de saldos
   - **Editar Cadastro** → Deve abrir tela de edição
   - **Logout** → Deve voltar para tela de login

**O que verificar:**
- ✅ Todos os botões respondem ao clique
- ✅ Navegação entre telas é suave
- ✅ Botão "voltar" funciona corretamente

---

### Teste 4: Verificar Logs no Terminal

Enquanto usa o app, observe o terminal. Você deve ver logs como:

```
[INFO] Usuário fez login
[INFO] Navegando para HomePage
[ERROR] Erro ao buscar dados: Connection timeout
```

**O que verificar:**
- ✅ Logs aparecem no console
- ✅ Erros são logados quando acontecem
- ✅ Logs são informativos e úteis

---

## 🛠️ Comandos Úteis Durante o Teste

Enquanto o app está rodando, você pode usar estes comandos no terminal:

### Hot Reload (Recarregar sem fechar o app)
Pressione **`r`** no terminal

**Quando usar:**
- Depois de fazer uma alteração no código
- Para ver mudanças rapidamente sem reiniciar o app

### Hot Restart (Reiniciar o app)
Pressione **`R`** no terminal

**Quando usar:**
- Quando hot reload não funciona
- Para reiniciar o estado do app

### Ver Todos os Comandos
Pressione **`h`** no terminal

### Limpar a Tela
Pressione **`c`** no terminal

### Fechar o App
Pressione **`q`** no terminal

---

## 🐛 Problemas Comuns e Soluções

### Problema 1: "Flutter não é reconhecido como comando"

**Solução:**
1. Verifique se o Flutter está instalado: `flutter --version`
2. Se não estiver, instale o Flutter
3. Adicione o Flutter ao PATH do sistema

---

### Problema 2: "No devices found"

**Solução:**
1. Para Android:
   - Abra o Android Studio
   - Vá em Tools → Device Manager
   - Crie um emulador ou conecte um dispositivo físico via USB
   - Ative "Modo Desenvolvedor" e "Depuração USB" no dispositivo

2. Para Web:
   - Use: `flutter run -d chrome`

---

### Problema 3: "Gradle build failed"

**Solução:**
1. Limpe o projeto:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Verifique se o Android SDK está instalado corretamente

---

### Problema 4: "App fecha sozinho (crash)"

**Solução:**
1. Veja os logs no terminal para identificar o erro
2. Verifique se todas as permissões estão configuradas
3. Verifique se a API está acessível (URL correta)

---

### Problema 5: "Erro de permissões"

**Solução:**
1. Para Android: Verifique `android/app/src/main/AndroidManifest.xml`
2. Para iOS: Verifique `ios/Runner/Info.plist`
3. Garanta que as permissões necessárias estão declaradas

---

## 📊 Checklist de Testes

Use este checklist para garantir que testou tudo:

### Funcionalidades Básicas
- [ ] App abre sem erros
- [ ] Splash screen aparece
- [ ] Tela de login aparece (se não logado)
- [ ] Login funciona com credenciais válidas
- [ ] Login mostra erro com credenciais inválidas

### Navegação
- [ ] Botão "Corridas" funciona
- [ ] Botão "Saldos" funciona
- [ ] Botão "Editar Cadastro" funciona
- [ ] Botão "Logout" funciona
- [ ] Botão "Voltar" funciona

### Diferentes Perfis
- [ ] Login como Motorista funciona
- [ ] Login como Empresa funciona
- [ ] Login como Admin funciona

### Tratamento de Erros
- [ ] Erros são mostrados de forma amigável
- [ ] App não fecha quando há erro de rede
- [ ] Logs aparecem no console

---

## 🎯 Próximos Passos Após Testar

1. **Se tudo funcionou:**
   - ✅ Parabéns! O app está funcionando
   - Continue desenvolvendo novas features
   - Considere adicionar mais testes automatizados

2. **Se encontrou problemas:**
   - Anote os erros encontrados
   - Veja os logs no terminal
   - Verifique a seção "Problemas Comuns" acima
   - Se necessário, peça ajuda com os erros específicos

---

## 📚 Recursos Adicionais

- **Documentação Flutter:** https://docs.flutter.dev
- **Flutter Community:** https://flutter.dev/community
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/flutter

---

## 💡 Dicas para Iniciantes

1. **Sempre teste em um dispositivo real quando possível** - Emuladores podem ter comportamentos diferentes

2. **Observe os logs** - Eles são muito úteis para entender o que está acontecendo

3. **Use Hot Reload** - Facilita muito o desenvolvimento

4. **Não tenha medo de errar** - Erros são normais e fazem parte do aprendizado

5. **Leia as mensagens de erro** - Elas geralmente indicam o que está errado

---

**Boa sorte com os testes! 🚀**

Se tiver dúvidas ou problemas, anote as mensagens de erro e peça ajuda!

