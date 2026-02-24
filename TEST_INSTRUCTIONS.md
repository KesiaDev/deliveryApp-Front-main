# Instruções para Executar Testes

## 📋 Pré-requisitos

1. Flutter SDK instalado e no PATH
2. Dependências instaladas: `flutter pub get`

## 🚀 Comandos Básicos

### Instalar Dependências
```bash
flutter pub get
```

### Executar Todos os Testes
```bash
flutter test
```

### Executar Testes com Cobertura
```bash
flutter test --coverage
```

### Executar Teste Específico
```bash
flutter test test/widgets/splash_page_test.dart
flutter test test/unit/home_page_timers_test.dart
```

## 📊 Testes Implementados

### 1. Testes de Widget (4 testes)
- `test/widgets/splash_page_test.dart` - Renderização do SplashPage
- `test/widgets/splash_navigation_test.dart` - Navegação do SplashPage

### 2. Testes Unitários (5 testes)
- `test/unit/home_page_timers_test.dart` - Cancelamento de timers

### 3. Testes de Integração (1 teste)
- `test/integration/auth_flow_test.dart` - Fluxo de autenticação

**Total: 10 testes** (6 críticos + 4 adicionais)

## ✅ Cobertura dos Requisitos

### ✅ Requisito 1: SplashPage decide corretamente entre login e home
- **Testes**: `splash_page_test.dart`, `splash_navigation_test.dart`
- **Cobertura**: Renderização, bootstrap, navegação

### ✅ Requisito 2: Timers substituídos por Timer.periodic e cancelados
- **Testes**: `home_page_timers_test.dart`
- **Cobertura**: 
  - Criação de timers sem crash
  - Cancelamento no dispose
  - GPS timer cancelado
  - Polling timer cancelado
  - Múltiplos ciclos sem memory leaks

### ✅ Requisito 3: 6+ testes cobrindo fluxos críticos
- **Total**: 10 testes implementados
- **Cobertura**: Widgets, unitários, integração

## 🔧 Gerar Mocks (Opcional)

Se precisar gerar mocks do LoginController:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📝 Estrutura de Testes

```
test/
├── README.md                          # Documentação completa
├── TEST_INSTRUCTIONS.md               # Este arquivo
├── widget_test.dart                   # Teste básico do AppWidget
├── mocks/
│   └── mock_login_controller.dart     # Definição de mocks
├── widgets/
│   ├── splash_page_test.dart          # Testes do SplashPage
│   └── splash_navigation_test.dart    # Testes de navegação
├── unit/
│   └── home_page_timers_test.dart     # Testes de timers
└── integration/
    └── auth_flow_test.dart            # Testes de integração
```

## 🐛 Troubleshooting

### Erro: "package:flutter_test/flutter_test.dart not found"
Execute: `flutter pub get`

### Erro: "Mock not found"
Execute: `flutter pub run build_runner build`

### Erro: "Timer not cancelled"
Verifique que o código em `lib/home/home_page.dart` tem:
- `_gpsVerificationTimer?.cancel()` no dispose
- `_chamadosPollingTimer?.cancel()` no dispose

### Testes muito lentos
Os testes de timer usam `fake_async` para controlar o tempo, então devem ser rápidos.

## 📈 Exemplo de Saída Esperada

```
00:02 +10: All tests passed!
```

## 🎯 Próximos Passos

Para adicionar mais testes:

1. Crie arquivo em `test/widgets/`, `test/unit/` ou `test/integration/`
2. Importe `package:flutter_test/flutter_test.dart`
3. Use `testWidgets()` para testes de widget
4. Use `test()` para testes unitários
5. Execute `flutter test` para validar

## 📚 Recursos

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget)
- [Unit Testing](https://docs.flutter.dev/cookbook/testing/unit)

