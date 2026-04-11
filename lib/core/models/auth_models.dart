import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

// ============================================================================
// AUTH RESPONSE MODELS
// ============================================================================

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  final String uid;

  final String role;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.uid,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

// ============================================================================
// USER MODEL
// ============================================================================

@JsonSerializable()
class User {
  final String uid;
  final String email;

  @JsonKey(name: 'full_name')
  final String fullName;

  final String? phone;

  final String role;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final String createdAt;

  User({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// ============================================================================
// OTP VERIFICATION MODELS
// ============================================================================

@JsonSerializable()
class OtpVerificationResponse {
  final String message;
  final String email;

  OtpVerificationResponse({required this.message, required this.email});

  factory OtpVerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpVerificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OtpVerificationResponseToJson(this);
}

// ============================================================================
// GENERIC MESSAGE RESPONSE
// ============================================================================

@JsonSerializable()
class MessageResponse {
  final String message;

  MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);
}

// ============================================================================
// CHATBOT RESPONSE
// ============================================================================

@JsonSerializable()
class ChatbotResponse {
  final String reply;

  ChatbotResponse({required this.reply});

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatbotResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotResponseToJson(this);
}
