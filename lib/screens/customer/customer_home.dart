import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int index = 0;
  final chatController = TextEditingController();
  final Set<int> expandedTrackingOrderIds = <int>{};

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pages = [
      _overview(app),
      _priceList(app),
      _tracking(app),
      _chat(app),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZAMZAM LAUNDRY'),
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
        onTap: (value) => setState(() => index = value),
        items: const [
          AppNavItem(icon: Icons.home_outlined, label: 'Home'),
          AppNavItem(icon: Icons.sell_outlined, label: 'Harga'),
          AppNavItem(icon: Icons.local_laundry_service_outlined, label: 'Tracking'),
          AppNavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
        ],
      ),
    );
  }

  ListView _pageList(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  Widget _overview(AppState app) {
    final user = app.currentUser;
    final orders = app.currentCustomerOrders;
    final activeOrder = orders.where((item) => item.status != OrderStatus.completed).toList();

    return _pageList([
      GradientBanner(
        title: 'Halo, ${user?.name ?? 'Pelanggan'}',
        subtitle: 'Pantau status laundry, cek harga, dan hubungi admin dari satu aplikasi.',
        trailing: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 42),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          StatCard(
            icon: Icons.local_laundry_service,
            title: 'Order Aktif',
            value: '${activeOrder.length}',
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: Icons.payments_outlined,
            title: 'Total Belanja',
            value: app.currency(app.spendingByCustomer(user?.id ?? 0)),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const SectionHeader(
        title: 'Status Terbaru',
        subtitle: 'Ringkasan laundry yang sedang berjalan.',
      ),
      const SizedBox(height: 10),
      if (orders.isNotEmpty)
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orders.first.invoiceNo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(app.getService(orders.first.serviceId).name),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PillChip(
                    text: orders.first.status.label,
                    color: AppColors.sage,
                  ),
                  PillChip(
                    text: orders.first.paymentStatus.label,
                    color: orders.first.paymentStatus == PaymentStatus.paid
                        ? AppColors.blush.withOpacity(0.55)
                        : Colors.orange.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Terakhir diperbarui: ${app.dateTime(app.logsForOrder(orders.first.id).first.changedAt)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        )
      else
        const EmptyPlaceholder(
          title: 'Belum Ada Order',
          subtitle: 'Setelah admin membuat transaksi Anda, status laundry akan muncul di sini.',
          icon: Icons.inventory_2_outlined,
        ),
      const SizedBox(height: 18),
      const SectionHeader(
        title: 'Layanan Unggulan',
        subtitle: 'Harga transparan dan estimasi pengerjaan yang jelas.',
      ),
      const SizedBox(height: 10),
      ...app.activeServices.take(3).map(
        (service) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.sage,
                child: Icon(Icons.local_offer_outlined, color: AppColors.ink),
              ),
              title: Text(service.name),
              subtitle: Text(
                '${app.currency(service.price)} / ${service.unit} • estimasi ${service.estimateDays} hari',
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _priceList(AppState app) {
    return _pageList([
      const SectionHeader(
        title: 'Daftar Harga',
        subtitle: 'Semua layanan yang aktif bisa dilihat pelanggan secara langsung.',
      ),
      const SizedBox(height: 10),
      ...app.activeServices.map(
        (service) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: PillChip(
                        text: '${app.currency(service.price)} / ${service.unit}',
                        color: AppColors.blush.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(service.description),
                const SizedBox(height: 8),
                Text(
                  'Estimasi ${service.estimateDays} hari',
                  style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _tracking(AppState app) {
    final orders = app.currentCustomerOrders;

    return _pageList([
      const SectionHeader(
        title: 'Tracking Laundry',
        subtitle: 'Lihat progres laundry Anda berdasarkan status terbaru.',
      ),
      const SizedBox(height: 10),
      if (orders.isEmpty)
        const EmptyPlaceholder(
          title: 'Belum Ada Tracking',
          subtitle: 'Pesanan laundry Anda akan tampil setelah dibuat oleh admin.',
          icon: Icons.timeline_outlined,
        ),
      ...orders.map((order) {
        final service = app.getService(order.serviceId);
        final logs = app.logsForOrder(order.id);
        final isExpanded = expandedTrackingOrderIds.contains(order.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                maintainState: true,
                initiallyExpanded: isExpanded,
                onExpansionChanged: (value) {
                  setState(() {
                    if (value) {
                      expandedTrackingOrderIds.add(order.id);
                    } else {
                      expandedTrackingOrderIds.remove(order.id);
                    }
                  });
                },
                title: Column(
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
                              Text('${service.name} • ${order.quantity} ${service.unit}'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: PillChip(
                            text: order.status.label,
                            color: AppColors.sage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Total: ${app.currency(order.totalPrice)}'),
                    Text('Pembayaran: ${order.paymentStatus.label}'),
                  ],
                ),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Riwayat Status',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...logs.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.rose,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.status.label,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(log.note),
                                const SizedBox(height: 2),
                                Text(
                                  app.dateTime(log.changedAt),
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ]);
  }

  Widget _chat(AppState app) {
    final user = app.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final room = app.ensureRoomForCustomer(user.id);
    final messages = app.messagesForRoom(room.id);

    return Column(
      children: [
        const SectionHeader(
          title: 'Chat Admin',
          subtitle: 'Ajukan pertanyaan atau cek update langsung ke admin.',
        ),
        const SizedBox(height: 10),
        SoftCard(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.sage,
                child: Icon(Icons.support_agent, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin ZAMZAM', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(app.shortTime(room.lastMessageAt)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SoftCard(
            child: messages.isEmpty
                ? const EmptyPlaceholder(
                    title: 'Belum Ada Pesan',
                    subtitle: 'Mulai percakapan dengan admin untuk bantuan laundry Anda.',
                    icon: Icons.chat_bubble_outline,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == user.id;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.blush : AppColors.snow,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.text),
                              const SizedBox(height: 6),
                              Text(
                                app.shortTime(message.sentAt),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: chatController,
                decoration: const InputDecoration(hintText: 'Tulis pesan ke admin...'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (chatController.text.trim().isEmpty) return;
                app.sendMessage(roomId: room.id, text: chatController.text);
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
}
