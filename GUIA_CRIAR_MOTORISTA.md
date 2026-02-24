# 🚀 Guia para Criar Motorista de Teste

## 📋 Como Criar um Novo Motorista pelo App

Como o cadastro direto via API pode ter restrições, a melhor forma é criar pelo próprio app:

### **Passo 1: Abrir o App**
1. Execute o app Flutter
2. Vá para a tela de Login

### **Passo 2: Acessar Cadastro de Motorista**
1. Na tela de login, clique em **"CADASTRO MOTORISTA"**
2. Aceite os termos de uso quando solicitado

### **Passo 3: Preencher os Dados**

#### **Seção: Conta**
- **E-mail:** `motorista.teste@fool.com` (ou outro email de sua escolha)
- **Senha:** `123456` (mínimo 6 caracteres)
- **Confirmar Senha:** `123456`

#### **Seção: Dados Pessoais**
- **CPF/CNPJ:** Selecione **CPF**
- **CPF:** `123.456.789-01` (ou use um CPF válido)
- **Nome completo:** `Motorista Teste`

#### **Seção: Veículo** (apenas para motorista)
- **Placa:** `ABC1234`
- **Modelo:** `Honda CG 160` (ou outro modelo)

#### **Seção: Endereço**
- **CEP:** `01310-100` (ou digite um CEP válido - será preenchido automaticamente)
- Os campos de endereço serão preenchidos automaticamente após digitar o CEP

#### **Seção: Documentos**
- **CNH:** Anexe uma foto da CNH (obrigatório para motorista)
- **Comprovante de Residência:** Anexe um comprovante (se solicitado)

### **Passo 4: Enviar Cadastro**
1. Clique em **"ENVIAR"** ou **"CADASTRAR"**
2. Aguarde o processamento
3. Se tudo estiver correto, você será redirecionado para a tela inicial

### **Passo 5: Testar Login**
1. Faça logout (se necessário)
2. Volte para a tela de login
3. Use as credenciais criadas:
   - **Email:** `motorista.teste@fool.com`
   - **Senha:** `123456`

---

## ✅ Credenciais de Teste Criadas

Após criar o motorista, você terá:

```
📧 Email: motorista.teste@fool.com
🔑 Senha: 123456
👤 Nome: Motorista Teste
🚗 Placa: ABC1234
🏍️ Modelo: Honda CG 160
```

---

## 🔍 Verificar se o Cadastro Funcionou

### **Opção 1: Testar Login no App**
1. Faça login com as credenciais criadas
2. Se funcionar, você será redirecionado para a Home do motorista

### **Opção 2: Testar via Script**
Execute o script de teste:

```bash
dart test_motorista_login.dart
```

Mas altere o email no script para o email que você criou.

---

## ⚠️ Possíveis Problemas

### **1. "Usuário já existe"**
- **Solução:** Use outro email para o cadastro

### **2. "Erro ao efetuar cadastro"**
- **Solução:** 
  - Verifique se todos os campos obrigatórios foram preenchidos
  - Verifique se a CNH foi anexada
  - Verifique se o CPF é válido

### **3. "CEP não encontrado"**
- **Solução:** Use um CEP válido (ex: `01310-100` para São Paulo)

---

## 📝 Dados de Exemplo para Teste

### **Email:**
- `motorista.teste@fool.com`
- `teste.motorista@fool.com`
- `motorista1@teste.com`

### **CPF (apenas para teste):**
- `123.456.789-01`
- `111.222.333-44`

### **CEP (São Paulo):**
- `01310-100` (Avenida Paulista)
- `04547-130` (Jardim Paulista)

### **Placa:**
- `ABC1234`
- `XYZ5678`

---

## 🎯 Próximos Passos

Após criar o motorista:

1. ✅ Teste o login com as credenciais criadas
2. ✅ Verifique se consegue acessar a Home do motorista
3. ✅ Teste as funcionalidades do motorista
4. ✅ Documente as credenciais para futuros testes

---

**Última atualização:** Agora mesmo! 🚀





