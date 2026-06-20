import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Lokasi Zam Zam Laundry (Indomaret Fresh Podomoro Park Bandung)
  static const double laundryLatitude = -6.9805;
  static const double laundryLongitude = 107.6431;

  double? _distanceInKm;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndDistance();
  }

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndDistance() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Layanan GPS tidak aktif.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationError = 'Akses lokasi ditolak.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Akses lokasi ditolak permanen.';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        laundryLatitude,
        laundryLongitude,
      );

      if (!mounted) return;
      setState(() {
        _distanceInKm = distanceInMeters / 1000;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Gagal memuat lokasi: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _openMapChooser() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buka Peta Navigasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih aplikasi untuk melihat rute ke Zam Zam Laundry',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.sage,
                    child: Icon(Icons.map_outlined, color: AppColors.ink),
                  ),
                  title: const Text('Google Maps (Aplikasi)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Rekomendasi jika aplikasi terinstall'),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri googleMapsUrl = Uri.parse(
                      'google.navigation:q=$laundryLatitude,$laundryLongitude&mode=d',
                    );
                    if (await canLaunchUrl(googleMapsUrl)) {
                      await launchUrl(googleMapsUrl);
                    } else {
                      final Uri webUrl = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$laundryLatitude,$laundryLongitude',
                      );
                      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.blush,
                    child: Icon(Icons.open_in_browser_rounded, color: AppColors.ink),
                  ),
                  title: const Text('Browser Web', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Membuka rute di tab browser baru'),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri webUrl = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$laundryLatitude,$laundryLongitude',
                    );
                    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
      floatingActionButton: index == 2
          ? FloatingActionButton(
              onPressed: () => _showCreateOrderDialog(app),
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: index,
        onTap: (value) {
          setState(() => index = value);
          app.isChatActive = (value == 3);
        },
        items: [
          const AppNavItem(icon: Icons.home_outlined, label: 'Home'),
          const AppNavItem(icon: Icons.sell_outlined, label: 'Harga'),
          const AppNavItem(icon: Icons.local_laundry_service_outlined, label: 'Tracking'),
          AppNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            hasBadge: app.hasUnreadMessages,
          ),
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
        title: 'Lokasi Laundry',
        subtitle: 'Kunjungi toko kami atau cek jarak pengantaran.',
      ),
      const SizedBox(height: 10),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.sage,
                  child: Icon(Icons.location_on_rounded, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zam Zam Laundry',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jl. Podomoro Park No.Kav N 2, Lengkong, Kec. Bojongsoang, Kabupaten Bandung, Jawa Barat 40287',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (_isLoadingLocation) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.rose),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mengukur jarak...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ] else if (_locationError != null) ...[
                    const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(fontSize: 13, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _fetchLocationAndDistance,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ),
                    ),
                  ] else if (_distanceInKm != null) ...[
                    const Icon(Icons.directions_run_rounded, color: AppColors.rose, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jarak dari lokasi Anda: ${_distanceInKm!.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: AppColors.rose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _fetchLocationAndDistance,
                    ),
                  ] else ...[
                    const Icon(Icons.location_off_rounded, color: Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Jarak tidak diketahui.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: _fetchLocationAndDistance,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Cek Jarak',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openMapChooser,
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: const Text('Petunjuk Arah (Google Maps)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Future<void> _showCreateOrderDialog(AppState app) async {
    int? selectedServiceId = app.activeServices.isNotEmpty ? app.activeServices.first.id : null;
    final qtyController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedService = selectedServiceId != null ? app.getService(selectedServiceId!) : null;
            final qty = double.tryParse(qtyController.text.trim()) ?? 0;
            final estimatedPrice = selectedService != null ? selectedService.price * qty : 0.0;

            return AlertDialog(
              title: const Text('Buat Pesanan Laundry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (app.activeServices.isEmpty)
                      Text(
                        'Belum ada layanan aktif saat ini.',
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
                      decoration: const InputDecoration(
                        labelText: 'Estimasi Kuantitas/Berat',
                        hintText: 'Masukkan berat/jumlah pengerjaan',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan',
                        hintText: 'Misal: Setrika rapi, wangi floral, dll.',
                      ),
                    ),
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
                          const Text('Estimasi Total:', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            app.currency(estimatedPrice),
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
                  onPressed: (selectedServiceId == null || qty <= 0)
                      ? null
                      : () {
                          final user = app.currentUser;
                          if (user == null) return;
                          Navigator.pop(context);
                          app.createOrder(
                            customerId: user.id,
                            serviceId: selectedServiceId!,
                            quantity: qty,
                            totalPrice: estimatedPrice,
                            notes: notesController.text,
                            isPaid: false,
                          );
                        },
                  child: const Text('Pesan Sekarang'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
