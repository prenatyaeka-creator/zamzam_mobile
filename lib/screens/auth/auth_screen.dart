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
  UserRole? selectedRole;
  bool rememberMe = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = Provider.of<AppState>(context, listen: false);
    rememberMe = app.rememberMe;
    if (app.savedEmail != null) {
      emailController.text = app.savedEmail!;
    }
    if (app.savedRole != null) {
      selectedRole = app.savedRole;
    }
  }

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
                    color: Colors.white.withAlpha(46),
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
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
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
                      const Text('Pilih Role',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
                      const SizedBox(height: 10),
                      if (selectedRole == null)
                        Text(
                          'Pilih role terlebih dahulu sebelum login.',
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12),
                        ),
                      const SizedBox(height: 6),
                    ],
                    if (isRegister) ...[
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Nama Lengkap'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText:
                            isRegister ? 'Contoh: pelanggan@contoh.com' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isRegister) ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration:
                            const InputDecoration(labelText: 'Nomor Telepon'),
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
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (!isRegister) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: rememberMe,
                        onChanged: (val) {
                          setState(() => rememberMe = val ?? false);
                        },
                        title: const Text('Ingat Akun', style: TextStyle(fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: AppColors.rose,
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: app.isBusy ? null : _submit,
                        child: Text(app.isBusy
                            ? 'Memproses...'
                            : (isRegister ? 'Daftar Sekarang' : 'Login')),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isRegister = !isRegister;
                            selectedRole = null;
                            emailController.clear();
                            passwordController.clear();
                            if (isRegister) {
                              nameController.clear();
                              phoneController.clear();
                              addressController.clear();
                            }
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
        setState(() {
          isRegister = false;
          selectedRole = UserRole.customer;
        });
        passwordController.clear();
        _showSnack(
          'Registrasi berhasil. Silakan login sebagai pelanggan.',
        );
      }
      return;
    }

    if (selectedRole == null) {
      _showSnack('Silakan pilih role admin atau pelanggan terlebih dahulu.');
      return;
    }

    final success = await app.login(
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole!,
      remember: rememberMe,
    );
    if (!mounted) return;
    if (!success) {
      final message =
          app.lastError ?? 'Email, password, atau role tidak sesuai.';
      if (selectedRole == UserRole.customer &&
          message.contains('Data pelanggan tidak ditemukan')) {
        setState(() {
          isRegister = true;
          selectedRole = null;
          emailController.clear();
          passwordController.clear();
          nameController.clear();
          phoneController.clear();
          addressController.clear();
        });
        _showSnack(
          'Data pelanggan tidak ditemukan. Silakan registrasi terlebih dahulu.',
        );
        return;
      }

      // Log to console
      // ignore: avoid_print
      print('[AuthScreen] Login failed: $message');
      // Show dialog with detailed message for debugging
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Gagal'),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup')),
          ],
        ),
      );
      _showSnack(message);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
