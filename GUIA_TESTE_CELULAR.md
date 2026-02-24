# 📱 Guia Passo a Passo - Testar App no Celular

## ✅ Pré-requisitos

### 1. No Celular Android
- ✅ **Opções de Desenvolvedor** ativadas
- ✅ **Depuração USB** ativada
- ✅ Celular conectado via cabo USB ao computador
- ✅ Autorizar depuração USB quando aparecer o popup no celular

### 2. No Computador
- ✅ Flutter instalado e configurado
- ✅ Android SDK instalado
- ✅ Drivers USB do celular instalados (geralmente automático no Windows)

---

## 🚀 Passo a Passo para Testar

### **Passo 1: Verificar se o celular está conectado**

Abra o terminal/PowerShell e execute:

```bash
flutter devices
```

**Resultado esperado:**
```
Found X connected devices:
  SM G780F (mobile)  • RQ8NA06WDQF  • android-arm64  • Android 13 (API 33)
```

Se o celular aparecer na lista, está tudo certo! ✅

---

### **Passo 2: Navegar até a pasta do projeto**

```bash
cd deliveryApp-Front-main
```

---

### **Passo 3: Instalar dependências (se necessário)**

```bash
flutter pub get
```

---

### **Passo 4: Executar o app no celular**

#### **Opção A: Pelo Terminal (Recomendado)**

```bash
flutter run -d RQ8NA06WDQF
```

Ou simplesmente (se for o único dispositivo):

```bash
flutter run
```

#### **Opção B: Pelo Android Studio**

1. Abra o projeto no Android Studio
2. No topo, clique no dropdown de dispositivos
3. Selecione **"samsung SM-G780F"**
4. Clique no botão **▶️ Run** (ou pressione `Shift + F10`)

---

### **Passo 5: Aguardar a compilação**

- O Flutter vai compilar o app (pode levar 1-3 minutos na primeira vez)
- Você verá mensagens como:
  ```
  Running Gradle task 'assembleDebug'...
  Built build\app\outputs\flutter-apk\app-debug.apk
  Installing...
  Launching lib\main.dart on SM G780F in debug mode...
  ```

---

### **Passo 6: App instalado e rodando**

- O app será instalado automaticamente no seu celular
- O app abrirá automaticamente
- Você verá a **Splash Screen** primeiro

---

## 🧪 Testes Básicos Recomendados

### **Teste 1: Fluxo de Inicialização**
1. ✅ App abre na Splash Screen
2. ✅ Se não estiver logado, vai para a tela de Login
3. ✅ Se estiver logado, vai direto para a Home

### **Teste 2: Login**
1. Tente fazer login com credenciais válidas
2. Verifique se navega para a Home correta (Motorista/Empresa/Admin)

### **Teste 3: Navegação**
1. Teste os botões de navegação
2. Verifique se as rotas funcionam corretamente
3. Teste o botão "Voltar"

### **Teste 4: Funcionalidades Específicas**
- **Motorista**: Ver corridas disponíveis
- **Empresa**: Criar nova corrida
- **Admin**: Gerenciar empresas/motoristas

---

## 🔧 Solução de Problemas

### **Problema: Celular não aparece no `flutter devices`**

**Soluções:**
1. Verifique se a depuração USB está ativada no celular
2. Desconecte e reconecte o cabo USB
3. Tente outro cabo USB
4. No celular, autorize a depuração quando aparecer o popup
5. Reinicie o ADB:
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### **Problema: Erro de compilação**

**Soluções:**
1. Limpe o build:
   ```bash
   flutter clean
   flutter pub get
   ```
2. Verifique se há erros:
   ```bash
   flutter analyze
   ```

### **Problema: App não instala**

**Soluções:**
1. Verifique se há espaço suficiente no celular
2. Desinstale versões antigas do app manualmente
3. Tente novamente:
   ```bash
   flutter run
   ```

### **Problema: App fecha ao abrir (crash)**

**Soluções:**
1. Veja os logs no terminal
2. Verifique permissões no celular (localização, etc.)
3. Tente em modo release:
   ```bash
   flutter run --release
   ```

---

## 📊 Comandos Úteis

### Ver logs em tempo real
```bash
flutter logs
```

### Parar a execução
- Pressione `q` no terminal onde o app está rodando
- Ou `Ctrl + C`

### Reinstalar o app
```bash
flutter run --debug
```

### Build APK para instalar manualmente
```bash
flutter build apk --debug
```
O APK estará em: `build\app\outputs\flutter-apk\app-debug.apk`

---

## 🎯 Dicas Importantes

1. **Mantenha o celular desbloqueado** durante a instalação
2. **Não desconecte o cabo USB** enquanto o app está instalando
3. **Primeira instalação é mais lenta** (compilação completa)
4. **Instalações seguintes são mais rápidas** (hot reload)
5. **Use `r` no terminal** para hot reload (recarregar sem reinstalar)
6. **Use `R` no terminal** para hot restart (reiniciar o app)

---

## ✅ Checklist Rápido

- [ ] Celular conectado via USB
- [ ] Depuração USB ativada
- [ ] Celular aparece em `flutter devices`
- [ ] Executou `flutter pub get`
- [ ] Executou `flutter run`
- [ ] App instalou e abriu no celular
- [ ] Testou funcionalidades básicas

---

## 🆘 Precisa de Ajuda?

Se encontrar algum problema:
1. Verifique os logs no terminal
2. Execute `flutter doctor` para verificar configuração
3. Verifique se todas as dependências estão instaladas

**Boa sorte com os testes! 🚀**


