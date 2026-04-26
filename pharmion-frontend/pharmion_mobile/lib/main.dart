import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51TQU70Bhdu9acYngXnYLDNSaKkjcPz7awniPOhqdhSCRLLcYbfObuDkFda9aFzMUKSNKFdSHcxEEUhpUD5a4jE6O009tiS5pho'; 
  await Stripe.instance.applySettings();
  runApp(const PharmionApp());
}

class PharmionApp extends StatelessWidget {
  const PharmionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'Pharmion',
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router(auth),
          );
        },
      ),
    );
  }
}