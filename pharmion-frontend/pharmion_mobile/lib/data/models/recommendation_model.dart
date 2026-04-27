import 'product_model.dart';

class RecommendationModel {
  final ProductModel product;
  final String reason;
  final double score;

  const RecommendationModel({
    required this.product,
    required this.reason,
    required this.score,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) =>
      RecommendationModel(
        product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
        reason: json['reason'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );
}