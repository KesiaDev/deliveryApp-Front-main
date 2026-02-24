# 🧪 Como Testar Firebase e Chat - Guia Rápido

## 🚀 TESTE RÁPIDO (5 minutos)

### 1️⃣ Executar o App
```bash
flutter run
```

### 2️⃣ Verificar Token FCM no Console
Quando o app abrir, procure no console/terminal:

```
🔥 ==========================================
🔥 TOKEN FCM: [um_token_longo_aqui]
🔥 ==========================================
```

**✅ Se aparecer isso, Firebase está funcionando!**

---

## 💬 TESTAR CHAT EM TEMPO REAL

### Opção 1: Teste com 2 Dispositivos/Emuladores

1. **Dispositivo 1 (Cliente):**
   - Faça login como Empresa
   - Vá em **Mensagens** (ícone de chat ou menu)
   - Crie uma corrida ou selecione uma existente
   - Envie: "Teste 123"

2. **Dispositivo 2 (Motorista):**
   - Faça login como Motorista
   - Vá em **Mensagens**
   - Abra a mesma conversa
   - **A mensagem deve aparecer automaticamente!** ⚡

### Opção 2: Teste no Firestore Console

1. Acesse: https://console.firebase.google.com/
2. Projeto: `foolapp-c7f40`
3. Vá em **Firestore Database**
4. Envie uma mensagem pelo app
5. **A mensagem deve aparecer instantaneamente no console!**

---

## 📱 TESTAR PUSH NOTIFICATIONS

### Passo 1: Copiar Token FCM
No console do app, copie o token que aparece:
```
🔥 TOKEN FCM: [cole_aqui]
```

### Passo 2: Enviar Notificação de Teste

1. Acesse: https://console.firebase.google.com/
2. Projeto: `foolapp-c7f40`
3. Vá em **Cloud Messaging** (menu lateral)
4. Clique em **Send test message**
5. Cole o token FCM
6. Digite:
   - **Título:** Teste
   - **Texto:** Esta é uma notificação de teste
7. Clique em **Test**

### Resultado Esperado:

**Se app em FOREGROUND (aberto):**
```
📩 ==========================================
📩 MENSAGEM RECEBIDA (App aberto)
📩 Título: Teste
📩 Corpo: Esta é uma notificação de teste
📩 ==========================================
```

**Se app em BACKGROUND (minimizado):**
- Notificação aparece na barra de notificações

**Se app FECHADO:**
- Notificação aparece
- Ao clicar, abre o app

---

## 🤖 TESTAR MENSAGENS AUTOMÁTICAS

### Como Testar:

1. **Como Cliente:**
   - Crie uma nova corrida
   - Abra o **Chat** da corrida
   - **Deve aparecer:** "Sua corrida foi criada! Estamos buscando um motoboy."

2. **Como Motorista:**
   - Aceite a corrida
   - Abra o **Chat**
   - **Deve aparecer:** "O motoboy está a caminho do ponto de retirada."

3. **Continue mudando status:**
   - Em andamento → "O item já foi retirado..."
   - Concluída → "Corrida finalizada com sucesso..."

---

## ✅ CHECKLIST DE TESTES

### Firebase Core
- [ ] App abre sem erros
- [ ] Token FCM aparece no console
- [ ] Mensagem: "✅ Firebase Messaging: Permissão concedida"

### Chat em Tempo Real
- [ ] Mensagens aparecem instantaneamente
- [ ] Mensagens aparecem no Firestore Console
- [ ] UI moderna funcionando (bolhas, cores, etc)

### Mensagens Automáticas
- [ ] Aparecem quando corrida muda de status
- [ ] Aparecem no chat correto
- [ ] Remetente: "Sistema"

### Push Notifications
- [ ] Token FCM obtido
- [ ] Notificação de teste chega
- [ ] Logs aparecem no console

---

## 🔍 VERIFICAR LOGS

### No Terminal (onde rodou `flutter run`):
Procure por:
- `🔥 TOKEN FCM:`
- `📩 MENSAGEM RECEBIDA`
- `✅ Firebase Messaging: Permissão concedida`

### No Firestore Console:
1. https://console.firebase.google.com/
2. Firestore Database
3. Veja as coleções `chatRooms` e `messages`

---

## 🐛 PROBLEMAS COMUNS

### Token não aparece?
- Verifique se concedeu permissão de notificações
- Verifique se `google-services.json` está correto
- Execute: `flutter clean && flutter pub get`

### Mensagens não aparecem?
- Verifique conexão com internet
- Verifique Firestore Console se mensagens estão sendo salvas
- Verifique logs do console para erros

### Notificações não chegam?
- Verifique se o token FCM foi copiado corretamente
- Verifique se enviou pelo Firebase Console
- Verifique permissões do Android

---

## 📊 TESTE COMPLETO (Cenário Real)

1. ✅ App abre → Token FCM aparece
2. ✅ Cliente cria corrida → Mensagem automática aparece
3. ✅ Cliente envia mensagem → Motorista recebe em tempo real
4. ✅ Motorista responde → Cliente recebe em tempo real
5. ✅ Motorista aceita corrida → Mensagem automática aparece
6. ✅ Envia notificação de teste → Chega no dispositivo

**Se tudo isso funcionar, está 100% OK! 🎉**

---

## 🎯 PRÓXIMOS PASSOS

Após confirmar que tudo funciona:

1. **Configurar Regras do Firestore** (segurança)
2. **Criar Cloud Functions** (notificações automáticas)
3. **Adicionar Índices** (performance)

---

**Dica:** Mantenha o console aberto enquanto testa para ver todos os logs em tempo real!

