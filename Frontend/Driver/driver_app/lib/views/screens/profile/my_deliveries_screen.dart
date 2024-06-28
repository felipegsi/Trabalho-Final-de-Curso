import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/profile_api.dart';
import 'deliveries_details_screen.dart';

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch delivered orders when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileApi>(context, listen: false).getOrderHistory();
    });
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

  double _priceOrderToDriver(double price) {
    // 80% of the order value goes to the driver
    return price * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Deliveries'),
        backgroundColor: Colors.white,
      ),
      body: Consumer<ProfileApi>(
        builder: (context, profileApi, child) {
          if (profileApi.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (profileApi.errorMessage != null) {
            return Center(child: Text(profileApi.errorMessage!));
          } else {
            // Filter the orders to only include delivered orders
           // final deliveredOrders = profileApi.orders
             //   .where((order) => order.status == 'DELIVERED')
               // .toList();

            if (profileApi.orders.isEmpty) {
              return Center(child: Text('No deliveries found.'));
            }

            return ListView.builder(
              itemCount: profileApi.orders.length,
              itemBuilder: (context, index) {
                final order = profileApi.orders[index];
                return Card(
                  color: Colors.grey[200],
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.black,
                      child: _getCategoryIcon(order.category),
                    ),
                    title: Text(
                      order.client?.name ?? 'Unknown Client',
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
                      '€${_priceOrderToDriver(order.value!.toDouble()).toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17.0),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeliveriesDetailScreen(order: order),
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
