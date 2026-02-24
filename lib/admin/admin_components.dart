import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/shared/models/usuario.dart';

/// Componentes reutilizáveis modernos para área administrativa
/// Mantém consistência visual em todas as telas admin

// ============================================
// CORES PADRÃO ADMIN
// ============================================
class AdminColors {
  static const Color background = Color(0xFFF7F6FB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color primaryRed = Color(0xFFD64545);
  static const Color secondaryGray = Color(0xFF6E6E6E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF727272);
  static const Color borderColor = Color(0xFFE6E7EB);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
}

// ============================================
// APP BAR MODERNA PARA ADMIN
// ============================================
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const AdminAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AdminColors.cardWhite,
      elevation: 0,
      shadowColor: Colors.transparent,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AdminColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          : Builder(
              builder: (context) => Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: AdminColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    if (scaffoldKey != null) {
                      scaffoldKey!.currentState?.openDrawer();
                    } else {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                ),
              ),
            ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: AdminColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// ============================================
// CARD MODERNO
// ============================================
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AdminCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AdminColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return content;
  }
}

// ============================================
// KPI CARD (para dashboard)
// ============================================
class AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;

  const AdminKpiCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? AdminColors.primaryRed).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AdminColors.primaryRed,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AdminColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARD DE ATALHO RÁPIDO
// ============================================
class AdminQuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const AdminQuickActionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? AdminColors.primaryRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AdminColors.primaryRed,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.fade,
              softWrap: true,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: AdminColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.fade,
              softWrap: true,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ============================================
// STATUS BADGE
// ============================================
class AdminStatusBadge extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isBlocked;

  const AdminStatusBadge({
    Key? key,
    required this.text,
    this.isActive = false,
    this.isBlocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (isBlocked) {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    } else if (isActive) {
      backgroundColor = AdminColors.successGreen.withOpacity(0.1);
      textColor = AdminColors.successGreen;
    } else {
      backgroundColor = AdminColors.secondaryGray.withOpacity(0.1);
      textColor = AdminColors.secondaryGray;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ============================================
// DRAWER MODERNO PARA ADMIN
// ============================================
class AdminDrawer extends StatelessWidget {
  final Usuario user;
  final Function(String route, Map<String, dynamic>? arguments)? onNavigate;
  final VoidCallback? onLogout;

  const AdminDrawer({
    Key? key,
    required this.user,
    this.onNavigate,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AdminColors.cardWhite,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header com avatar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AdminColors.background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AdminColors.primaryRed,
                  child: Text(
                    (user.desNome?.toUpperCase().substring(0, 1) ?? 'A'),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  user.desNome ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user.usuario ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          _buildMenuItem(
            context,
            icon: Icons.delivery_dining_rounded,
            title: 'Corridas',
            subtitle: 'Corridas em andamento',
            visible: user.indTipo == 99,
            onTap: () {
              Navigator.pop(context);
              if (onNavigate != null) {
                onNavigate!(
                  AppRoutes.corridas,
                  {
                    'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                    'isAdm': true,
                  },
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.corridas,
                  arguments: {
                    'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                    'isAdm': true,
                  },
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Motoristas',
            subtitle: 'Motoristas na plataforma',
            visible: user.indTipo != 1,
            onTap: () {
              Navigator.pop(context);
              if (onNavigate != null) {
                onNavigate!(
                  AppRoutes.adminMotoristas,
                  {'userInfo': user},
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.adminMotoristas,
                  arguments: {'userInfo': user},
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.business_rounded,
            title: 'Empresas',
            subtitle: 'Empresas na plataforma',
            visible: user.indTipo != 1,
            onTap: () {
              Navigator.pop(context);
              if (onNavigate != null) {
                onNavigate!(
                  AppRoutes.adminEmpresas,
                  {'userInfo': user},
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.adminEmpresas,
                  arguments: {'userInfo': user},
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.history_rounded,
            title: 'Histórico',
            subtitle: user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                ? 'Meu histórico de entregas'
                : 'Histórico de chamados',
            visible: true,
            onTap: () {
              Navigator.pop(context);
              if (onNavigate != null) {
                onNavigate!(
                  AppRoutes.corridas,
                  {
                    'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
                    'isAdm': true,
                  },
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.corridas,
                  arguments: {
                    'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
                    'isAdm': true,
                  },
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.analytics_rounded,
            title: 'Relatórios e Analytics',
            subtitle: 'Gráficos e estatísticas',
            visible: true,
            onTap: () {
              Navigator.pop(context);
              int? codEmpresa;
              int? codMotorista;
              bool? isAdm;
              
              if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
                codMotorista = user.usuarioResp?.motoristas?.first.codMotorista;
              } else if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
                codEmpresa = user.usuarioResp?.empresas?.first.codEmpresa;
              } else if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA) {
                isAdm = true;
              }
              
              if (onNavigate != null) {
                onNavigate!(
                  AppRoutes.analytics,
                  {
                    'isAdm': isAdm,
                    'codEmpresa': codEmpresa,
                    'codMotorista': codMotorista,
                  },
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.analytics,
                  arguments: {
                    'isAdm': isAdm,
                    'codEmpresa': codEmpresa,
                    'codMotorista': codMotorista,
                  },
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_rounded,
            title: 'Parâmetros do sistema',
            subtitle: 'Gerenciar corridas',
            visible: user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA,
            onTap: () async {
              Navigator.pop(context);
              // Busca config e navega
              try {
                final userService = UserService();
                final config = await userService.buscarConfigSys();
                if (onNavigate != null) {
                  onNavigate!(
                    AppRoutes.configSistema,
                    {'usuarioEdicao': config},
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.configSistema,
                    arguments: {'usuarioEdicao': config},
                  );
                }
              } catch (e) {
                // Se der erro, cria com valores padrão
                final config = ConfigSys(
                  vlrKmRodado: 0.0,
                  vlrPercentualDescontoMotorista: 0.0,
                  vlrTaxaApp: 0.0,
                  raioBuscaCorridas: 25,
                );
                if (onNavigate != null) {
                  onNavigate!(
                    AppRoutes.configSistema,
                    {'usuarioEdicao': config},
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.configSistema,
                    arguments: {'usuarioEdicao': config},
                  );
                }
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.percent_rounded,
            title: 'Parâmetros de taxas',
            subtitle: 'Gerenciar taxas de corrida',
            visible: user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA,
            onTap: () {
              Navigator.pop(context);
              final userEnvio = Usuario();
              if (onNavigate != null) {
                onNavigate!(
                  AppRoutes.adminTaxas,
                  {'userInfo': userEnvio},
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.adminTaxas,
                  arguments: {'userInfo': userEnvio},
                );
              }
            },
          ),
          Divider(height: 32, thickness: 1, color: AdminColors.borderColor),
          _buildMenuItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Sair',
            subtitle: '',
            visible: true,
            isLogout: true,
            onTap: () async {
              Navigator.pop(context);
              if (onLogout != null && context.mounted) {
                // Aguarda um frame para garantir que o Navigator não está locked
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted && onLogout != null) {
                    onLogout!();
                  }
                });
              }
            },
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool visible,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    if (!visible) return SizedBox.shrink();

    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? AdminColors.primaryRed : AdminColors.secondaryGray,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? AdminColors.primaryRed : AdminColors.textPrimary,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AdminColors.textSecondary,
              ),
            )
          : null,
      trailing: isLogout
          ? null
          : Icon(Icons.chevron_right_rounded, color: AdminColors.secondaryGray),
      onTap: onTap,
    );
  }
}

// ============================================
// EMPTY STATE
// ============================================
class AdminEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const AdminEmptyState({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon = Icons.motorcycle_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AdminColors.secondaryGray.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

