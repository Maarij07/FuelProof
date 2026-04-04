import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key}); // UPDATED: Converted to super parameter

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late TextEditingController _messageController;
  late List<ChatMessage> _messages;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _initializeMessages();
  }

  void _initializeMessages() {
    _messages = [
      ChatMessage(
        id: 'msg-001',
        content: 'Hello! How can I assist you with FuelProof today?',
        isUser: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      ChatMessage(
        id: 'msg-002',
        content: 'I have a question about my last transaction',
        isUser: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 4)),
      ),
      ChatMessage(
        id: 'msg-003',
        content:
            'Of course! I\'d be happy to help. Could you provide the transaction ID or date?',
        isUser: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 3)),
      ),
      ChatMessage(
        id: 'msg-004',
        content: 'It was from today at 2:45 PM at Shell Makati',
        isUser: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 2)),
      ),
      ChatMessage(
        id: 'msg-005',
        content:
            'I found your transaction (TXN-2024-089452) for â‚±2,450.00. How can I help with this?',
        isUser: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 1)),
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      content: _messageController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        final botMessage = ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          content: _generateBotResponse(userMessage.content),
          isUser: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(botMessage);
        });

        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.short,
        curve: Curves.easeOut,
      );
    });
  }

  String _generateBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('refund') || lowerMessage.contains('return')) {
      return 'We process refunds within 3-5 business days. Can you clarify the reason for the refund request?';
    } else if (lowerMessage.contains('price') ||
        lowerMessage.contains('cost')) {
      return 'Fuel prices fluctuate based on market conditions. You can check current prices at any station through our Find Stations feature.';
    } else if (lowerMessage.contains('thank')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    } else if (lowerMessage.contains('problem') ||
        lowerMessage.contains('issue')) {
      return 'I\'m sorry to hear you\'re experiencing an issue. Could you provide more details so I can assist you better?';
    } else {
      return 'Thanks for your message. I\'m here to help! Please let me know what you need.';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 2),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support Chat', style: AppTextStyles.cardTitle),
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'AI Assistant Online',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
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
            color: AppColors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Chat with our AI Assistant',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.subtleList,
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Attachment feature coming soon'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.attach_file,
                          color: AppColors.secondaryText,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.input,
                          ),
                          boxShadow: AppShadows.subtleList,
                        ),
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.tertiaryText,
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
                        color: AppColors.accentTeal,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.subtleList,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(
                          Icons.send,
                          color: AppColors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
                color: AppColors.accentTeal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.smart_toy, size: 18, color: AppColors.white),
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
                color: isUser ? AppColors.brandNavy : AppColors.lightGray,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
                boxShadow: AppShadows.subtleList,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.body.copyWith(
                      color: isUser ? AppColors.white : AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: isUser
                          ? AppColors.white.withValues(
                              alpha: 0.7,
                            ) // UPDATED: Replaced withOpacity with withValues
                          : AppColors.secondaryText,
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
                color: AppColors.accentTeal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.person, size: 18, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}
