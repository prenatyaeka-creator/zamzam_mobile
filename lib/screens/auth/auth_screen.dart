import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  UserRole selectedRole = UserRole.customer;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientBanner(
                title: 'ZAMZAM LAUNDRY',
                subtitle: isRegister
                    ? 'Buat akun pelanggan baru untuk mulai menggunakan aplikasi laundry modern.'
                    : 'Masuk sebagai admin atau pelanggan untuk mengakses fitur aplikasi.',
                trailing: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_laundry_service_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRegister ? 'Registrasi Pelanggan' : 'Masuk ke Aplikasi',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRegister
                          ? 'Lengkapi data untuk membuat akun pelanggan.'
                          : 'Pilih role dan login menggunakan email serta password.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 18),
                    if (!isRegister) ...[
                      const Text('Pilih Role', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: UserRole.values.map((role) {
                          return ChoiceChip(
                            selected: selectedRole == role,
                            selectedColor: AppColors.sage,
                            label: Text(role.label),
                            onSelected: (_) {
                              setState(() => selectedRole = role);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isRegister) ...[
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    if (isRegister) ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: app.isBusy ? null : _submit,
                        child: Text(app.isBusy ? 'Memproses...' : (isRegister ? 'Daftar Sekarang' : 'Login')), 
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isRegister = !isRegister;
                            selectedRole = UserRole.customer;
                          });
                        },
                        child: Text(
                          isRegister
                              ? 'Sudah punya akun? Masuk sekarang'
                              : 'Belum punya akun? Registrasi pelanggan',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(
                title: 'Akun Demo',
                subtitle: 'Gunakan tombol ini untuk mengisi akun cepat saat demo.',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isRegister = false;
                          selectedRole = UserRole.admin;
                          emailController.text = 'admin@zamzam.com';
                          passwordController.text = 'Admin123!';
                        });
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin Demo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isRegister = false;
                          selectedRole = UserRole.customer;
                          emailController.text = 'alya@zamzam.com';
                          passwordController.text = 'Pelanggan123!';
                        });
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Customer Demo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    if (isRegister) {
      final error = await app.registerCustomer(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        address: addressController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      if (error != null) {
        _showSnack(error);
      } else {
        _showSnack('Registrasi berhasil. Selamat datang di ZAMZAM LAUNDRY.');
      }
      return;
    }

    final success = await app.login(
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole,
    );
    if (!mounted) return;
    if (!success) {
      _showSnack(app.lastError ?? 'Email, password, atau role tidak sesuai.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
