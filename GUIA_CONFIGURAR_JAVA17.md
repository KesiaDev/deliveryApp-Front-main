# ☕ GUIA: Configurar Java 17 no Projeto

**Data:** 2025-01-29  
**Objetivo:** Configurar o projeto para usar Java 17

---

## 📋 PRÓXIMOS PASSOS

### Passo 1: Encontrar o Caminho do Java 17

Você precisa encontrar onde o Java 17 está instalado no seu sistema. Locais comuns no Windows:

- `C:\Program Files\Java\jdk-17`
- `C:\Program Files\Java\jdk-17.0.x`
- `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
- `C:\Program Files\Microsoft\jdk-17.x.x-hotspot`
- `C:\Users\[SeuUsuario]\AppData\Local\Programs\Eclipse Adoptium\jdk-17.x.x-hotspot`

**Como encontrar:**
1. Abra o Explorador de Arquivos
2. Navegue até `C:\Program Files\Java\` ou `C:\Program Files\`
3. Procure por pastas que contenham "jdk-17" ou "java-17"

---

### Passo 2: Configurar no gradle.properties

1. Abra o arquivo `android/gradle.properties`
2. Encontre a linha comentada:
   ```properties
   # org.gradle.java.home=C:/Program Files/Java/jdk-17
   ```
3. Descomente e ajuste o caminho para o seu Java 17:
   ```properties
   org.gradle.java.home=C:/Program Files/Java/jdk-17
   ```
   **Importante:** Use barras `/` ou barras invertidas duplas `\\`, não barra invertida simples `\`

**Exemplo:**
```properties
org.gradle.java.home=C:/Program Files/Eclipse Adoptium/jdk-17.0.10.9-hotspot
```

---

### Passo 3: Verificar se o Caminho Está Correto

O caminho deve apontar para a **pasta raiz do JDK**, não para `bin` ou outras subpastas.

**Estrutura correta:**
```
C:/Program Files/Java/jdk-17/
├── bin/
│   ├── java.exe
│   └── javac.exe
├── lib/
├── include/
└── ...
```

**Caminho correto:** `C:/Program Files/Java/jdk-17`  
**Caminho errado:** `C:/Program Files/Java/jdk-17/bin`

---

### Passo 4: Sincronizar o Projeto

No Android Studio:

1. Clique em **File → Sync Project with Gradle Files**
   - Ou use o botão **"Sync Now"** que aparece no banner
   - Ou pressione **Ctrl+Shift+O** (Windows/Linux) ou **Cmd+Shift+O** (Mac)

2. Aguarde a sincronização completar

3. Se ainda houver erro, tente:
   - **File → Invalidate Caches → Invalidate and Restart**

---

### Passo 5: Verificar se Funcionou

Após sincronizar, verifique:

1. O banner de erro deve desaparecer
2. No console do Gradle, não deve haver erros sobre Java
3. Você pode tentar fazer um build: **Build → Make Project**

---

## 🔧 ALTERNATIVA: Configurar JAVA_HOME (Sistema)

Se preferir configurar para todo o sistema:

### Windows:

1. Abra **Configurações do Sistema** → **Variáveis de Ambiente**
2. Em **Variáveis do Sistema**, clique em **Novo**
3. Nome: `JAVA_HOME`
4. Valor: `C:\Program Files\Java\jdk-17` (caminho do seu Java 17)
5. Clique em **OK**
6. Reinicie o Android Studio

### Verificar JAVA_HOME:

Abra o PowerShell e execute:
```powershell
echo $env:JAVA_HOME
```

Deve mostrar o caminho do Java 17.

---

## ❓ PROBLEMAS COMUNS

### Erro: "Could not find Java 17"

**Solução:**
- Verifique se o caminho em `gradle.properties` está correto
- Use barras `/` ou `\\`, não `\`
- Certifique-se de que o caminho aponta para a pasta raiz do JDK, não para `bin`

### Erro: "Invalid directory"

**Solução:**
- Verifique se a pasta existe
- Verifique se tem permissão de leitura
- Tente usar o caminho completo com barras `/`

### Android Studio não reconhece

**Solução:**
1. **File → Invalidate Caches → Invalidate and Restart**
2. Feche e reabra o Android Studio
3. Verifique se o caminho está correto no `gradle.properties`

---

## ✅ CHECKLIST

- [ ] Java 17 instalado
- [ ] Caminho do Java 17 encontrado
- [ ] `gradle.properties` atualizado com o caminho correto
- [ ] Projeto sincronizado no Android Studio
- [ ] Sem erros de build

---

## 📝 EXEMPLO COMPLETO

Se seu Java 17 está em `C:\Program Files\Eclipse Adoptium\jdk-17.0.10.9-hotspot`:

**android/gradle.properties:**
```properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4096M -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8

# Java 17 configuration
org.gradle.java.home=C:/Program Files/Eclipse Adoptium/jdk-17.0.10.9-hotspot
```

---

**Pronto!** Após configurar, sincronize o projeto e o erro deve desaparecer.



