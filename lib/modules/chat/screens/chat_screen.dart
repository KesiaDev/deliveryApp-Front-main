import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';

/// Tela de chat modernizada - estilo WhatsApp/iFood
class ChatScreen extends StatefulWidget {
  final String corridaId;
  final String motoristaId;
  final String motoristaName;
  final String empresaId;
  final String empresaName;
  final String currentUserId;
  final String currentUserName;
  final String currentUserType; // 'motorista', 'empresa' ou 'admin'

  const ChatScreen({
    Key? key,
    required this.corridaId,
    required this.motoristaId,
    required this.motoristaName,
    required this.empresaId,
    required this.empresaName,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserType,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late ChatController _controller;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  bool _isTyping = false;

  // Cores modernas - estilo WhatsApp/iFood
  static const Color backgroundColor = Color(0xFFF8F5FA);
  static const Color sentBubbleColor = Color(0xFFE74A3B);
  static const Color receivedBubbleColor = Color(0xFFFFFFFF);
  static const Color receivedBubbleBorder = Color(0xFFEDEDED);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color inputBackground = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _controller.initializeChat(
      corridaId: widget.corridaId,
      motoristaId: widget.motoristaId,
      motoristaName: widget.motoristaName,
      empresaId: widget.empresaId,
      empresaName: widget.empresaName,
    );

    // Scroll para o final após carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getOtherUserName() {
    return widget.currentUserType == 'motorista'
        ? widget.empresaName
        : widget.motoristaName;
  }

  String _getOtherUserInitial() {
    final name = _getOtherUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.corridaId}',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: sentBubbleColor,
                child: Text(
                  _getOtherUserInitial(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getOtherUserName(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isTyping)
                    Text(
                      'Digitando...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: sentBubbleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textPrimary),
            onPressed: () {
              // Menu de opções
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(sentBubbleColor),
                    ),
                  );
                }

                if (_controller.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma mensagem ainda.\nInicie a conversa!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = _controller.messages[index];
                    final isMe = message.senderId == widget.currentUserId;
                    return _buildMessageBubble(message, isMe, index);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(isMe ? 20 * (1 - value) : -20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: sentBubbleColor,
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? sentBubbleColor : receivedBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: receivedBubbleBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe && message.senderName.isNotEmpty) ...[
                        Text(
                          message.senderName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white70 : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message.content,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isMe ? Colors.white : textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : textSecondary,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead ? Colors.blue[300] : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: inputBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller.messageController,
                  decoration: InputDecoration(
                    hintText: 'Digite uma mensagem...',
                    hintStyle: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    setState(() {
                      _isTyping = text.isNotEmpty;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final hasText = _controller.messageController.text.trim().isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: hasText ? sentBubbleColor : textSecondary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasText
                          ? () async {
                              await _controller.sendMessage(
                                senderId: widget.currentUserId,
                                senderName: widget.currentUserName,
                                senderType: widget.currentUserType,
                              );
                              _scrollToBottom();
                              setState(() {
                                _isTyping = false;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
