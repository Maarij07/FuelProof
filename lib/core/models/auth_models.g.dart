// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      uid: json['uid'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'uid': instance.uid,
      'role': instance.role,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'role': instance.role,
      'avatar_url': instance.avatarUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };

OtpVerificationResponse _$OtpVerificationResponseFromJson(
        Map<String, dynamic> json) =>
    OtpVerificationResponse(
      message: json['message'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$OtpVerificationResponseToJson(
        OtpVerificationResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'email': instance.email,
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      message: json['message'] as String,
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
    };

ChatbotResponse _$ChatbotResponseFromJson(Map<String, dynamic> json) =>
    ChatbotResponse(
      reply: json['reply'] as String,
    );

Map<String, dynamic> _$ChatbotResponseToJson(ChatbotResponse instance) =>
    <String, dynamic>{
      'reply': instance.reply,
    };
