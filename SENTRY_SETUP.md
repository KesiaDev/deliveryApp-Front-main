# Configuração do Sentry

Este documento explica como ativar o Sentry para monitoramento de erros em produção.

## Pré-requisitos

1. Conta no [Sentry](https://sentry.io)
2. Projeto criado no Sentry
3. DSN do projeto

## Passo 1: Adicionar Dependência

Adicione ao `pubspec.yaml`:

```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

Execute:
```bash
flutter pub get
```

## Passo 2: Configurar DSN

### Opção A: Via --dart-define (Recomendado)

No `main.dart`, atualize:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Sentry se DSN estiver disponível
  await SentryConfig.initialize(
    dsn: const String.fromEnvironment('SENTRY_DSN'),
  );
  
  // ... resto do código
  runApp(AppWidget());
}
```

Execute com:
```bash
flutter run --dart-define=SENTRY_DSN=https://seu-dsn@sentry.io/projeto-id
```

### Opção B: Via .env (Alternativa)

1. Crie um arquivo `.env` na raiz do projeto:
```
SENTRY_DSN=https://seu-dsn@sentry.io/projeto-id
```

2. Adicione `flutter_dotenv` ao pubspec.yaml:
```yaml
dependencies:
  flutter_dotenv: ^5.0.0
```

3. No `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  
  await SentryConfig.initialize(
    dsn: dotenv.env['SENTRY_DSN'],
  );
  
  runApp(AppWidget());
}
```

## Passo 3: Atualizar SentryConfig

Descomente o código em `lib/core/sentry_config.dart` após adicionar a dependência.

## Passo 4: Build de Produção

Para builds de produção, sempre inclua a DSN:

```bash
flutter build apk --release --dart-define=SENTRY_DSN=https://...
flutter build ios --release --dart-define=SENTRY_DSN=https://...
```

## Verificação

1. O Sentry só é inicializado em modo release (não em debug)
2. Verifique os logs - não deve aparecer erro de inicialização
3. Teste enviando um erro manualmente e verifique no dashboard do Sentry

## Notas

- O Sentry é opcional - o app funciona normalmente sem ele
- Em modo debug, o Sentry não é inicializado
- Todos os erros são logados localmente mesmo sem Sentry

