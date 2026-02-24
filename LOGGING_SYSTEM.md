# Sistema de Logging e Tratamento de Erros

## 📋 Visão Geral

Sistema completo de logging estruturado e tratamento de erros implementado no projeto Fool Delivery.

## 🗂️ Arquivos Criados

### Core
- `lib/core/log_config.dart` - Configuração de níveis de log
- `lib/core/logger.dart` - Sistema de logging centralizado
- `lib/core/errors/api_exception.dart` - Exceções tipadas para API
- `lib/core/errors/error_handler.dart` - Handler centralizado de erros
- `lib/core/sentry_config.dart` - Configuração opcional do Sentry

## 🔧 Arquivos Modificados

### Principais
- `lib/core/core.dart` - Exporta novos módulos
- `lib/main.dart` - Inicialização opcional do Sentry
- `lib/bussiness/service/ApiBaseHelper.dart` - Interceptors de logging e erro
- `lib/bussiness/repository/user_repository.dart` - Uso do novo sistema
- `lib/bussiness/service/user_service.dart` - Tratamento de erros
- `lib/login/login_controller.dart` - Mensagens amigáveis
- `lib/cadastro/cadastro_controller.dart` - Tratamento de erros

## 📖 Como Usar

### 1. Logging Básico

```dart
import 'package:delivery_front/core/core.dart';

// Log informativo
Logger.logInfo('Usuário fez login', meta: {'userId': 123});

// Log de aviso
Logger.logWarn('Tentativa de acesso negado', meta: {'endpoint': '/admin'});

// Log de erro
try {
  // código
} catch (e, stackTrace) {
  Logger.logError(
    e,
    stackTrace: stackTrace,
    meta: {'context': 'login'},
    tag: 'LoginService',
  );
}
```

### 2. Tratamento de Erros em Services

```dart
Future<Usuario?> login(LoginRequest login) async {
  try {
    final result = await _userRepository.autenticaUser(null, null, login);
    return result;
  } on ApiException catch (e) {
    // Erro já logado pelo interceptor
    // Retorna mensagem amigável
    throw e;
  } catch (e, stackTrace) {
    Logger.logError(e, stackTrace: stackTrace);
    throw ApiException(
      message: ErrorHandler.handleError(e, stackTrace: stackTrace),
      originalError: e,
    );
  }
}
```

### 3. Tratamento de Erros em Controllers

```dart
Future<void> authenticate() async {
  try {
    final result = await _userService.login(await credential);
    // sucesso
  } on ApiException catch (e) {
    final message = ErrorHandler.handleError(e);
    showToast(context, message);
  } catch (e, stackTrace) {
    final message = ErrorHandler.handleError(e, stackTrace: stackTrace);
    showToast(context, message);
  }
}
```

### 4. Escutar Erros de Autenticação (401)

```dart
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';

// No initState ou onde necessário
ApiBaseHelper.authErrorStream.listen((isUnauthorized) {
  if (isUnauthorized) {
    // Fazer logout e redirecionar para login
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
});
```

## 🎛️ Configuração de Logs

Edite `lib/core/log_config.dart`:

```dart
// Nível mínimo de log
LogConfig.minLevel = LogLevel.info; // debug, info, warning, error

// Habilitar logs no console
LogConfig.enableConsoleLog = true;

// Habilitar Sentry (produção)
LogConfig.enableSentry = true;

// Incluir stack traces
LogConfig.includeStackTrace = true;

// Mascarar dados sensíveis
LogConfig.maskSensitiveData = true;
```

## 🔐 Mascaramento de Dados Sensíveis

O sistema automaticamente mascara campos sensíveis nos logs:
- password, senha
- token, jwt, authorization
- cpf, cnpj
- cartao, cvv

Adicione mais campos em `LogConfig.sensitiveFields`.

## 📊 Interceptors do Dio

O `ApiBaseHelper` agora inclui 3 interceptors:

1. **LoggingInterceptor**: Loga todas as requisições/respostas
2. **AuthInterceptor**: Detecta 401 e emite evento
3. **ErrorInterceptor**: Converte erros em ApiException

## 🚀 Ativar Sentry

Veja `SENTRY_SETUP.md` para instruções completas.

Resumo:
1. Adicione `sentry_flutter: ^7.0.0` ao pubspec.yaml
2. Execute: `flutter run --dart-define=SENTRY_DSN=https://seu-dsn@sentry.io/projeto`
3. Descomente código em `lib/core/sentry_config.dart`

## ✅ Benefícios

- ✅ Logs estruturados e centralizados
- ✅ Erros tipados (ApiException)
- ✅ Mensagens amigáveis para usuários
- ✅ Detecção automática de 401
- ✅ Mascaramento de dados sensíveis
- ✅ Suporte opcional ao Sentry
- ✅ Interceptors automáticos no Dio
- ✅ Fácil de estender e manter

## 📝 Exemplos de Uso por Service

### UserService
```dart
Future<Usuario?> login(LoginRequest login) async {
  try {
    final result = await _userRepository.autenticaUser(null, null, login);
    return result;
  } on ApiException catch (e) {
    Logger.logError(e, meta: {'email': login.email});
    rethrow;
  } catch (e, stackTrace) {
    Logger.logError(e, stackTrace: stackTrace);
    throw ApiException(
      message: ErrorHandler.handleError(e, stackTrace: stackTrace),
      originalError: e,
    );
  }
}
```

### AdminService
```dart
Future<void> changeStatusUser(int userId, int status) async {
  try {
    await _adminRepository.updateStatus(userId, status);
    Logger.logInfo('Status atualizado', meta: {'userId': userId, 'status': status});
  } on ApiException catch (e) {
    Logger.logError(e, meta: {'userId': userId});
    rethrow;
  }
}
```

### LocationService
```dart
Future<void> updateLocation(double lat, double lng) async {
  try {
    await _repository.updateLocation(lat, lng);
  } catch (e, stackTrace) {
    Logger.logError(
      e,
      stackTrace: stackTrace,
      meta: {'lat': lat, 'lng': lng},
      tag: 'LocationService',
    );
    throw ApiException(
      message: 'Erro ao atualizar localização',
      originalError: e,
    );
  }
}
```

## 🔍 Verificando Logs

### Em Debug
Os logs aparecem no console do Flutter com tags e metadados.

### Em Produção
- Console logs (se habilitado)
- Sentry (se configurado)
- Logs locais do dispositivo

## 🛠️ Manutenção

Para adicionar novos campos sensíveis:
```dart
// Em lib/core/log_config.dart
static const List<String> sensitiveFields = [
  // ... campos existentes
  'novoCampoSensivel',
];
```

Para adicionar novos tipos de erro:
```dart
// Em lib/core/errors/api_exception.dart
// Adicione novos casos no factory fromDioError
```

