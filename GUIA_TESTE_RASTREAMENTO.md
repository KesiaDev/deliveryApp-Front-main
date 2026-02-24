# 🗺️ Guia de Teste - Rastreamento em Tempo Real

## ✅ Status: Pronto para Testar

Todas as funcionalidades foram implementadas e integradas.

---

## 📋 Pré-requisitos

1. ✅ Firebase configurado e funcionando
2. ✅ Permissões de localização concedidas (Android/iOS)
3. ✅ Dois dispositivos ou emuladores:
   - **Dispositivo 1**: Motorista (aceita corridas)
   - **Dispositivo 2**: Cliente/Empresa (visualiza rastreamento)

---

## 🧪 Passo a Passo para Testar

### 1️⃣ **Teste do Motorista (Início Automático)**

1. **Faça login como Motorista**
2. **Aceite uma nova corrida** (status 0 → status 1)
3. **Verifique no console/log:**
   ```
   ✅ Rastreamento iniciado automaticamente para corrida {numSeq}
   ```
4. **O rastreamento deve iniciar automaticamente**
   - Localização será salva no Firestore a cada 10 metros ou mudança de posição
   - Verifique no Firebase Console: `/tracking/{corridaId}`

### 2️⃣ **Teste do Cliente (Visualização)**

1. **Faça login como Empresa/Cliente**
2. **Vá em "Minhas Corridas"**
3. **Encontre uma corrida em andamento** (status 1 ou 2)
4. **Procure o botão vermelho com ícone de localização** (ao lado do botão azul de navegação)
5. **Clique em "Rastrear"**
6. **A tela de rastreamento deve abrir:**
   - ✅ Mapa do Google Maps
   - ✅ Marcador vermelho mostrando posição do motorista
   - ✅ Card inferior com "Rastreamento ativo"
   - ✅ Velocidade em km/h (se disponível)
   - ✅ Timestamp da última atualização

### 3️⃣ **Teste de Atualização em Tempo Real**

1. **Com o cliente visualizando o rastreamento:**
2. **Mova o dispositivo do motorista** (ou simule movimento)
3. **A posição deve atualizar automaticamente:**
   - ✅ Marcador se move no mapa
   - ✅ Câmera segue o movimento
   - ✅ Card atualiza timestamp

### 4️⃣ **Teste de Finalização**

1. **Motorista finaliza a corrida** (status 3)
2. **Verifique no console/log:**
   ```
   🛑 Rastreamento parado para corrida {numSeq}
   ```
3. **No Firestore:**
   - Campo `isActive` deve ser `false`
   - Campo `stoppedAt` deve ter timestamp

---

## 🔍 Verificações no Firebase Console

### Estrutura Esperada:

```
/tracking/{corridaId}
  ├── corridaId: "123"
  ├── userId: "456" (ID do motorista)
  ├── lastLatitude: -29.1860583
  ├── lastLongitude: -51.2377713
  ├── lastUpdate: Timestamp
  ├── isActive: true
  └── /locations/{locationId}
      ├── userId: "456"
      ├── latitude: -29.1860583
      ├── longitude: -51.2377713
      ├── timestamp: Timestamp
      ├── speed: 45.5 (opcional)
      └── heading: 90.0 (opcional)
```

---

## 🐛 Troubleshooting

### ❌ "Rastreamento não inicia automaticamente"
- Verifique se o motorista aceitou a corrida (status 1)
- Verifique permissões de localização
- Veja logs do console para erros

### ❌ "Botão Rastrear não aparece"
- Verifique se a corrida está em status 1 ou 2
- Verifique se `codMotorista` não é null
- Verifique se está na tela "Minhas Corridas" da empresa

### ❌ "Tela de rastreamento não atualiza"
- Verifique conexão com Firebase
- Verifique se o motorista está se movendo
- Verifique logs do Firestore no console

### ❌ "Erro ao abrir rastreamento"
- Verifique se `initialLatitude` e `initialLongitude` não são 0.0
- Verifique se há última localização no Firestore
- Verifique se a rota está registrada em `app_widget.dart`

---

## 📱 Pontos de Teste Específicos

### ✅ Início Automático
- [ ] Motorista aceita corrida → Rastreamento inicia
- [ ] Log confirma início
- [ ] Firestore recebe primeira localização

### ✅ Botão Rastrear
- [ ] Botão aparece em corridas status 1 ou 2
- [ ] Botão não aparece em corridas finalizadas
- [ ] Clique abre tela de rastreamento

### ✅ Visualização em Tempo Real
- [ ] Mapa carrega corretamente
- [ ] Marcador aparece na posição correta
- [ ] Atualizações chegam em tempo real
- [ ] Câmera segue movimento

### ✅ Finalização
- [ ] Rastreamento para ao finalizar
- [ ] Firestore marca como inativo
- [ ] Log confirma parada

---

## 🎯 Resultado Esperado

✅ **Motorista**: Rastreamento inicia automaticamente ao aceitar corrida  
✅ **Cliente**: Pode visualizar rastreamento em tempo real  
✅ **Firestore**: Salva todas as localizações  
✅ **UI**: Interface moderna e responsiva  
✅ **Finalização**: Para automaticamente ao encerrar corrida  

---

## 📞 Próximos Passos (Opcional)

- [ ] Adicionar histórico de rota (polyline)
- [ ] Adicionar estimativa de tempo de chegada
- [ ] Adicionar notificações push quando motorista se aproxima
- [ ] Adicionar rastreamento em background

---

**Status**: ✅ Pronto para produção (após testes)

