import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int index = 0;
  final chatController = TextEditingController();
  final reportSearchController = TextEditingController();
  final customerSearchController = TextEditingController();

  @override
  void dispose() {
    chatController.dispose();
    reportSearchController.dispose();
    customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pages = [
      _dashboard(app),
      _orders(app),
      _services(app),
      _customers(app),
      _reports(app),
      _chat(app),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin ZAMZAM'),
        actions: [
          IconButton(
            onPressed: app.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: index,
        onTap: (value) {
          setState(() => index = value);
          app.isChatActive = (value == 5);
        },
        items: [
          const AppNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          const AppNavItem(icon: Icons.sync_alt_outlined, label: 'Status'),
          const AppNavItem(icon: Icons.local_offer_outlined, label: 'Layanan'),
          const AppNavItem(icon: Icons.people_outline, label: 'Pelanggan'),
          const AppNavItem(icon: Icons.receipt_long_outlined, label: 'Laporan'),
          AppNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            hasBadge: app.hasUnreadMessages,
          ),
        ],
      ),
    );
  }

  Widget _pageList(List<Widget> children, AppState app) {
    return RefreshIndicator(
      onRefresh: () => app.refreshAllData(),
      color: AppColors.rose,
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: children,
      ),
    );
  }

  Widget _dashboard(AppState app) {
    final latestOrders = app.allOrdersSorted.take(3).toList();

    return _pageList([
      GradientBanner(
        title: 'Dashboard Admin',
        subtitle: 'Pantau operasional laundry, update status, dan lihat ringkasan bisnis harian.',
        trailing: const Icon(Icons.space_dashboard_rounded, color: Colors.white, size: 42),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          StatCard(
            icon: Icons.people_outline,
            title: 'Pelanggan',
            value: '${app.customers.length}',
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: Icons.local_laundry_service_outlined,
            title: 'Order Aktif',
            value: '${app.activeOrdersCount}',
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          StatCard(
            icon: Icons.payments_outlined,
            title: 'Omzet',
            value: app.currency(app.totalRevenue),
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: Icons.warning_amber_rounded,
            title: 'Belum Bayar',
            value: app.currency(app.unpaidRevenue),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const SectionHeader(
        title: 'Order Terbaru',
        subtitle: 'Tiga transaksi terbaru yang perlu dipantau.',
      ),
      const SizedBox(height: 10),
      ...latestOrders.map(
        (order) {
          final service = app.getService(order.serviceId);
          final customer = app.getUser(order.customerId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.sage,
                    child: Icon(Icons.receipt_long_outlined, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${customer.name} • ${service.name}'),
                        const SizedBox(height: 4),
                        Text('Dibuat ${app.shortDate(order.createdAt)}'),
                      ],
                    ),
                  ),
                  PillChip(text: order.status.label, color: AppColors.blush.withOpacity(0.45)),
                ],
              ),
            ),
          );
        },
      ),
    ], app);
  }

  Widget _orders(AppState app) {
    final orders = app.allOrdersSorted;

    return _pageList([
      SectionHeader(
        title: 'Update Status Laundry',
        subtitle: 'Admin dapat memperbarui status pesanan pelanggan secara langsung.',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateOrderDialog(app),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Tambah'),
        ),
      ),
      const SizedBox(height: 10),
      ...orders.map(
        (order) {
          final service = app.getService(order.serviceId);
          final customer = app.getUser(order.customerId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.invoiceNo,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text('${customer.name} • ${customer.phone}'),
                            Text(service.name),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PillChip(
                            text: order.paymentStatus.label,
                            color: order.paymentStatus == PaymentStatus.paid
                                ? AppColors.sage
                                : Colors.orange.shade100,
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 20),
                            onPressed: () => _confirmDeleteOrder(context, app, order),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Qty: ${order.quantity} ${service.unit}'),
                  Text('Total: ${app.currency(order.totalPrice)}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<OrderStatus>(
                          value: order.status,
                          decoration: const InputDecoration(labelText: 'Status Laundry'),
                          items: OrderStatus.values
                              .map(
                                (status) => DropdownMenuItem<OrderStatus>(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              app.updateOrderStatus(order.id, value);
                            }
                          },
                        ),
                      ),
                      if (order.paymentStatus == PaymentStatus.unpaid) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sage,
                            foregroundColor: AppColors.ink,
                          ),
                          onPressed: () => _showPaymentDialog(app, order),
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: const Text('Bayar'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ], app);
  }

  Widget _services(AppState app) {
    final items = [...app.services]..sort((a, b) => a.id.compareTo(b.id));

    return _pageList([
      SectionHeader(
        title: 'Manajemen Layanan',
        subtitle: 'Tambah, ubah, atau nonaktifkan layanan dan harga laundry.',
        action: ElevatedButton.icon(
          onPressed: () => _showServiceDialog(app),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
      const SizedBox(height: 10),
      ...items.map(
        (service) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    PillChip(
                      text: service.isActive ? 'Aktif' : 'Nonaktif',
                      color: service.isActive ? AppColors.sage : Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(service.description),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillChip(
                      text: '${app.currency(service.price)} / ${service.unit}',
                      color: AppColors.blush.withOpacity(0.45),
                    ),
                    PillChip(
                      text: '${service.estimateDays} hari',
                      color: AppColors.snow,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showServiceDialog(app, service: service),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Ubah'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => app.toggleServiceActive(service.id),
                        icon: const Icon(Icons.power_settings_new),
                        label: Text(service.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ], app);
  }

  Widget _customers(AppState app) {
    final customers = app.customers;
    final searchQuery = customerSearchController.text.trim().toLowerCase();
    final filteredCustomers = customers.where((c) {
      return c.name.toLowerCase().contains(searchQuery) ||
          c.email.toLowerCase().contains(searchQuery) ||
          c.phone.toLowerCase().contains(searchQuery);
    }).toList();

    return _pageList([
      const SectionHeader(
        title: 'Data Pelanggan',
        subtitle: 'Daftar pelanggan beserta ringkasan transaksi mereka.',
      ),
      const SizedBox(height: 10),
      TextField(
        controller: customerSearchController,
        decoration: InputDecoration(
          hintText: 'Cari nama, email, atau telepon...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: customerSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    setState(() {
                      customerSearchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
      const SizedBox(height: 12),
      if (filteredCustomers.isEmpty)
        const EmptyPlaceholder(
          title: 'Tidak Ada Pelanggan',
          subtitle: 'Tidak menemukan pelanggan yang cocok dengan pencarian.',
          icon: Icons.person_off_outlined,
        ),
      ...filteredCustomers.map(
        (customer) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.blush,
                  child: Icon(Icons.person_outline, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(customer.email),
                      Text(customer.phone),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PillChip(
                            text: '${app.ordersCountByCustomer(customer.id)} order',
                            color: AppColors.sage,
                          ),
                          PillChip(
                            text: app.currency(app.spendingByCustomer(customer.id)),
                            color: AppColors.blush.withOpacity(0.45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ], app);
  }

  Widget _reports(AppState app) {
    final transactions = [...app.transactions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final searchQuery = reportSearchController.text.trim().toLowerCase();
    final filteredTransactions = transactions.where((transaction) {
      final customer = app.getUser(transaction.customerId);
      return customer.name.toLowerCase().contains(searchQuery);
    }).toList();

    return _pageList([
      const SectionHeader(
        title: 'Laporan Transaksi',
        subtitle: 'Ringkasan pemasukan dan histori pembayaran laundry.',
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          StatCard(
            icon: Icons.attach_money_outlined,
            title: 'Omzet Lunas',
            value: app.currency(app.totalRevenue),
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: Icons.check_circle_outline,
            title: 'Order Selesai',
            value: '${app.completedOrdersCount}',
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          StatCard(
            icon: Icons.pending_actions_outlined,
            title: 'Order Aktif',
            value: '${app.activeOrdersCount}',
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Piutang',
            value: app.currency(app.unpaidRevenue),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const SectionHeader(title: 'Detail Transaksi'),
      const SizedBox(height: 10),
      TextField(
        controller: reportSearchController,
        decoration: InputDecoration(
          hintText: 'Cari nama pelanggan...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: reportSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    setState(() {
                      reportSearchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
      const SizedBox(height: 12),
      if (filteredTransactions.isEmpty)
        const EmptyPlaceholder(
          title: 'Tidak Ada Transaksi',
          subtitle: 'Tidak menemukan transaksi untuk nama pelanggan tersebut.',
          icon: Icons.search_off_rounded,
        ),
      ...filteredTransactions.map(
        (transaction) {
          final customer = app.getUser(transaction.customerId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: transaction.status == PaymentStatus.paid
                        ? AppColors.sage
                        : Colors.orange.shade100,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: transaction.status == PaymentStatus.paid ? AppColors.ink : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(customer.name),
                        Text('Metode: ${transaction.paymentMethod}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        app.currency(transaction.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(transaction.status.label),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ], app);
  }

  Widget _chat(AppState app) {
final rooms = app.sortedRooms;
final selectedRoomId =
app.selectedAdminRoomId ?? (rooms.isNotEmpty ? rooms.first.id : null);

if (rooms.isEmpty || selectedRoomId == null) {
return const EmptyPlaceholder(
title: 'Belum Ada Room Chat',
subtitle: 'Room percakapan pelanggan akan muncul di sini.',
icon: Icons.chat_outlined,
);
}

final selectedRoom = rooms.firstWhere(
(room) => room.id == selectedRoomId,
);

final messages = app.messagesForRoom(selectedRoomId);

return Column(
children: [
const SectionHeader(
title: 'Chat Pelanggan',
subtitle:
'Balas pertanyaan pelanggan secara langsung dari aplikasi.',
),
const SizedBox(height: 10),
  SizedBox(
    height: 70,
    child: ListView.separated(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final isSelected = room.id == selectedRoomId;

        return GestureDetector(
          onTap: () => app.selectAdminRoom(room.id),
          child: Container(
            width: 210,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sage : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rose.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.grey.shade800 : Colors.grey.shade700,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: isSelected ? AppColors.rose : Colors.red.shade400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _confirmDeleteChat(context, app, room);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),

  const SizedBox(height: 10),

  // Isi pesan room yang sedang dipilih.
  Expanded(
    child: SoftCard(
      child: messages.isEmpty
          ? const EmptyPlaceholder(
              title: 'Belum Ada Pesan',
              subtitle: 'Mulai balas pesan pelanggan dari sini.',
              icon: Icons.mark_chat_unread_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isAdmin =
                    message.senderId == app.currentUser?.id;

                return Align(
                  alignment: isAdmin
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppColors.blush
                          : AppColors.snow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.text),
                        const SizedBox(height: 6),
                        Text(
                          app.shortTime(message.sentAt),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
  ),

  const SizedBox(height: 10),

  // Input balasan admin.
  Row(
    children: [
      Expanded(
        child: TextField(
          controller: chatController,
          decoration: InputDecoration(
            hintText: 'Balas ${selectedRoom.title}...',
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.rose,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          if (chatController.text.trim().isEmpty) {
            return;
          }

          app.sendMessage(
            roomId: selectedRoom.id,
            text: chatController.text,
          );

          chatController.clear();
        },
        icon: const Icon(Icons.send_rounded),
      ),
    ],
  ),

  const SizedBox(height: 8),
],

);
}
  Future<void> _showServiceDialog(AppState app, {LaundryService? service}) async {
    final nameController = TextEditingController(text: service?.name ?? '');
    final descriptionController = TextEditingController(text: service?.description ?? '');
    final priceController = TextEditingController(text: service?.price.toString() ?? '');
    final unitController = TextEditingController(text: service?.unit ?? 'kg');
    final estimateController = TextEditingController(text: service?.estimateDays.toString() ?? '1');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service == null ? 'Tambah Layanan' : 'Ubah Layanan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama layanan')),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
              ),
              const SizedBox(height: 10),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Satuan')),
              const SizedBox(height: 10),
              TextField(
                controller: estimateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estimasi hari'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final unit = unitController.text.trim().isEmpty ? 'kg' : unitController.text.trim();
              final estimateDays = int.tryParse(estimateController.text.trim()) ?? 1;

              if (service == null) {
                await app.addService(
                  name: name,
                  description: description,
                  price: price,
                  unit: unit,
                  estimateDays: estimateDays,
                );
              } else {
                await app.updateService(
                  id: service.id,
                  name: name,
                  description: description,
                  price: price,
                  unit: unit,
                  estimateDays: estimateDays,
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateOrderDialog(AppState app) async {
    int? selectedCustomerId = app.customers.isNotEmpty ? app.customers.first.id : null;
    int? selectedServiceId = app.activeServices.isNotEmpty ? app.activeServices.first.id : null;
    final qtyController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    bool isPaid = false;
    String paymentMethod = 'Cash';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedService = selectedServiceId != null ? app.getService(selectedServiceId!) : null;
            final qty = double.tryParse(qtyController.text.trim()) ?? 0;
            final totalPrice = selectedService != null ? selectedService.price * qty : 0.0;

            return AlertDialog(
              title: const Text('Tambah Order Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (app.customers.isEmpty)
                      Text(
                        'Belum ada pelanggan aktif. Pelanggan harus terdaftar terlebih dahulu.',
                        style: TextStyle(color: Colors.red.shade700),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedCustomerId,
                        decoration: const InputDecoration(labelText: 'Pilih Pelanggan'),
                        items: app.customers.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedCustomerId = val);
                        },
                      ),
                    const SizedBox(height: 10),
                    if (app.activeServices.isEmpty)
                      Text(
                        'Belum ada layanan aktif.',
                        style: TextStyle(color: Colors.red.shade700),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedServiceId,
                        decoration: const InputDecoration(labelText: 'Pilih Layanan'),
                        items: app.activeServices.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.id,
                            child: Text('${s.name} (${app.currency(s.price)}/${s.unit})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedServiceId = val);
                        },
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Kuantitas/Berat'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Sudah Bayar (Lunas)'),
                      value: isPaid,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => isPaid = val ?? false);
                      },
                    ),
                    if (isPaid) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => paymentMethod = val);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.snow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Harga:', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            app.currency(totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.rose,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: (selectedCustomerId == null || selectedServiceId == null || qty <= 0)
                      ? null
                      : () {
                          Navigator.pop(context);
                          app.createOrder(
                            customerId: selectedCustomerId!,
                            serviceId: selectedServiceId!,
                            quantity: qty,
                            totalPrice: totalPrice,
                            notes: notesController.text,
                            isPaid: isPaid,
                            paymentMethod: paymentMethod,
                          );
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPaymentDialog(AppState app, LaundryOrder order) async {
    String paymentMethod = 'Cash';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pembayaran ${order.invoiceNo}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total tagihan: ${app.currency(order.totalPrice)}'),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => paymentMethod = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                await app.markOrderAsPaid(
                  orderId: order.id,
                  amount: order.totalPrice,
                  paymentMethod: paymentMethod,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Tandai Lunas'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOrder(BuildContext context, AppState app, LaundryOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Orderan'),
        content: Text('Apakah Anda yakin ingin menghapus orderan ${order.invoiceNo}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await app.deleteOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Orderan ${order.invoiceNo} berhasil dihapus')),
        );
      }
    }
  }

  Future<void> _confirmDeleteChat(BuildContext context, AppState app, ChatRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Chat Pelanggan'),
        content: Text('Apakah Anda yakin ingin menghapus seluruh riwayat chat dengan ${room.title}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await app.deleteChatRoom(room.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat dengan ${room.title} berhasil dihapus')),
        );
      }
    }
  }
}
