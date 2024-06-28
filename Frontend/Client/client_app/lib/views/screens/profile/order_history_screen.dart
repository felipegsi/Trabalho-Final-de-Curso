// order_history_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../api/order_api.dart';
import '../../../models/order.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _orderHistory;

  @override
  void initState() {
    super.initState();
    _orderHistory = _loadOrderHistory();
  }

  Future<List<Order>> _loadOrderHistory() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    return await orderApi.getOrderHistory();
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case 'SMALL':
        return Icon(Icons.motorcycle, color: Colors.white);
      case 'MEDIUM':
        return Icon(Icons.directions_car, color: Colors.white);
      case 'LARGE':
        return Icon(Icons.local_shipping, color: Colors.white);
      case 'MOTORIZED':
        return Icon(Icons.train, color: Colors.white);
      default:
        return Icon(Icons.help_outline, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Order>>(
        future: _orderHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No orders found.'));
          } else {
            List<Order> orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                Order order = orders[index];
                return Card(
                  color: Colors.grey[200],
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.black87,
                      child: _getCategoryIcon(order.category),
                    ),
                    title: Text(
                      'Order ${order.id}',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      order.status ?? 'Unknown Status',
                      style: TextStyle(color: Colors.black),
                    ),
                    trailing: Text(
                      order.value != null
                          ? '€${order.value!.toStringAsFixed(2)}'
                          : '€0.00',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(order: order),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
