import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
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
      backgroundColor: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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
                Navigator.of(context).pop();
                if (onLogout != null) {
                  onLogout!();
                } else {
                  _showLogoutDialog(context);
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.black87, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("Deseja realmente sair?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (userService != null) {
                await userService!.logoffLocalDB();
              }
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.splash,
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text("Sair"),
          ),
        ],
      ),
    );
  }
}

