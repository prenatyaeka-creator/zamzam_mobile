import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/service_model.dart';
import 'models/order_model.dart';

void main() => runApp(const ZamzamApp());

class ZamzamApp extends StatelessWidget {
  const ZamzamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zamzam Laundry',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFD4AF37), // Gold
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  int _selectedIndex = 0; // Untuk navigasi bawah

  // Daftar Widget Halaman
  static final List<Widget> _pages = [
    const ServiceListSection(),
    const OrderHistorySection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFFD4AF37),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wash), label: "Layanan"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Status"),
        ],
      ),
    );
  }
}

// --- BAGIAN 1: DAFTAR LAYANAN ---
class ServiceListSection extends StatefulWidget {
  const ServiceListSection({super.key});

  @override
  State<ServiceListSection> createState() => _ServiceListSectionState();
}

class _ServiceListSectionState extends State<ServiceListSection> {
  double weight = 1.0;

  void _showOrderDialog(ServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(service.serviceName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Rp ${service.price} / ${service.unit}", style: const TextStyle(color: Color(0xFFD4AF37))),
              const SizedBox(height: 20),
              Text("Estimasi: ${weight.round()} ${service.unit}"),
              Slider(
                value: weight, min: 1, max: 20, divisions: 19,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (val) => setModalState(() => weight = val),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Bayar:"),
                  Text("Rp ${(service.price * weight).toInt()}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => Navigator.pop(context),
                child: const Text("TUTUP"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 120, pinned: true,
          flexibleSpace: FlexibleSpaceBar(title: Text("ZAMZAM LAUNDRY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))),
          backgroundColor: Colors.white,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<List<ServiceModel>>(
              future: ApiService().fetchServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final s = snapshot.data![index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.auto_awesome, color: Color(0xFFD4AF37))),
                        title: Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Rp ${s.price}/${s.unit}"),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _showOrderDialog(s),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        )
      ],
    );
  }
}

// --- BAGIAN 2: RIWAYAT PESANAN ---
class OrderHistorySection extends StatelessWidget {
  const OrderHistorySection({super.key});

  Color _getStatusColor(String s) {
    if (s == 'done') return Colors.green;
    if (s == 'process') return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Status Laundry"), backgroundColor: Colors.white),
      body: FutureBuilder<List<OrderModel>>(
        future: ApiService().fetchOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: () async => (context as Element).markNeedsBuild(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final o = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    title: Text(o.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${o.customerName} - ${o.serviceName}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Rp ${o.totalPrice.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _getStatusColor(o.orderStatus), borderRadius: BorderRadius.circular(5)),
                          child: Text(o.orderStatus, style: const TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}