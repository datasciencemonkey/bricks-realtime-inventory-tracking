import 'dart:convert' show json, utf8;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/colors.dart';
import '../widgets/border_beam.dart';
import '../services/api_service.dart';

/// Context types for the floating chat widget
enum ChatContext {
  executiveDashboard,
  realtimeSnapshot,
  shipmentTracking,
}

class FloatingChatWidget extends StatefulWidget {
  final ChatContext context;

  /// Optional batch ID for shipment tracking context
  /// When provided, the chat will have detailed context about this specific batch
  final String? selectedBatchId;

  const FloatingChatWidget({
    super.key,
    required this.context,
    this.selectedBatchId,
  });

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
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  // Animation state
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String get _contextName {
    switch (widget.context) {
      case ChatContext.executiveDashboard:
        return 'Executive Dashboard';
      case ChatContext.realtimeSnapshot:
        return 'Real-time Snapshot';
      case ChatContext.shipmentTracking:
        return 'Shipment Tracking';
    }
  }

  String get _contextDescription {
    switch (widget.context) {
      case ChatContext.executiveDashboard:
        return 'Ask me about KPIs, metrics, and executive insights';
      case ChatContext.realtimeSnapshot:
        return 'Ask me about inventory levels and shipment status';
      case ChatContext.shipmentTracking:
        return 'Ask me about batch tracking and delivery routes';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
          'Hello! I\'m your Supply Chain Assistant for the $_contextName. $_contextDescription. How can I help you?',
    );

    setState(() {
      _messages.insert(0, textMessage);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
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

  /// Get the API endpoint URL based on context
  String get _chatApiEndpoint {
    switch (widget.context) {
      case ChatContext.executiveDashboard:
        return '${ApiService.baseUrl}/api/chat/executive-dashboard/stream';
      case ChatContext.realtimeSnapshot:
        return '${ApiService.baseUrl}/api/chat/realtime-snapshot/stream';
      case ChatContext.shipmentTracking:
        return '${ApiService.baseUrl}/api/chat/shipment-tracking/stream';
    }
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty || _isLoading) return;

    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: userMessage,
    );

    setState(() {
      _messages.insert(0, textMessage);
      _isLoading = true;
    });

    _textController.clear();

    // Create placeholder message for streaming updates
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
      // Build conversation history for context
      final conversationMessages = _messages.reversed
          .where((msg) => msg.id != messageId)
          .map((msg) {
        return {
          'role': msg.author.id == _user.id ? 'user' : 'assistant',
          'content': (msg as types.TextMessage).text,
        };
      }).toList();

      // Make streaming API call
      final request = http.Request(
        'POST',
        Uri.parse(_chatApiEndpoint),
      );
      request.headers['Content-Type'] = 'application/json';

      // Build request body - include selected_batch_id for shipment tracking context
      final Map<String, dynamic> requestBody = {
        'messages': conversationMessages,
      };
      if (widget.context == ChatContext.shipmentTracking &&
          widget.selectedBatchId != null) {
        requestBody['selected_batch_id'] = widget.selectedBatchId;
      }
      request.body = json.encode(requestBody);

      final streamedResponse = await request.send();

      if (!mounted) return;

      if (streamedResponse.statusCode == 200) {
        String accumulatedText = '';

        // Listen to the stream
        await for (var chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          if (!mounted) break;

          // Parse SSE data
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final dataStr = line.substring(6);
              try {
                final data = json.decode(dataStr);

                if (data['done'] == true) {
                  setState(() {
                    _isLoading = false;
                  });
                  break;
                } else if (data['error'] != null) {
                  _handleError(messageId, data['error']);
                  return;
                } else if (data['content'] != null) {
                  accumulatedText += data['content'];
                  _updateStreamingMessage(messageId, accumulatedText);
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
        _handleError(messageId, 'Server error: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _handleError(messageId, 'Connection error. Please try again.');
      }
    }
  }

  void _updateStreamingMessage(String messageId, String text) {
    setState(() {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = types.TextMessage(
          author: _assistant,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: messageId,
          text: text,
        );
      }
    });
  }

  void _handleError(String messageId, String error) {
    setState(() {
      _isLoading = false;
      _messages.removeWhere((msg) => msg.id == messageId);
      _messages.insert(
        0,
        types.TextMessage(
          author: _assistant,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: 'Sorry, I encountered an error: $error',
        ),
      );
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    // Add welcome message back after clearing
    _addInitialMessage();
  }

  Widget _buildInputWidget(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              colorFrom: AppColors.lava600,
              colorTo: AppColors.sunriseOrange,
              staticBorderColor: theme.colorScheme.border,
              borderRadius: BorderRadius.circular(20),
              padding: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !_isLoading,
                  style: TextStyle(
                    color: theme.colorScheme.foreground,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: _isLoading ? 'Thinking...' : 'Ask a question...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    )
                  : const LinearGradient(
                      colors: [AppColors.lava600, AppColors.sunriseOrange],
                    ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              onPressed:
                  _isLoading ? null : () => _sendMessage(_textController.text),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              tooltip: _isLoading ? 'Sending...' : 'Send',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
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
            bottom: 80,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 400,
                  height: 520,
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
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.lava600, AppColors.sunriseOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Supply Chain Assistant',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (_isLoading) ...[
                                        const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white70),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Thinking...',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          _contextName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
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
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Clear chat',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _toggleChat,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
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
                          onSendPressed: (msg) => _sendMessage(msg.text),
                          user: _user,
                          theme: DefaultChatTheme(
                            backgroundColor: theme.colorScheme.card,
                            primaryColor: AppColors.lava600,
                            secondaryColor: theme.colorScheme.muted,
                            inputBackgroundColor: theme.colorScheme.background,
                            inputTextColor: theme.colorScheme.foreground,
                            inputBorderRadius: BorderRadius.circular(20),
                            messageBorderRadius: 12,
                            inputPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
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
                          showUserAvatars: false,
                          showUserNames: false,
                          customBottomWidget: _buildInputWidget(theme),
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
            backgroundColor: AppColors.lava600,
            elevation: 4,
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
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
