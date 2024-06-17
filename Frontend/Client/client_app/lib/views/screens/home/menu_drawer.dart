// menu_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../api/profile_api.dart';
import '../../../models/client.dart';
import '../../../themes/app_theme.dart';
import '../order_confirmed/searching_driver_screen.dart';
import '../profile/profile_screen.dart';
import '../home/order_screen.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({Key? key}) : super(key: key);

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
            return Center(child: CircularProgressIndicator());
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
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30.0,
                          backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                          backgroundColor: Colors.transparent,
                        ),
                        SizedBox(width: 10.0),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
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
                  leading: Icon(Icons.payment),
                  title: Text('Payment'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_offer_outlined),
                  title: Text('Promotions'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Subscriptions'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('My Orders'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Messages'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help_outline_outlined),
                  title: Text('Help'),
                  onTap: () {
                    Navigator.pop(context);
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.border_all),
                  title: Text('Teste receber pedido'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderScreen()));
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
