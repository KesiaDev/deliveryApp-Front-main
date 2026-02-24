# 📝 GUIA: Como Configurar o arquivo key.properties

## 🔍 O que é o `key.properties`?

O arquivo `key.properties` é um arquivo de configuração **local e privado** que armazena informações sensíveis do seu projeto Android, como:

1. **Google Maps API Key** - Chave para usar o Google Maps
2. **Credenciais de Assinatura (Signing)** - Senhas e informações do keystore para gerar o APK de produção

## ⚠️ Por que é importante?

**ANTES das correções:**
- ❌ API Key estava **exposta** no código (qualquer um podia ver)
- ❌ Senhas do keystore não estavam configuradas
- ❌ App de produção usava chaves de debug (inseguro)

**DEPOIS das correções:**
- ✅ API Key fica em arquivo **privado** (não versionado)
- ✅ Credenciais de assinatura configuradas corretamente
- ✅ App de produção usa chaves de produção (seguro)

---

## 📋 PASSO A PASSO: Como Criar e Configurar

### Passo 1: Criar o arquivo `key.properties`

1. Vá até a pasta `android/` do seu projeto
2. Copie o arquivo de exemplo:
   ```bash
   # No terminal, dentro da pasta android/
   cp key.properties.example key.properties
   ```
   
   **OU** crie manualmente um arquivo chamado `key.properties` na pasta `android/`

### Passo 2: Abrir o arquivo para editar

Abra o arquivo `android/key.properties` em um editor de texto (VS Code, Android Studio, Notepad++, etc.)

### Passo 3: Preencher com suas informações

O arquivo deve ficar assim:

```properties
# Google Maps API Key
GOOGLE_MAPS_API_KEY=AIzaSyBJ-GzLkdL3BUc9TJd1ZdrDdF_NV8Y9JN8

# Keystore configuration (para release builds)
storeFile=../foolApp.jks
keyAlias=sua_key_alias_aqui
keyPassword=sua_senha_da_chave_aqui
storePassword=sua_senha_do_keystore_aqui
```

---

## 🔑 O que cada campo significa?

### 1. `GOOGLE_MAPS_API_KEY`
**O que é:** A chave da API do Google Maps que você usa no app.

**Onde encontrar:**
- Se você já tem uma: use a mesma que estava no AndroidManifest (a que foi movida)
- Se não tem: crie uma no [Google Cloud Console](https://console.cloud.google.com/)

**Exemplo:**
```properties
GOOGLE_MAPS_API_KEY=AIzaSyBJ-GzLkdL3BUc9TJd1ZdrDdF_NV8Y9JN8
```

---

### 2. `storeFile`
**O que é:** Caminho para o arquivo do keystore (arquivo `.jks` ou `.keystore`).

**Onde encontrar:**
- Você já tem arquivos `.jks` na pasta `android/`:
  - `fool.jks`
  - `foolApp.jks`
  - `foolAppNew.jks`

**Como usar:**
- Se o arquivo está na pasta `android/`, use: `../foolApp.jks`
- Se está em outra pasta, ajuste o caminho

**Exemplo:**
```properties
storeFile=../foolApp.jks
```

---

### 3. `keyAlias`
**O que é:** O "apelido" ou nome da chave dentro do keystore.

**Onde encontrar:**
- Foi definido quando você criou o keystore
- Se não lembra, pode listar com: `keytool -list -v -keystore foolApp.jks`

**Exemplo:**
```properties
keyAlias=upload
# ou
keyAlias=key
# ou outro nome que você definiu
```

---

### 4. `keyPassword`
**O que é:** A senha da chave específica (não a senha do keystore).

**Onde encontrar:**
- Foi definida quando você criou o keystore
- Pode ser igual ou diferente da `storePassword`

**Exemplo:**
```properties
keyPassword=minhasenha123
```

---

### 5. `storePassword`
**O que é:** A senha do arquivo keystore (a senha principal).

**Onde encontrar:**
- Foi definida quando você criou o keystore
- É a senha que você precisa para abrir o arquivo `.jks`

**Exemplo:**
```properties
storePassword=minhasenha123
```

---

## 📝 EXEMPLO COMPLETO

Aqui está um exemplo de como seu arquivo `key.properties` deve ficar:

```properties
# Google Maps API Key
GOOGLE_MAPS_API_KEY=AIzaSyBJ-GzLkdL3BUc9TJd1ZdrDdF_NV8Y9JN8

# Keystore configuration (para release builds)
storeFile=../foolApp.jks
keyAlias=upload
keyPassword=MinhaSenh@123
storePassword=MinhaSenh@123
```

---

## ⚠️ IMPORTANTE: Segurança

### ✅ O que fazer:
- ✅ O arquivo `key.properties` **NÃO** será versionado (está no `.gitignore`)
- ✅ Mantenha este arquivo **privado** e **seguro**
- ✅ Não compartilhe este arquivo publicamente
- ✅ Não envie por email ou mensagem

### ❌ O que NÃO fazer:
- ❌ **NÃO** commite o `key.properties` no Git
- ❌ **NÃO** compartilhe as senhas
- ❌ **NÃO** publique este arquivo em repositórios públicos

---

## 🎯 Quando você precisa do `key.properties`?

### Para builds de DEBUG:
- ✅ **NÃO é obrigatório** - O app funciona normalmente
- ✅ Se não existir, usa o fallback (API Key hardcoded)

### Para builds de RELEASE (produção):
- ⚠️ **É OBRIGATÓRIO** se você quer:
  - Assinar o app com suas chaves de produção
  - Publicar na Google Play Store
  - Distribuir o app oficialmente

---

## 🔧 Como verificar se está funcionando?

### 1. Teste o build de debug:
```bash
flutter build apk --debug
```
Se funcionar, a API Key está sendo lida corretamente.

### 2. Teste o build de release:
```bash
flutter build apk --release
```
Se funcionar e o app estiver assinado, as credenciais estão corretas.

---

## ❓ E se eu não tiver um keystore?

Se você **não tem** um keystore ainda, você precisa criar um:

### Criar um novo keystore:
```bash
# No terminal, dentro da pasta android/
keytool -genkey -v -keystore foolApp.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Isso vai pedir:
- Senha do keystore (use para `storePassword`)
- Senha da chave (use para `keyPassword`)
- Seu nome, organização, etc.

Depois, use essas informações no `key.properties`.

---

## 📍 Onde fica o arquivo?

```
deliveryApp-Front-main/
└── android/
    ├── key.properties          ← AQUI (você cria)
    ├── key.properties.example  ← Template (já existe)
    ├── foolApp.jks             ← Seu keystore (se tiver)
    └── app/
        └── build.gradle        ← Lê o key.properties
```

---

## 🆘 Problemas Comuns

### "Arquivo não encontrado"
- ✅ Certifique-se que o arquivo está em `android/key.properties`
- ✅ Verifique se o nome está correto (sem espaços)

### "Senha incorreta"
- ✅ Verifique se `keyPassword` e `storePassword` estão corretas
- ✅ Verifique se `keyAlias` está correto

### "Keystore não encontrado"
- ✅ Verifique se o caminho em `storeFile` está correto
- ✅ Verifique se o arquivo `.jks` existe

---

## 📚 Resumo Rápido

1. **Crie** o arquivo `android/key.properties`
2. **Copie** o conteúdo do `key.properties.example`
3. **Preencha** com suas informações:
   - API Key do Google Maps
   - Caminho do keystore
   - Senhas e alias
4. **Teste** com `flutter build apk --release`
5. **Nunca** commite este arquivo no Git

---

**Pronto!** Agora você sabe como configurar o `key.properties`! 🎉



