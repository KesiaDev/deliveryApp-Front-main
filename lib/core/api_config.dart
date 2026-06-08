/// Configuração da API - altere aqui para usar backend local
///
/// IMPORTANTE: Em dispositivos Android, localhost/127.0.0.1 NÃO funciona!
/// - Emulador: use http://10.0.2.2:PORTA/v1 (10.0.2.2 = localhost do host)
/// - Celular físico: use o IP da sua máquina na rede (ex: http://192.168.1.100:8080/v1)
///   Celular e PC devem estar na mesma rede Wi-Fi
class ApiConfig {
  /// Use true para conectar no backend local (desenvolvimento)
  static const bool useLocalApi = false;

  /// URL do backend local
  /// - Emulador Android: http://10.0.2.2:8080/v1
  /// - Celular físico: http://SEU_IP:8080/v1 (ex: http://192.168.1.104:8080/v1)
  static const String localApiUrl = "http://192.168.1.104:8080/v1";

  /// URL do backend em produção
  static const String productionApiUrl = "https://api.foolentregas.com.br/v1";

  /// Retorna a URL base da API
  static String get baseUrl => useLocalApi ? localApiUrl : productionApiUrl;
}
