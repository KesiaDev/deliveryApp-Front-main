# 🔍 Verificação do Usuário Motorista

## 📋 Informações do Usuário

**Email:** `motorista1@testeadmin`  
**Senha:** `123`  
**Tipo:** Motorista (indTipo = 1)

---

## 🧪 Como Verificar

### **Opção 1: Usar o Script de Teste**

Execute o script de teste criado:

```bash
dart test_motorista_login.dart
```

Este script vai:
- ✅ Testar se o usuário existe na API
- ✅ Verificar se as credenciais estão corretas
- ✅ Mostrar informações detalhadas do usuário se o login funcionar
- ❌ Mostrar erro específico se não funcionar

### **Opção 2: Testar Manualmente com Postman/cURL**

**Endpoint:**
```
POST https://api.foolentregas.com.br/v1/public/login
```

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "username": "motorista1@testeadmin",
  "password": "123",
  "desTokenFcm": null,
  "indLogado": false
}
```

**Com cURL:**
```bash
curl -X POST https://api.foolentregas.com.br/v1/public/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "motorista1@testeadmin",
    "password": "123",
    "desTokenFcm": null,
    "indLogado": false
  }'
```

---

## 🔍 O que Verificar

### **Se retornar 200 OK:**
✅ Usuário existe e credenciais estão corretas  
✅ Verifique os dados retornados (codUsuario, desNome, tipPerfil, jwt)

### **Se retornar 401 Unauthorized:**
❌ Usuário não existe OU credenciais estão incorretas

**Possíveis causas:**
1. O usuário `motorista1@testeadmin` não existe no banco de dados
2. A senha não é `123` (pode ser diferente)
3. O email está incorreto ou tem formato diferente
4. O usuário pode estar bloqueado (`indBloqueado = 1`)

---

## 💡 Próximos Passos

### **Se o usuário NÃO existe:**
1. **Criar o usuário no banco de dados:**
   - Use o cadastro do app para criar um novo motorista
   - Ou crie diretamente no banco de dados
   - Ou use a API de cadastro: `POST /public/criarUsuario`

2. **Verificar outras credenciais:**
   - Teste com o admin: `liocer123@admin` / `1234`
   - Teste com empresa: `empresa@admin` / `123`
   - Se esses funcionarem, o problema é específico do motorista

### **Se o usuário existe mas a senha está errada:**
1. **Verificar a senha no banco de dados:**
   - A senha pode estar criptografada
   - Pode ser diferente de `123`
   - Pode ter sido alterada

2. **Resetar a senha:**
   - Use a funcionalidade de "Esqueci minha senha" se existir
   - Ou atualize diretamente no banco de dados

---

## 📝 Logs do App

Quando você tentar fazer login pelo app, verifique os logs:

```
🟢 [LOGIN] Email recebido: "motorista1@testeadmin"
🟢 [LOGIN] Username no JSON: "motorista1@testeadmin"
🔴 [LOGIN] Status Code: 401
🔴 [LOGIN] Response data: Usuário ou senha incorretos
```

Isso confirma que:
- ✅ O email está sendo enviado corretamente
- ✅ A requisição está chegando na API
- ❌ Mas as credenciais estão sendo rejeitadas

---

## ✅ Checklist

- [ ] Executei o script de teste
- [ ] Verifiquei se o usuário existe no banco de dados
- [ ] Confirmei a senha correta
- [ ] Testei com outras credenciais conhecidas
- [ ] Verifiquei se o usuário está bloqueado
- [ ] Testei a API diretamente (Postman/cURL)

---

**Última atualização:** Agora mesmo! 🚀





