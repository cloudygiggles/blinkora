import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_history_controller.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/address_model.dart';

class OrderHistoryView extends GetView<OrderHistoryController> {
  const OrderHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pemesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.pink[700]
            : Colors.pink[100],
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada riwayat pemesanan',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isTablet ? 20 : 12),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            final List<OrderItem> items = controller.orderItemsMap[order.id] ?? [];
            final Address? orderAddress = controller.orderAddressMap[order.id];

            return Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.pink[50],
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.pink),
                ),
                title: Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rp ${order.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(order.status),
                  ],
                ),
                children: [
                  const Divider(height: 1),
                  _buildAddressSection(context, orderAddress),
                  const Divider(height: 1),
                  _buildItemList(items),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tanggal: ${order.createdAt?.toLocal().toString().split(' ')[0] ?? '-'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (order.status.toLowerCase() == 'completed')
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Beli Lagi'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, Address? address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Alamat Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (address != null) ...[
            Text(
              '${address.receiverName} (${address.phoneNumber})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              '${address.address}, ${address.city}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ] else
            const Text('Alamat tidak tersedia', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildItemList(List<OrderItem> items) {
    return Column(
      children: items.map((item) {
        final productName = controller.getProductName(item.productId);
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            productName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          subtitle: Text('Jumlah: ${item.quantity}', style: const TextStyle(fontSize: 11)),
          trailing: Text(
            'Rp ${item.price.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}