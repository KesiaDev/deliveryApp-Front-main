# 🔐 Credenciais de Teste - Fool Delivery

## 📋 Credenciais Disponíveis

### 1. **Administrador**
```
Email: liocer123@admin
Senha: 1234
Tipo: Admin (indTipo = 99)
```

### 2. **Motorista** ⚠️ (Usuário não existe - precisa ser criado)
```
Email: motorista1@testeadmin
Senha: 123
Tipo: Motorista (indTipo = 1)
Status: ❌ Não existe no banco de dados
```

### 2.1. **Motorista de Teste** (Criar pelo app)
```
Email: motorista.teste@fool.com
Senha: 123456
Tipo: Motorista (indTipo = 1)
Status: ⚠️ Precisa ser criado pelo app (veja GUIA_CRIAR_MOTORISTA.md)
```

### 3. **Empresa/Cliente** ⚠️ (Usuário não existe - precisa ser criado)
```
Email: empresa@admin
Senha: 123
Tipo: Empresa (indTipo = 2)
Status: ❌ Não existe no banco de dados
⚠️ Este usuário não existe na API. É necessário criar uma empresa pelo app ou backend.
```

---

## 🧪 Como Testar

### **Passo 1: Abrir o App**
- O app deve abrir na tela de Login ou Splash

### **Passo 2: Selecionar Tipo de Login**
- Se aparecer tela de escolha de perfil, selecione o tipo correspondente
- Ou vá direto para a tela de login

### **Passo 3: Inserir Credenciais**
1. Digite o **email** no campo de login
2. Digite a **senha** no campo de senha
3. Clique em **"ENTRAR"**

### **Passo 4: Verificar Resultado**

#### ✅ **Se funcionar:**
- Admin → Vai para `HomeAdminPage`
- Motorista → Vai para `HomePage` (com funcionalidades de motorista)
- Empresa → Vai para `HomePage` (com funcionalidades de empresa)

#### ❌ **Se não funcionar:**
- Aparece mensagem: "E-mail ou senha inválidos"
- Ou erro de conexão com a API

---

## 🔍 Verificação Técnica

### **API Endpoint:**
```
POST https://api.foolentregas.com.br/v1/public/login
```

### **Payload Enviado:**
```json
{
  "username": "email@exemplo.com",
  "password": "senha",
  "desTokenFcm": "token_fcm_do_dispositivo",
  "indLogado": false
}
```

### **Resposta Esperada (Sucesso):**
```json
{
  "jwt": "token_jwt",
  "codUsuario": 123,
  "usuario": "email@exemplo.com",
  "desNome": "Nome do Usuário",
  "tipPerfil": 1, // 1=Motorista, 2=Empresa, 99=Admin
  "usuarioResp": { ... },
  ...
}
```

---

## ⚠️ Possíveis Problemas

### **1. Credenciais Inválidas**
- **Sintoma:** Mensagem "E-mail ou senha inválidos"
- **Causa:** Credenciais não existem no banco de dados da API
- **Solução:** Verificar se as credenciais estão corretas no backend

### **2. Erro de Conexão**
- **Sintoma:** Erro de rede/timeout
- **Causa:** API não está acessível ou internet sem conexão
- **Solução:** Verificar conexão e se a API está online

### **3. Usuário Bloqueado**
- **Sintoma:** Login falha mesmo com credenciais corretas
- **Causa:** Usuário pode estar bloqueado (`indBloqueado = 1`)
- **Solução:** Verificar status do usuário no backend

### **4. Token FCM Não Configurado**
- **Sintoma:** Login funciona mas pode dar erro depois
- **Causa:** OneSignal não está configurado corretamente
- **Solução:** Verificar se OneSignal está inicializado (Android)

---

## 📝 Logs para Debug

Para ver os logs do login, verifique o console onde o app está rodando:

```bash
flutter logs
```

Ou no terminal onde executou `flutter run`, você verá:
- `Login realizado com sucesso` - se funcionou
- `Erro ao realizar login` - se deu erro
- Detalhes da requisição HTTP

---

## ✅ Checklist de Teste

- [ ] App abre corretamente
- [ ] Tela de login aparece
- [ ] Campo de email aceita texto
- [ ] Campo de senha está oculto (****)
- [ ] Botão "ENTRAR" está habilitado
- [ ] Ao clicar, aparece loading
- [x] Login com Admin funciona ✅
- [ ] Login com Motorista funciona (precisa criar)
- [ ] Login com Empresa funciona (precisa criar)
- [ ] Navegação após login está correta
- [ ] Logout funciona

---

## 🆘 Se as Credenciais Não Funcionarem

1. **Verificar se a API está online:**
   - Teste a URL: `https://api.foolentregas.com.br/v1/public/login`
   - Use Postman ou similar para testar diretamente

2. **Verificar logs do app:**
   - Veja o console para mensagens de erro
   - Procure por erros HTTP (401, 403, 500, etc.)

3. **Testar com outras credenciais:**
   - Se você tem acesso ao backend, verifique quais usuários existem
   - Ou crie novos usuários de teste

4. **Verificar formato do email:**
   - O app valida se o email contém "@"
   - Certifique-se de usar o formato correto

---

---

## 📊 Status Atual das Credenciais (Testado em 01/12/2025)

| Tipo | Email | Senha | Status | Observação |
|------|-------|-------|--------|------------|
| ✅ Admin | `liocer123@admin` | `1234` | **Funcionando** | Testado e confirmado |
| ❌ Motorista | `motorista1@testeadmin` | `123` | **Não existe** | Precisa ser criado |
| ❌ Empresa | `empresa@admin` | `123` | **Não existe** | Precisa ser criado |
| ⚠️ Motorista | `motorista.teste@fool.com` | `123456` | **Criar pelo app** | Veja GUIA_CRIAR_MOTORISTA.md |

---

## 💡 Como Criar Usuário de Empresa

Para testar como empresa, você precisa criar pelo app:

### **Passo 1: Abrir o App**
1. Execute o app Flutter
2. Vá para a tela de Login

### **Passo 2: Acessar Cadastro de Cliente**
1. Na tela de login, clique em **"CADASTRO CLIENTE"**
2. Aceite os termos de uso quando solicitado

### **Passo 3: Preencher os Dados**

#### **Seção: Conta**
- **E-mail:** `empresa.teste@fool.com` (ou outro email de sua escolha)
- **Senha:** `123456` (mínimo 6 caracteres)
- **Confirmar Senha:** `123456`

#### **Seção: Dados da Empresa**
- **CPF/CNPJ:** Selecione **CNPJ**
- **CNPJ:** `12.345.678/0001-90` (ou use um CNPJ válido)
- **Nome completo/Razão Social:** `Empresa Teste LTDA`
- **Nome Fantasia:** `Empresa Teste`

#### **Seção: Endereço**
- **CEP:** `01310-100` (ou digite um CEP válido - será preenchido automaticamente)
- Os campos de endereço serão preenchidos automaticamente após digitar o CEP

#### **Seção: Motorista Amigo** (Opcional)
- **E-mail motorista amigo:** Deixe em branco ou informe um email de motorista cadastrado

### **Passo 4: Enviar Cadastro**
1. Clique em **"ENVIAR"** ou **"CADASTRAR"**
2. Aguarde o processamento
3. Se tudo estiver correto, você será redirecionado para a tela inicial

### **Passo 5: Testar Login**
1. Faça logout (se necessário)
2. Volte para a tela de login
3. Use as credenciais criadas:
   - **Email:** `empresa.teste@fool.com`
   - **Senha:** `123456`

---

## ✅ Credenciais de Teste Criadas

Após criar a empresa, você terá:

```
📧 Email: empresa.teste@fool.com
🔑 Senha: 123456
👤 Nome: Empresa Teste LTDA
🏢 CNPJ: 12.345.678/0001-90
```

---

**Última atualização:** 01/12/2025 - Testado via API 🚀


