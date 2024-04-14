import 'package:flutter/material.dart';
import 'package:teste_2/views/screens/estimate_order_costs_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EstimateOrderCostScreen()),
            );
          },
          child: Text('Nova Encomenda'),
        ),
      ),
    );
  }
}