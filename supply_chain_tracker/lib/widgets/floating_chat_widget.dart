import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/colors.dart';

class FloatingChatWidget extends StatefulWidget {
  const FloatingChatWidget({super.key});

  @override
  State<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<FloatingChatWidget>
    with SingleTickerProviderStateMixin {
  // Chat state
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user-1', firstName: 'You');
  final _assistant = const types.User(
    id: 'assistant-1',
    firstName: 'Supply Chain Assistant',
  );

  // Animation state
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Add welcome message
    _addInitialMessage();
  }

  void _addInitialMessage() {
    final textMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          'Hello! I\'m your Supply Chain Assistant. I can help you with inventory queries, shipment tracking, and data insights. How can I assist you today?',
    );

    setState(() {
      _messages.insert(0, textMessage);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    // Simulate assistant response (placeholder for backend integration)
    _simulateAssistantResponse(message.text);
  }

  void _simulateAssistantResponse(String userMessage) {
    // This is a placeholder - will be replaced with actual backend call
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      final responseMessage = types.TextMessage(
        author: _assistant,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text:
            'I received your message: "$userMessage". Backend integration coming soon!',
      );

      setState(() {
        _messages.insert(0, responseMessage);
      });
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    // Add welcome message back after clearing
    _addInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Expanded chat window
        if (_isExpanded)
          Positioned(
            right: 16,
            bottom: 88,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 380,
                  height: 600,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? theme.colorScheme.border.withValues(alpha: 0.5)
                          : theme.colorScheme.border,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Chat header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.forestGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Supply Chain Assistant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Online',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _clearChat,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Clear chat',
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _toggleChat,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        // Chat messages
                        Expanded(
                          child: Chat(
                            messages: _messages,
                            onSendPressed: _handleSendPressed,
                            user: _user,
                            theme: DefaultChatTheme(
                              backgroundColor: isDark
                                  ? theme.colorScheme.background
                                  : theme.colorScheme.background,
                              primaryColor: AppColors.unfiGreen,
                              secondaryColor: isDark
                                  ? theme.colorScheme.muted
                                  : theme.colorScheme.muted,
                              inputBackgroundColor: isDark
                                  ? theme.colorScheme.card
                                  : theme.colorScheme.card,
                              inputTextColor: isDark
                                  ? theme.colorScheme.foreground
                                  : theme.colorScheme.foreground,
                              inputBorderRadius: BorderRadius.circular(24),
                              messageBorderRadius: 12,
                              inputPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              receivedMessageBodyTextStyle: TextStyle(
                                color: theme.colorScheme.foreground,
                                fontSize: 14,
                              ),
                              sentMessageBodyTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            inputOptions: InputOptions(
                              sendButtonVisibilityMode:
                                  SendButtonVisibilityMode.always,
                            ),
                            showUserAvatars: true,
                            showUserNames: false,
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),

        // Floating action button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _toggleChat,
            backgroundColor: AppColors.unfiGreen,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                _isExpanded ? Icons.close_rounded : Icons.chat_rounded,
                key: ValueKey<bool>(_isExpanded),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
