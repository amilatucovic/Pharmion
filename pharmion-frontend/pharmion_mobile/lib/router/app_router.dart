import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/dashboard_home_screen.dart';
import '../screens/reservations/reservations_screen.dart';
import '../screens/prescriptions/prescriptions_screen.dart';
import '../screens/prescriptions/prescription_detail_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/pharmacies/pharmacy_detail_screen.dart';
import '../data/models/pharmacy_model.dart';
import '../data/models/prescription_model.dart';
import '../data/models/inventory_item_model.dart';
import '../data/models/reservation_model.dart';
import '../screens/reservations/reservation_detail_screen.dart';
import '../screens/pharmacies/pharmacies_screen.dart';
import '../screens/products/products_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) => GoRouter(
        initialLocation: '/splash',
        redirect: (context, state) {
          final isAuth = auth.isAuthenticated;
          final isUnknown = auth.status == AuthStatus.unknown;
          final isSplash = state.matchedLocation == '/splash';
          final isAuthRoute = state.matchedLocation.startsWith('/auth');

          if (isUnknown) return isSplash ? null : '/splash';
          if (!isAuth && !isAuthRoute) return '/auth/login';
          if (isAuth && isAuthRoute) return '/';
          return null;
        },
        refreshListenable: auth,
        routes: [
          GoRoute(
            path: '/splash',
            builder: (_, __) => const SplashScreen(),
          ),
          GoRoute(
            path: '/auth/login',
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: '/auth/register',
            builder: (_, __) => const RegisterScreen(),
          ),
          ShellRoute(
            builder: (context, state, child) => DashboardScreen(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const DashboardHomeScreen(),
              ),
              GoRoute(
                path: '/reservations',
                builder: (_, __) => const ReservationsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final reservation = state.extra as ReservationModel;
                      return ReservationDetailScreen(reservation: reservation);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/prescriptions',
                builder: (_, __) => const PrescriptionsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final prescription = state.extra as PrescriptionModel;
                      return PrescriptionDetailScreen(
                          prescription: prescription);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/products',
                builder: (_, __) => const ProductsScreen(), 
              ),
              GoRoute(
                path: '/product-detail',
                builder: (_, state) {
                  final item = state.extra as InventoryItemModel;
                  return ProductDetailScreen(inventoryItem: item);
                },
              ),
              GoRoute(
                path: '/pharmacy',
                builder: (context, state) {
                  final pharmacy = state.extra as PharmacyModel;
                  return PharmacyDetailScreen(pharmacy: pharmacy);
                },
              ),
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
              GoRoute(
                path: '/pharmacies',
                builder: (_, __) => const PharmaciesScreen(),
              ),
            ],
          ),
        ],
      );
}
