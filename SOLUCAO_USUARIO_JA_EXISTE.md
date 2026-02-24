# 🔧 Solução: "Usuário já existe!"

## ❌ Problema
Ao tentar criar um novo motorista, aparece o erro:
```
Erro ao salvar registro: Usuário já existe!
```

## 🔍 Causa
Isso acontece porque:
1. **Os motoristas foram bloqueados, mas não excluídos** do banco de dados
2. A API valida se o **email já existe** antes de criar um novo usuário
3. Mesmo bloqueados, os emails continuam registrados no sistema

## ✅ Soluções

### **Solução 1: Usar um email diferente (RECOMENDADO)**

Quando você tentar criar um novo motorista e receber o erro "Usuário já existe", o app agora mostrará um diálogo sugerindo um email alternativo com timestamp.

**Exemplo:**
- Email original: `motorista.teste@fool.com`
- Email sugerido: `motorista.teste.1234567890@fool.com`

**Como usar:**
1. Copie o email sugerido do diálogo
2. Cole no campo "E-mail" do cadastro
3. Preencha os demais campos normalmente
4. Envie o cadastro

### **Solução 2: Criar manualmente com email único**

Use um email único adicionando números ou data:

**Exemplos de emails únicos:**
- `motorista.teste.001@fool.com`
- `motorista.teste.2024@fool.com`
- `motorista.teste.$(date +%s)@fool.com` (com timestamp)
- `motorista.teste.${DateTime.now().millisecondsSinceEpoch}@fool.com`

### **Solução 3: Limpar usuários bloqueados (ADMIN)**

Se você tem acesso ao banco de dados ou API:

1. **Verificar usuários bloqueados:**
   - Acesse a tela de Motoristas no Admin
   - Veja quais estão com status "Bloqueado"

2. **Excluir permanentemente:**
   - Use o botão **"Excluir"** (ícone vermelho) na AppBar
   - Ou exclua individualmente pelo menu "..." de cada card
   - ⚠️ **ATENÇÃO:** Isso remove permanentemente do sistema

3. **Depois de excluir:**
   - Tente criar o novo motorista novamente
   - Use o mesmo email que estava dando erro

## 📝 Dicas

### ✅ Boas Práticas:
- Use emails únicos para cada teste
- Adicione timestamp ou número sequencial ao email
- Exemplo: `motorista.teste.${timestamp}@fool.com`

### ❌ Evite:
- Reutilizar emails de motoristas bloqueados
- Usar emails genéricos como `teste@fool.com` (já pode estar em uso)

## 🚀 Script Rápido

Se você quiser criar um motorista de teste rapidamente:

```dart
// Use este formato de email:
final timestamp = DateTime.now().millisecondsSinceEpoch;
final email = 'motorista.teste.$timestamp@fool.com';
```

Isso garante que cada tentativa de cadastro use um email único!

## 💡 Por que isso acontece?

A API valida **unicidade de email** antes de criar um usuário. Mesmo que um motorista esteja:
- ❌ Bloqueado
- ❌ Inativo
- ❌ Com status "excluído" (soft delete)

O email ainda está registrado no banco de dados e não pode ser reutilizado.

---

**Última atualização:** Quando você receber o erro "Usuário já existe", o app agora mostrará automaticamente um email sugerido para você usar! 🎉

