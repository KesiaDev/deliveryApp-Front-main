/// Rotas nomeadas do aplicativo Fool Delivery
/// 
/// Centraliza todas as rotas do app para facilitar navegação e manutenção
class AppRoutes {
  AppRoutes._();

  // Rotas principais
  static const String splash = '/';
  static const String login = '/login';
  static const String escolhaPerfil = '/escolha-perfil';
  static const String home = '/home';
  static const String homeAdmin = '/home-admin';
  static const String homeEmpresa = '/home-empresa';

  // Rotas de cadastro e autenticação
  static const String cadastro = '/cadastro';
  static const String termos = '/termos';
  static const String editarCadastro = '/editar-cadastro';
  static const String recuperacaoSenha = '/recuperacao-senha';
  static const String alteracaoSenha = '/alteracao-senha';
  static const String biometricSettings = '/biometric-settings';

  // Rotas de funcionalidades
  static const String saldos = '/saldos';
  static const String corridas = '/corridas';
  static const String corridasEmpresa = '/corridas-empresa';
  static const String infoCorrida = '/info-corrida';
  static const String novaCorrida = '/nova-corrida';
  static const String analytics = '/analytics';

  // Rotas administrativas
  static const String adminEmpresas = '/admin/empresas';
  static const String adminMotoristas = '/admin/motoristas';
  static const String adminTaxas = '/admin/taxas';
  static const String configSistema = '/admin/config-sistema';

  // Rotas dos novos módulos (isolados)
  // Chat
  static const String chatList = '/chat/list';
  static const String chat = '/chat';

  // Rating
  static const String rating = '/rating';
  static const String ratingHistory = '/rating/history';

  // Tracking
  static const String liveTracking = '/tracking/live';

  // Payments
  static const String paymentMethodSelection = '/payment/method';
  static const String paymentReview = '/payment/review';

  // Mapa do Motorista
  static const String map = '/map';

  // Navegação in-app do motorista
  static const String motoristaNavigation = '/navigation/motorista';

  // Monitor de corrida ao vivo + simulador
  static const String corridaMonitor = '/corrida/monitor';
  static const String rideSimulator = '/corrida/simulator';

  // Pagamentos avançados
  static const String carteiraFool = '/pagamentos/carteira';
  static const String boletosSemanais = '/pagamentos/boletos';
  static const String empresaPaymentConfig = '/pagamentos/config';

  // Cobrança na Entrega (CoD)
  static const String pendenciasMotorista = '/cod/pendencias';
  static const String confirmacaoCobranca = '/cod/confirmacao';
}

