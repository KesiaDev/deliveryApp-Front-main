# Testes Automatizados - Fool Delivery

## 📋 Estrutura de Testes

```
test/
├── README.md                          # Este arquivo
├── widget_test.dart                   # Teste padrão (pode ser removido)
├── mocks/
│   └── mock_login_controller.dart     # Mocks para LoginController
├── widgets/
│   ├── splash_page_test.dart          # Testes de widget do SplashPage
│   └── splash_navigation_test.dart    # Testes de navegação
├── unit/
│   └── home_page_timers_test.dart     # Testes unitários de timers
└── integration/
    └── auth_flow_test.dart            # Testes de integração
```

## 🚀 Como Executar

### Executar todos os testes
```bash
flutter test
```

### Executar testes específicos
```bash
# Apenas testes de widget
flutter test test/widgets/

# Apenas testes unitários
flutter test test/unit/

# Teste específico
flutter test test/widgets/splash_page_test.dart
```

### Executar com cobertura
```bash
flutter test --coverage
```

### Ver relatório de cobertura
```bash
# Instale lcov (Linux/Mac)
# brew install lcov  # Mac
# sudo apt-get install lcov  # Linux

# Gere relatório
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # Mac
xdg-open coverage/html/index.html  # Linux
```

## 📝 Testes Implementados

### 1. SplashPage Tests (3 testes)
- ✅ Renderização de elementos visuais
- ✅ Execução do bootstrap após primeiro frame
- ✅ Manutenção da UI durante autenticação

### 2. HomePage Timers Tests (5 testes)
- ✅ Criação de timers sem crash
- ✅ Cancelamento de timers no dispose
- ✅ GPS timer não executa após dispose
- ✅ Polling timer não executa após dispose
- ✅ Múltiplos ciclos não causam memory leaks

### 3. Integration Tests (1 teste)
- ✅ Fluxo completo de autenticação

**Total: 9 testes** (6 críticos + 3 adicionais)

## 🔧 Dependências de Teste

As seguintes dependências foram adicionadas ao `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4          # Para criar mocks
  build_runner: ^2.4.7      # Para gerar código dos mocks
  fake_async: ^1.3.1        # Para testar timers
```

## 📦 Gerar Mocks (se necessário)

Se precisar gerar mocks do LoginController:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## ✅ Cobertura Mínima Atendida

- ✅ **SplashPage**: Navegação baseada em autenticação
- ✅ **HomePage**: Timers cancelados no dispose
- ✅ **6+ testes** cobrindo fluxos críticos

## 🐛 Troubleshooting

### Erro: "Mock not found"
Execute: `flutter pub run build_runner build`

### Erro: "Timer not cancelled"
Verifique que `dispose()` está sendo chamado corretamente.

### Testes muito lentos
Use `fakeAsync` para controlar o tempo nos testes de timer.

## 📊 Exemplo de Saída

```
00:02 +9: All tests passed!
```

## 🔄 Adicionar Novos Testes

1. Crie arquivo em `test/widgets/`, `test/unit/` ou `test/integration/`
2. Importe `flutter_test`
3. Use `testWidgets()` para testes de widget
4. Use `test()` para testes unitários
5. Execute `flutter test` para validar

## 📚 Recursos

- [Flutter Testing](https://docs.flutter.dev/testing)
- [Mockito](https://pub.dev/packages/mockito)
- [Fake Async](https://pub.dev/packages/fake_async)

