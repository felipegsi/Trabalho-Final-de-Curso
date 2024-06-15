import 'package:flutter/material.dart';
import 'package:projeto_proj/views/screens/home/order_screen.dart';

import '../../../services/network_service.dart';
import '../../../models/driver.dart';
import '../../../themes/app_theme.dart';
import '../profile/profile_screen.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NetworkService _networkService = NetworkService();

    return Drawer(
      child: FutureBuilder<Driver?>(
        future: _networkService.viewProfile(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            print('Error fetching data: ${snapshot.error}');
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          else if (snapshot.data == null) {
            return Text('No profile data available');
          }

          Driver user = snapshot.data!;
          return Container(
            color: backgroundColor, // Assegure que esta cor está definida nos seus temas
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ProfileScreen()));
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
                              user.name, // Nome do usuário
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              user.email, // Email do usuário
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
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_offer_outlined),
                  title: Text('Promotions'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Subscriptions'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('My Orders'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Messages'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Adicionar navegação ou função de clique aqui
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help_outline_outlined),
                  title: Text('Help'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
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
