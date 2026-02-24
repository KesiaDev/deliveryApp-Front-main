# 🧪 Guia de Testes - Firebase e Chat

## 📋 Checklist de Testes

### ✅ 1. TESTAR FIREBASE CORE E MESSAGING

#### Passo 1: Executar o App
```bash
flutter run
```

#### Passo 2: Verificar Logs no Console
Procure por estas mensagens no console/logcat:

**✅ Firebase inicializado:**
```
Firebase initialized successfully
```

**✅ Token FCM obtido:**
```
🔥 Token FCM: [um_token_longo_aqui]
```

**✅ Permissão de notificações:**
```
Usuário autorizou notificações
```

#### Passo 3: Verificar no Firebase Console
1. Acesse: https://console.firebase.google.com/
2. Selecione o projeto: `foolapp-c7f40`
3. Vá em **Cloud Messaging** → **Tokens**
4. Você deve ver o token do dispositivo listado

---

### ✅ 2. TESTAR CHAT EM TEMPO REAL (FIRESTORE)

#### Teste Manual - Enviar Mensagem

**Como testar:**
1. Abra o app em **2 dispositivos/emuladores diferentes** (ou 1 dispositivo + 1 emulador)
2. Faça login como:
   - **Dispositivo 1:** Cliente (Empresa)
   - **Dispositivo 2:** Motorista

3. **No dispositivo do Cliente:**
   - Vá em **Mensagens** (ícone de chat ou menu)
   - Selecione uma conversa ou crie uma nova corrida
   - Envie uma mensagem: "Olá, teste!"

4. **No dispositivo do Motorista:**
   - Abra a mesma conversa
   - **A mensagem deve aparecer automaticamente em tempo real!** ⚡

#### Verificar no Firestore Console
1. Acesse: https://console.firebase.google.com/
2. Vá em **Firestore Database**
3. Você deve ver:
   - Coleção `chatRooms` com as salas de chat
   - Subcoleção `messages` dentro de cada sala com as mensagens

---

### ✅ 3. TESTAR MENSAGENS AUTOMÁTICAS

#### Teste: Mudança de Status da Corrida

**Como testar:**
1. Como **Cliente**, crie uma nova corrida
2. Como **Motorista**, aceite a corrida
3. Abra o **Chat** da corrida
4. **Você deve ver a mensagem automática:**
   - "O motoboy está a caminho do ponto de retirada."

5. Continue mudando o status da corrida:
   - **Em andamento** → "O item já foi retirado e está indo para o destino."
   - **Concluída** → "Corrida finalizada com sucesso. Obrigado por usar nosso app!"

#### Verificar no Firestore
- As mensagens automáticas devem aparecer com `senderType: "system"`

---

### ✅ 4. TESTAR PUSH NOTIFICATIONS

#### Teste Manual via Firebase Console

**Passo 1: Obter o Token FCM**
1. Execute o app
2. No console, copie o token que aparece: `🔥 Token FCM: [token]`

**Passo 2: Enviar Notificação de Teste**
1. Acesse: https://console.firebase.google.com/
2. Vá em **Cloud Messaging** → **Send test message**
3. Cole o token FCM
4. Digite título e mensagem
5. Clique em **Test**

**Resultado esperado:**
- Se o app estiver em **foreground**: Log no console `📩 Mensagem em foreground: [título]`
- Se o app estiver em **background**: Notificação aparece na barra de notificações
- Se o app estiver **fechado**: Notificação aparece e ao clicar abre o app

---

### ✅ 5. TESTAR UI DO CHAT

#### Checklist Visual

**Tela de Lista de Conversas:**
- [ ] Search bar no topo
- [ ] Cards com avatar circular
- [ ] Nome da conversa visível
- [ ] Última mensagem visível
- [ ] Horário da última mensagem à direita
- [ ] Contador de não lidas (se houver)
- [ ] Empty state com ícone de moto (quando não há conversas)

**Tela de Chat:**
- [ ] Fundo cinza claro (#F8F5FA)
- [ ] AppBar com avatar e nome do destinatário
- [ ] Status "Online" ou "Digitando..."
- [ ] Bolhas de mensagem:
  - [ ] Minhas mensagens: vermelho (#E74A3B) com texto branco
  - [ ] Mensagens recebidas: branco com borda cinza
- [ ] Timestamps formatados corretamente
- [ ] Campo de input arredondado
- [ ] Botão de enviar vermelho quando há texto
- [ ] Scroll automático para última mensagem
- [ ] Animações suaves ao enviar mensagem

---

### ✅ 6. TESTAR INTEGRAÇÃO COMPLETA

#### Cenário Completo de Teste

1. **Cliente cria corrida:**
   - [ ] Mensagem automática aparece: "Sua corrida foi criada! Estamos buscando um motoboy."

2. **Motorista aceita corrida:**
   - [ ] Mensagem automática aparece: "O motoboy está a caminho do ponto de retirada."

3. **Cliente envia mensagem:**
   - [ ] Motorista recebe em tempo real
   - [ ] Motorista recebe notificação push (se app em background)

4. **Motorista responde:**
   - [ ] Cliente recebe em tempo real
   - [ ] Cliente recebe notificação push (se app em background)

5. **Status muda para "Em andamento":**
   - [ ] Mensagem automática aparece para ambos

6. **Corrida concluída:**
   - [ ] Mensagem automática: "Corrida finalizada com sucesso..."

---

## 🔍 Verificações Técnicas

### Verificar Logs do Flutter
```bash
flutter run --verbose
```

Procure por:
- `Firebase initialized`
- `FCM Token:`
- `Mensagem recebida em foreground`
- `App aberto através de notificação`

### Verificar Logs do Android (Logcat)
```bash
adb logcat | grep -i firebase
```

### Verificar Firestore em Tempo Real
1. Abra Firestore Console
2. Vá em uma sala de chat
3. Envie mensagem pelo app
4. **A mensagem deve aparecer instantaneamente no console!**

---

## 🐛 Troubleshooting

### Problema: Token FCM não aparece
**Solução:**
- Verifique se as permissões foram concedidas
- Verifique se o `google-services.json` está correto
- Limpe e reconstrua: `flutter clean && flutter pub get`

### Problema: Mensagens não aparecem em tempo real
**Solução:**
- Verifique conexão com internet
- Verifique regras do Firestore (devem permitir leitura/escrita)
- Verifique logs do console para erros

### Problema: Notificações não chegam
**Solução:**
- Verifique se o token FCM foi obtido
- Verifique se as permissões foram concedidas
- Teste enviando notificação manual pelo Firebase Console

### Problema: Build falha
**Solução:**
- Verifique se `google-services.json` está em `android/app/`
- Verifique se o package name está correto: `com.fool.delivery_front`
- Execute `flutter clean && flutter pub get`

---

## 📱 Teste Rápido (5 minutos)

1. **Execute o app:**
   ```bash
   flutter run
   ```

2. **Verifique o console:**
   - Deve aparecer: `🔥 Token FCM: [token]`

3. **Acesse Mensagens:**
   - Clique no ícone de chat ou menu → Mensagens

4. **Envie uma mensagem de teste:**
   - Se não houver conversas, crie uma corrida primeiro
   - Envie: "Teste 123"

5. **Verifique no Firestore:**
   - A mensagem deve aparecer no console do Firebase

**Se tudo isso funcionar, está OK! ✅**

---

## 🎯 Próximos Passos Após Testes

1. **Configurar Cloud Functions** (opcional):
   - Para enviar notificações push automaticamente
   - Quando nova mensagem chegar

2. **Configurar Regras do Firestore** (importante):
   - Garantir segurança dos dados
   - Permitir apenas leitura/escrita para usuários autenticados

3. **Adicionar Índices** (se necessário):
   - Para melhor performance em queries complexas

---

## ✅ Checklist Final

- [ ] Firebase Core inicializado
- [ ] Token FCM obtido
- [ ] Chat funcionando em tempo real
- [ ] Mensagens automáticas aparecendo
- [ ] UI moderna do chat funcionando
- [ ] Push notifications funcionando
- [ ] Build compilando sem erros
- [ ] Nenhuma lógica quebrada

**Se todos os itens estiverem marcados, está tudo funcionando! 🎉**

