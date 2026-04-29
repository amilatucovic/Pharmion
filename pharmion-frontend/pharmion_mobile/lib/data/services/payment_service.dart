import 'api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int reservationId,
    required int method, 
  }) async {
    return await ApiService.post('Payment/create-intent', {
      'reservationId': reservationId,
      'method': method,
    }) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getByReservation(
      int reservationId) async {
    try {
      return await ApiService.get('Payment/by-reservation/$reservationId')
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> refund(int reservationId) async {
    return await ApiService.post('Payment/refund/$reservationId', {})
        as Map<String, dynamic>;
  }
}