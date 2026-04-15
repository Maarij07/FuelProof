import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/repositories/chat_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late final ChatRepository _chatRepository;
  late final TextEditingController _messageController;
  late final ScrollController _scrollController;

  final List<String> _quickPrompts = const [
    'How do I reset my password?',
    'Where can I find my latest transaction?',
    'How does QR fueling work?',
    'Why is my session pending?',
  ];

  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _chatRepository = ChatRepository(apiClient: apiClient);
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content:
            'Hello! I am the FuelGuard support assistant. Ask me anything about fueling, transactions, or account issues.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.short,
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? presetMessage]) async {
    final messageText = (presetMessage ?? _messageController.text).trim();
    if (messageText.isEmpty || _isSending) return;

    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      content: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isSending = true;
      _messages.add(
        ChatMessage(
          id: 'typing-${DateTime.now().millisecondsSinceEpoch}',
          content: 'Typing',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ),
      );
    });

    _scrollToBottom();

    try {
      final response = await _chatRepository.sendMessage(messageText);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.isTyping);
        _messages.add(
          ChatMessage(
            id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
            content: response.reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.isTyping);
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppError && e.detail != null && e.detail!.trim().isNotEmpty
                ? e.detail!
                : 'Unable to reach support. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Chat',
              style: AppTextStyles.cardTitle.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  _isSending ? 'Assistant replying...' : 'AI Assistant Online',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (context, _) =>
                    SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(prompt),
                    onPressed: _isSending ? null : () => _sendMessage(prompt),
                    backgroundColor: colorScheme.surface,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            color: colorScheme.surface,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.input,
                      ),
                      boxShadow: AppShadows.subtleList,
                    ),
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: _isSending
                        ? colorScheme.outline
                        : colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.subtleList,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: Icon(
                      Icons.send,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    if (message.isTyping) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
                boxShadow: AppShadows.subtleList,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _typingDot(),
                  SizedBox(width: 4),
                  _typingDot(delay: 80),
                  SizedBox(width: 4),
                  _typingDot(delay: 160),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          SizedBox(width: isUser ? 0 : AppSpacing.md),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
                boxShadow: AppShadows.subtleList,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.body.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary.withValues(alpha: 0.75)
                          : colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isUser ? AppSpacing.md : 0),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typingDot({int delay = 0}) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
