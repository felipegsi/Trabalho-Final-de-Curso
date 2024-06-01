import 'dart:ffi';

import 'package:flutter/material.dart';
import '../../../models/driver.dart';
import '../../../services/network_service.dart';


class SearchingDriverScreen extends StatefulWidget {
  final Long? orderId;

  const SearchingDriverScreen({
    super.key,
    required this.orderId,
  });

  @override
  _SearchingDriverScreenState createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  final NetworkService _networkService = NetworkService();

// _buildDriver
  Widget _buildDriver(Driver driver) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Driver: ${driver.name}'),
          Text('Phone: ${driver.birthdate}'),
          Text('Vehicle: ${driver.city}'),
          Text('License Plate: ${driver.email}'),
        ],
      ),
    );
  }

  // metodo para construir a AppBar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Parking Lots - List', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.deepPurple,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            //onSelected: (value) => _sortParks(_loadParks() as List<Park>, value),
            itemBuilder: (BuildContext context) {
              return {'Last Updated', 'Name', 'Current Occupation'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // Constrói a barra de aplicativo
      body: FutureBuilder<Driver>(
        future: _networkService.assignOrderToDriver(widget.orderId, context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Exibe um indicador de progresso enquanto carrega
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Exibe uma mensagem de erro se ocorrer um erro
          } else if (!snapshot.hasData ) {
            return Center(child: Text('No driver found')); // Exibe uma mensagem se não houver dados
          } else {
            // retornar o driver
            return _buildDriver(snapshot.data!); // Constrói a lista de parques

          }
        },
      ),
    );
  }
}
