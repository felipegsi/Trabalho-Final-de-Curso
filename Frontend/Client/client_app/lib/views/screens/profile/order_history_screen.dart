// order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/order_api.dart';
import '../../../models/order.dart';
/*
class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  Future<List<Order>>? _orderHistory;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    try {
      final orders = await orderApi.fetchOrderHistory();
      setState(() {
        _orderHistory = Future.value(orders);
      });
    } catch (error) {
      setState(() {
        _orderHistory = Future.error(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
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
                  child: ListTile(
                    title: Text('Order #${order.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From: ${order.origin}'),
                        Text('To: ${order.destination}'),
                        Text('Category: ${order.category}'),
                        if (order.width != null) Text('Width: ${order.width}'),
                        if (order.height != null) Text('Height: ${order.height}'),
                        if (order.length != null) Text('Length: ${order.length}'),
                        if (order.weight != null) Text('Weight: ${order.weight}'),
                        if (order.value != null) Text('Value: ${order.value}'),
                        if (order.status != null) Text('Status: ${order.status}'),
                        if (order.date != null) Text('Date: ${order.date}'),
                      ],
                    ),
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
*/