import 'package:flutter/material.dart';
import 'package:projeto_proj/views/screens/profile/my_deliveries_screen.dart';
import 'package:provider/provider.dart';
import '../../../api/profile_api.dart';
import '../../../themes/app_theme.dart';
import '../profile/profile_screen.dart';
import '../archive/order_screen.dart';
import '../archive/map_sample.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Carrega os dados do perfil na inicialização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileApi>(context, listen: false).fetchProfile();
    });

    return Drawer(
      child: Consumer<ProfileApi>(
        builder: (context, profileApi, child) {
          if (profileApi.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (profileApi.hasError) {
            return Center(child: Text('An error occurred: ${profileApi.errorMessage}'));
          } else if (profileApi.driver == null) {
            return const Center(child: Text('No profile data available'));
          }

          final driver = profileApi.driver!;

          return Container(
            color: backgroundColor, // Assegure que esta cor está definida nos seus temas
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: DrawerHeader(
                    decoration: const BoxDecoration(
                      color: backgroundColor,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 30,
                          child: Text(
                            '${driver.name[0]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name, // Nome do usuário
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              driver.email, // Email do usuário
                              style: const TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Payment'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: const Text('Promotions'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Subscriptions'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('My Deliveries'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyDeliveriesScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Messages'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_outlined),
                  title: const Text('Help'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
