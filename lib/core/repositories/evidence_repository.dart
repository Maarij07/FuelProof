import '../services/api_client.dart';

class EvidenceItem {
  final String id;
  final String transactionId;
  final String imageUrl;
  final String? thumbnailUrl;
  final double fileSizeKb;
  final String captureTrigger;
  final String watermarkText;
  final String? captureTimePkt;
  final DateTime createdAt;
  final DateTime deleteAt;

  EvidenceItem({
    required this.id,
    required this.transactionId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.fileSizeKb,
    required this.captureTrigger,
    required this.watermarkText,
    this.captureTimePkt,
    required this.createdAt,
    required this.deleteAt,
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      // Firestore Timestamp-serialized map
      if (v is Map && v['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (v['_seconds'] as int) * 1000,
        );
      }
      return DateTime.now();
    }

    final metadata = json['metadata'];
    final metadataMap = metadata is Map ? metadata : const {};

    return EvidenceItem(
      id: json['id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      fileSizeKb: (json['file_size_kb'] as num?)?.toDouble() ?? 0,
      captureTrigger: json['capture_trigger'] as String? ?? 'manual',
      watermarkText: json['watermark_text'] as String? ?? '',
      captureTimePkt: metadataMap['capture_time_pkt'] as String?,
      createdAt: parseDate(json['created_at']),
      deleteAt: parseDate(json['delete_at']),
    );
  }
}

class EvidenceRepository {
  final ApiClient _apiClient;

  EvidenceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<EvidenceItem> uploadEvidence({
    required String transactionId,
    required List<int> imageBytes,
    required String filename,
    String nozzleId = 'manual',
    String captureTrigger = 'manual',
  }) async {
    return _apiClient.uploadMultipart<EvidenceItem>(
      '/evidence',
      fileBytes: imageBytes,
      filename: filename,
      mimeType: 'image/jpeg',
      queryParams: {
        'transaction_id': transactionId,
        'nozzle_id': nozzleId,
        'capture_trigger': captureTrigger,
      },
      parser: (data) => EvidenceItem.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<EvidenceItem>> getEvidenceForTransaction(
    String transactionId,
  ) async {
    return _apiClient.get<List<EvidenceItem>>(
      '/evidence/$transactionId',
      parser: (data) => (data as List)
          .map((e) => EvidenceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
