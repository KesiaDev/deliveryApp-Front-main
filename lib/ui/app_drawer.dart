import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/theme_controller.dart';
import 'package:delivery_front/core/app_session.dart';
import 'theme_components.dart';
import 'dart:convert';

class AppDrawer extends StatelessWidget {
  final Usuario? user;
  final UserService? userService;
  final VoidCallback? onLogout;

  const AppDrawer({
    Key? key,
    this.user,
    this.userService,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? ApiBaseHelper.userSessao;
    final nome = currentUser?.desNome ?? "Motorista";
    final email = currentUser?.usuario ?? "motorista@foo.com";
    final fotoPerfil = currentUser?.usuarioResp?.motoristas?.first.desFotoPerfil;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kPrimaryRed,
                    backgroundImage: fotoPerfil != null && fotoPerfil.isNotEmpty
                        ? MemoryImage(base64.decode(fotoPerfil))
                        : null,
                    child: fotoPerfil == null || fotoPerfil.isEmpty
                        ? Text(
                            nome.isNotEmpty ? nome.toUpperCase().substring(0, 1) : "M",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Camera icon overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimaryRed, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: kPrimaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Name and Email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: "Dados",
                    subtitle: "Minhas informações",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.editarCadastro);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.lock_outline,
                    title: "Alterar Senha",
                    subtitle: "Alterar minha senha",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.alteracaoSenha);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.fingerprint,
                    title: "Login Biométrico",
                    subtitle: "Configurar biometria",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.biometricSettings);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: "Corridas",
                    subtitle: "Corridas em andamento",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.corridas,
                        arguments: {'indTipoDefault': -1},
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.star_outline,
                    title: "Saldos",
                    subtitle: "Meus valores",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.saldos,
                        arguments: {'userInfo': currentUser},
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_outlined,
                    title: "Relatórios",
                    subtitle: "Analytics e gráficos",
                    onTap: () {
                      Navigator.of(context).pop();
                      final user = currentUser;
                      int? codEmpresa;
                      int? codMotorista;
                      bool? isAdm;
                      
                      if (user?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
                        codMotorista = user?.usuarioResp?.motoristas?.first.codMotorista;
                      } else if (user?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
                        codEmpresa = user?.usuarioResp?.empresas?.first.codEmpresa;
                      } else if (user?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA) {
                        isAdm = true;
                      }
                      
                      Navigator.pushNamed(
                        context,
                        AppRoutes.analytics,
                        arguments: {
                          'isAdm': isAdm,
                          'codEmpresa': codEmpresa,
                          'codMotorista': codMotorista,
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: "Mensagens",
                    subtitle: "Conversas e mensagens",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.chatList,
                        arguments: {
                          'currentUserId': currentUser?.codUsuario?.toString() ?? '',
                          'currentUserName': currentUser?.desNome ?? 'Motorista',
                          'currentUserType': 'motorista',
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.history,
                    title: "Histórico",
                    subtitle: "Meu histórico de entregas",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.corridas,
                        arguments: {
                          'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
                        },
                      );
                    },
                  ),
                  // Toggle tema claro/escuro
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.themeMode,
                    builder: (context, mode, _) {
                      final isDark = mode == ThemeMode.dark;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        leading: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                        title: Text(
                          isDark ? 'Modo Claro' : 'Modo Escuro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        trailing: Switch(
                          value: isDark,
                          activeColor: kPrimaryRed,
                          onChanged: (_) => ThemeController.toggle(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Logout
            const Divider(height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.exit_to_app,
              title: "Sair",
              subtitle: null,
              onTap: () {
                // Salva root navigator ANTES do pop — drawer context desmonta após pop
                final rootCtx = Navigator.of(context, rootNavigator: true).context;
                Navigator.of(context).pop();
                if (onLogout != null) {
                  onLogout!();
                } else {
                  _showLogoutDialog(rootCtx);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: textColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: textColor.withOpacity(0.4),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AppSession.logoutComConfirmacao(context);
  }
}

