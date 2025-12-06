import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../theme/colors.dart';
import '../widgets/border_beam.dart';
import '../widgets/gemini_splash/gemini_splash.dart';
import '../services/api_service.dart';

class PlanningScreen extends StatefulWidget {
  final bool isVisible;

  const PlanningScreen({
    super.key,
    this.isVisible = false,
  });

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  // Chat state
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user-1', firstName: 'You');
  final _assistant = const types.User(
    id: 'assistant-1',
    firstName: 'Supply Chain Planning Agent',
  );
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  // Splash animation state
  bool _showSplash = false;
  bool _hasPlayedSplash = false;
  final GlobalKey<GeminiSplashState> _splashKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addInitialMessage();
  }

  @override
  void didUpdateWidget(PlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger splash when tab becomes visible for the first time
    if (widget.isVisible && !oldWidget.isVisible && !_hasPlayedSplash) {
      setState(() {
        _showSplash = true;
        _hasPlayedSplash = true;
      });
    }
  }

  void _onSplashComplete() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addInitialMessage() {
    final textMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          'Hello! I\'m your Supply Chain Planning Agent. I can help you with inventory queries, shipment tracking, and data insights. How can I assist you today?',
    );

    setState(() {
      _messages.insert(0, textMessage);
    });
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

  Future<void> _simulateAssistantResponse(String userMessage) async {
    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Create a placeholder message for streaming updates
    final messageId = const Uuid().v4();
    final placeholderMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: messageId,
      text: '',
    );

    setState(() {
      _messages.insert(0, placeholderMessage);
    });

    try {
      // Build the conversation history for context
      final conversationMessages = _messages.reversed.where((msg) => msg.id != messageId).map((msg) {
        return {
          'role': msg.author.id == _user.id ? 'user' : 'assistant',
          'content': (msg as types.TextMessage).text,
        };
      }).toList();

      // Make streaming API call
      final request = http.Request(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/chat/stream'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'messages': conversationMessages,
      });

      final streamedResponse = await request.send();

      if (!mounted) return;

      if (streamedResponse.statusCode == 200) {
        String accumulatedText = '';

        // Listen to the stream
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          if (!mounted) break;

          // Parse SSE data
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final dataStr = line.substring(6);
              try {
                final data = json.decode(dataStr);

                if (data['done'] == true) {
                  // Stream complete
                  setState(() {
                    _isLoading = false;
                  });
                  break;
                } else if (data['error'] != null) {
                  // Handle error
                  setState(() {
                    _isLoading = false;
                    _messages.removeWhere((msg) => msg.id == messageId);
                    _messages.insert(0, types.TextMessage(
                      author: _assistant,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                      id: const Uuid().v4(),
                      text: 'Sorry, I encountered an error: ${data['error']}',
                    ));
                  });
                  return;
                } else if (data['content'] != null) {
                  // Update message with new content
                  accumulatedText += data['content'];

                  setState(() {
                    final index = _messages.indexWhere((msg) => msg.id == messageId);
                    if (index != -1) {
                      _messages[index] = types.TextMessage(
                        author: _assistant,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                        id: messageId,
                        text: accumulatedText,
                      );
                    }
                  });
                }
              } catch (e) {
                // Ignore JSON parse errors for incomplete chunks
              }
            }
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _isLoading = false;
          _messages.removeWhere((msg) => msg.id == messageId);
          _messages.insert(0, types.TextMessage(
            author: _assistant,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: const Uuid().v4(),
            text: 'Sorry, I encountered an error. Please try again.',
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Handle network or parsing errors
      setState(() {
        _isLoading = false;
        _messages.removeWhere((msg) => msg.id == messageId);
        _messages.insert(0, types.TextMessage(
          author: _assistant,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: 'Sorry, I couldn\'t connect to the server. Please check your connection.',
        ));
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    // Add welcome message back after clearing
    _addInitialMessage();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || _isLoading) return;

    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    _textController.clear();
    _simulateAssistantResponse(text);
  }

  Widget _buildTextMessage(types.TextMessage message, {required int messageWidth, required bool showName}) {
    final theme = ShadTheme.of(context);
    final isUser = message.author.id == _user.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.unfiGreen : theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GptMarkdown(
        message.text,
        style: TextStyle(
          color: isUser ? Colors.white : theme.colorScheme.foreground,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildInputWidget(ShadThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: BorderBeam(
              duration: 4,
              borderWidth: 2,
              colorFrom: AppColors.unfiGreen,
              colorTo: AppColors.sunriseOrange,
              staticBorderColor: theme.colorScheme.border,
              borderRadius: BorderRadius.circular(24),
              padding: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !_isLoading,
                  style: TextStyle(
                    color: theme.colorScheme.foreground,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: _isLoading ? 'Waiting for response...' : 'Message',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _handleSubmitted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: _isLoading
                ? LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  )
                : AppColors.forestGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
              icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
              tooltip: _isLoading ? 'Sending...' : 'Send',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(ShadThemeData theme, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.forestGradient,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supply Chain Planning Agent',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (_isLoading) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Thinking...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ] else
                              const Text(
                                'Online • Ready to help with planning and insights',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearChat,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Clear chat',
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
                  backgroundColor: theme.colorScheme.card,
                  primaryColor: AppColors.unfiGreen,
                  secondaryColor: theme.colorScheme.muted,
                  inputBackgroundColor: theme.colorScheme.background,
                  inputTextColor: theme.colorScheme.foreground,
                  inputBorderRadius: BorderRadius.circular(24),
                  messageBorderRadius: 12,
                  inputPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  receivedMessageBodyTextStyle: TextStyle(
                    color: theme.colorScheme.foreground,
                    fontSize: 15,
                  ),
                  sentMessageBodyTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  inputTextStyle: TextStyle(
                    color: theme.colorScheme.foreground,
                    fontSize: 15,
                  ),
                ),
                showUserAvatars: true,
                showUserNames: false,
                customBottomWidget: _buildInputWidget(theme, isDark),
                textMessageBuilder: _buildTextMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Main chat content
          AnimatedOpacity(
            opacity: _showSplash ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: _buildChatContent(theme, isDark),
          ),
          // Gemini splash overlay
          if (_showSplash)
            Positioned.fill(
              child: GeminiSplash(
                key: _splashKey,
                onAnimationComplete: _onSplashComplete,
                duration: const Duration(milliseconds: 3000),
                primaryColor: AppColors.lava500,
                secondaryColor: AppColors.lava600,
              ),
            ),
        ],
      ),
    );
  }
}
