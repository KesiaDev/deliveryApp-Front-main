import 'package:shared_preferences/shared_preferences.dart';

/// Serviço centralizado para gerenciamento de armazenamento local
/// 
/// Fornece métodos tipados e seguros para salvar/carregar dados
/// usando SharedPreferences do Flutter.
class LocalStorageService {
  static const String _keyTokenFCM = 'token_fcm';
  
  static SharedPreferences? _prefs;
  
  /// Inicializa a instância do SharedPreferences (chamado automaticamente)
  static Future<SharedPreferences> _getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Obtém o token FCM salvo (persistido)
  static Future<String> get tokenFCM async {
    return await getString(_keyTokenFCM) ?? '';
  }

  /// Salva o token FCM (persistido)
  static Future<bool> setTokenFCM(String token) async {
    return await setString(_keyTokenFCM, token);
  }

  /// Obtém um valor String
  static Future<String?> getString(String key) async {
    final prefs = await _getInstance();
    return prefs.getString(key);
  }

  /// Salva um valor String
  static Future<bool> setString(String key, String value) async {
    final prefs = await _getInstance();
    return await prefs.setString(key, value);
  }

  /// Obtém um valor int
  static Future<int?> getInt(String key) async {
    final prefs = await _getInstance();
    return prefs.getInt(key);
  }

  /// Salva um valor int
  static Future<bool> setInt(String key, int value) async {
    final prefs = await _getInstance();
    return await prefs.setInt(key, value);
  }

  /// Obtém um valor double
  static Future<double?> getDouble(String key) async {
    final prefs = await _getInstance();
    return prefs.getDouble(key);
  }

  /// Salva um valor double
  static Future<bool> setDouble(String key, double value) async {
    final prefs = await _getInstance();
    return await prefs.setDouble(key, value);
  }

  /// Obtém um valor bool
  static Future<bool?> getBool(String key) async {
    final prefs = await _getInstance();
    return prefs.getBool(key);
  }

  /// Salva um valor bool
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await _getInstance();
    return await prefs.setBool(key, value);
  }

  /// Obtém uma lista de Strings
  static Future<List<String>?> getStringList(String key) async {
    final prefs = await _getInstance();
    return prefs.getStringList(key);
  }

  /// Salva uma lista de Strings
  static Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _getInstance();
    return await prefs.setStringList(key, value);
  }

  /// Verifica se uma chave existe
  static Future<bool> contains(String key) async {
    final prefs = await _getInstance();
    return prefs.containsKey(key);
  }

  /// Remove uma chave
  static Future<bool> remove(String key) async {
    final prefs = await _getInstance();
    return await prefs.remove(key);
  }

  /// Limpa todos os dados
  static Future<bool> clear() async {
    final prefs = await _getInstance();
    return await prefs.clear();
  }

  // Métodos de compatibilidade com código antigo (deprecated)
  @Deprecated('Use getString, getInt, getDouble, getBool ou getStringList diretamente')
  static Future<dynamic> getValue<T>(String key) async {
    final prefs = await _getInstance();
    if (T == String) {
      return prefs.getString(key) ?? '';
    } else if (T == int) {
      return prefs.getInt(key) ?? 0;
    } else if (T == double) {
      return prefs.getDouble(key) ?? 0.0;
    } else if (T == bool) {
      return prefs.getBool(key) ?? false;
    } else if (T == List) {
      return prefs.getStringList(key) ?? [];
    }
    return prefs.getString(key) ?? '';
  }

  @Deprecated('Use setString, setInt, setDouble, setBool ou setStringList diretamente')
  static Future<bool> setValue<T>(String key, dynamic value) async {
    final prefs = await _getInstance();
    if (T == String) {
      return await prefs.setString(key, value as String);
    } else if (T == int) {
      return await prefs.setInt(key, value as int);
    } else if (T == double) {
      return await prefs.setDouble(key, value as double);
    } else if (T == bool) {
      return await prefs.setBool(key, value as bool);
    } else if (T == List) {
      return await prefs.setStringList(key, value as List<String>);
    }
    return await prefs.setString(key, value.toString());
  }

  @Deprecated('Use remove() ao invés de cleanValue()')
  static Future<void> cleanValue<T>(String key) async {
    await remove(key);
  }

  @Deprecated('Use contains() ao invés de cointains()')
  static Future<bool> cointains(String key) async {
    return await contains(key);
  }
}
