import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'models/app_models.dart';
import 'screens/admin/admin_home.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/customer/customer_home.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ZamzamLaundryApp());
}

class ZamzamLaundryApp extends StatelessWidget {
  const ZamzamLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ZAMZAM LAUNDRY',
        theme: AppTheme.light,
        home: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    if (user == null) {
      return const AuthScreen();
    }
    if (user.role == UserRole.admin) {
      return const AdminHome();
    }
    return const CustomerHome();
  }
}
