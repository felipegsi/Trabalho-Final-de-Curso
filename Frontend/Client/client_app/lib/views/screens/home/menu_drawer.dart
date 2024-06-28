// menu_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teste_2/views/screens/profile/order_history_screen.dart';

import '../../../api/profile_api.dart';
import '../../../models/client.dart';
import '../../../themes/app_theme.dart';
import '../profile/profile_screen.dart';
import '../home/order_screen.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileApi = Provider.of<ProfileApi>(context, listen: false);
    await profileApi.viewProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<ProfileApi>(
        builder: (context, profileApi, child) {
          if (profileApi.client == null) {
            return const Center(child: CircularProgressIndicator());
          }

          Client user = profileApi.client!;
          return Container(
            color: backgroundColor,
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
                            '${user.name[0]}',
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
                              user.name,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              user.email,
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
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: const Text('Promotions'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Subscriptions'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('My Orders'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen()));
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Messages'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_outlined),
                  title: const Text('Help'),
                  onTap: () {
                    Navigator.pop(context);
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
