import '../models/auth_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';

class ChatRepository {
  final ApiClient apiClient;

  ChatRepository({required this.apiClient});

  Future<ChatbotResponse> sendMessage(String message) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/chatbot',
        data: {'message': message},
      );
      return ChatbotResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  AppError _handleError(dynamic error) {
    if (error is AppError) return error;
    return AppError(message: 'An unexpected error occurred');
  }
}
