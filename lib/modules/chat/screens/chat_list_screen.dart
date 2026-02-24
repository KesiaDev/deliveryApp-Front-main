import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';

/// Tela de lista de conversas modernizada - estilo WhatsApp
class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserType;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserType,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoomModel> _chatRooms = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Cores modernas
  static const Color backgroundColor = Color(0xFFF8F5FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color sentBubbleColor = Color(0xFFE74A3B);

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);
    try {
      _chatRooms = await ChatService.getUserChatRooms(widget.currentUserId);
    } catch (e) {
      debugPrint('Erro ao carregar chats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getOtherName(ChatRoomModel room) {
    return widget.currentUserType == 'motorista'
        ? room.empresaName
        : room.motoristaName;
  }

  String _getOtherInitial(ChatRoomModel room) {
    final name = _getOtherName(room);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        title: Text(
          'Mensagens',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: textPrimary),
            onPressed: () {
              // Implementar busca
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: cardBackground,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar conversas...',
                  hintStyle: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
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
              ),
            ),
          ),
          // Lista de conversas
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(sentBubbleColor),
                    ),
                  )
                : _chatRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.motorcycle_rounded,
                              size: 80,
                              color: textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma conversa ainda',
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Suas conversas aparecerão aqui',
                              style: GoogleFonts.inter(
                                color: textSecondary.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadChatRooms,
                        color: sentBubbleColor,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _chatRooms.length,
                          itemBuilder: (context, index) {
                            final room = _chatRooms[index];
                            return _buildChatRoomItem(room);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoomModel room) {
    final otherName = _getOtherName(room);
    final otherInitial = _getOtherInitial(room);
    final lastMessageTime = room.lastMessageAt ?? room.createdAt;
    final unreadCount = room.unreadCount;

    return Material(
      color: cardBackground,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                corridaId: room.corridaId,
                motoristaId: room.motoristaId,
                motoristaName: room.motoristaName,
                empresaId: room.empresaId,
                empresaName: room.empresaName,
                currentUserId: widget.currentUserId,
                currentUserName: widget.currentUserName,
                currentUserType: widget.currentUserType,
              ),
            ),
          ).then((_) => _loadChatRooms());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: backgroundColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'avatar_${room.corridaId}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: sentBubbleColor,
                  child: Text(
                    otherInitial,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatLastMessageTime(lastMessageTime),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: sentBubbleColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
