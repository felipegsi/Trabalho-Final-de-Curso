// custom_drawer.dart

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:teste_2/views/screens/order_confirmed/searching_driver_screen.dart';
import 'package:teste_2/views/screens/profile/profile_screen.dart';

import '../../../themes/app_theme.dart';
import 'order_screen.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: backgroundColor, // Define a cor de fundo como branco
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
              child: const DrawerHeader(
                decoration: BoxDecoration(
                  color: backgroundColor, // Define a cor de fundo como branco
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30.0,
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                      // Substitua pela URL da imagem
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(width: 10.0),
                    // Adiciona um espaço entre a imagem e os textos
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Felipe Silva', // Substitua pelo nome do usuário
                          style: TextStyle(
                            color: textColor,
                            // Define a cor do texto como preto
                            fontSize: 24, // Aumenta o tamanho do texto
                          ),
                        ),
                        Text(
                          'My Account', // Substitua pelo e-mail do usuário
                          style: TextStyle(
                            color: subTextColor,
                            // Define a cor do texto como cinza
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
            ListTile(
              leading: Icon(Icons.account_tree_outlined),
              title: Text('Send request order'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchingDriverScreen()));
                // Adicionar navegação ou função de clique aqui
              },
            ),

            // Adicione outros ListTiles conforme necessário
          ],
        ),
      ),
    );
  }
}
