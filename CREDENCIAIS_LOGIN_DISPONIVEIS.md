# 🔐 Credenciais de Login Disponíveis - ATUALIZADO

## ✅ ÚNICO LOGIN CONFIRMADO FUNCIONANDO

### **Administrador**
```
📧 Email: liocer123@admin
🔑 Senha: 1234
👤 Tipo: Admin (indTipo = 99)
✅ Status: FUNCIONANDO
```

---

## ⚠️ MOTORISTAS - SITUAÇÃO ATUAL

### **motorista.teste@fool.com**
```
📧 Email: motorista.teste@fool.com
🔑 Senha: ??? (NÃO É 123456)
❌ Status: USUÁRIO EXISTE mas senha está incorreta
```

**Problema:** O usuário existe no banco, mas a senha não é `123456`.

**Soluções:**
1. **Criar novo motorista pelo app** (recomendado)
2. **Resetar senha** (se houver funcionalidade)
3. **Verificar senha correta** com o administrador do sistema

---

## 🚀 COMO CRIAR NOVO MOTORISTA DE TESTE AGORA

### **Opção 1: Criar pelo App (RECOMENDADO)**

1. **Abra o app Flutter**
2. **Na tela de login, clique em "CADASTRO MOTORISTA"**
3. **Preencha os dados:**

   **Conta:**
   - Email: `motorista.teste2@fool.com` (ou outro email único)
   - Senha: `123456`
   - Confirmar Senha: `123456`

   **Dados Pessoais:**
   - CPF/CNPJ: Selecione **CPF**
   - CPF: `123.456.789-01`
   - Nome: `Motorista Teste 2`

   **Veículo:**
   - Placa: `XYZ5678`
   - Modelo: `Honda CG 160`

   **Endereço:**
   - CEP: `01310-100` (preenche automaticamente)
   - Número: `1000`
   - Bairro: `Bela Vista`
   - Cidade: `São Paulo`
   - Estado: `SP`

   **Documentos:**
   - **CNH:** Anexe uma foto da CNH (OBRIGATÓRIO)

4. **Clique em "ENVIAR"**
5. **Após criar, faça login com as credenciais criadas**

---

### **Opção 2: Usar Email Único**

Se `motorista.teste@fool.com` já existe, use um email diferente:

**Sugestões de emails:**
- `motorista.teste2@fool.com`
- `teste.motorista@fool.com`
- `motorista1@fool.com`
- `motoboy.teste@fool.com`

**Senha:** `123456` (mínimo 6 caracteres)

---

## 📋 RESUMO DAS CREDENCIAIS

| Tipo | Email | Senha | Status |
|------|-------|-------|--------|
| ✅ Admin | `liocer123@admin` | `1234` | **Funcionando** |
| ❌ Motorista | `motorista.teste@fool.com` | `???` | Existe mas senha incorreta |
| ⚠️ Motorista | `[criar novo]` | `123456` | **Criar pelo app** |

---

## 🎯 PRÓXIMOS PASSOS

1. **Use o Admin para testar funcionalidades administrativas:**
   - Email: `liocer123@admin`
   - Senha: `1234`

2. **Crie um novo motorista pelo app:**
   - Siga as instruções acima
   - Use um email único
   - Anexe a CNH (obrigatório)

3. **Após criar, teste o login:**
   - Use as credenciais criadas
   - Verifique se consegue acessar a Home do motorista

---

## 💡 POR QUE NÃO CONSEGUIMOS CRIAR VIA SCRIPT?

A API retorna **403 (Forbidden)** ao tentar criar motorista sem:
- CNH anexada (obrigatório)
- Autenticação adequada
- Validações completas

**Solução:** Criar pelo app garante que todos os campos obrigatórios sejam preenchidos corretamente.

---

**Última atualização:** Agora mesmo 🚀

