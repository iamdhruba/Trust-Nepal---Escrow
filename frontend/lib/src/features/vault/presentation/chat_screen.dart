import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nt_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../auth/presentation/auth_viewmodel.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const ChatScreen({super.key, required this.vaultId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _initSocket();
  }

  void _initSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = ref.read(socketServiceProvider);
      socket.connect();
      socket.joinVault(widget.vaultId);
      socket.onChatMessage((data) {
        if (mounted) {
          final msg = Map<String, dynamic>.from(data);
          final exists = _messages.any((m) => m['_id'] != null && m['_id'] == msg['_id']);
          if (!exists) {
            setState(() {
              _messages.add(msg);
            });
            _scrollToBottom();
          }
        }
      });
    });
  }

  Future<void> _fetchHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/vaults/${widget.vaultId}/messages');
      if (mounted) {
        setState(() {
          _messages.addAll(List<Map<String, dynamic>>.from(res.data['data']));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    
    final user = ref.read(authViewModelProvider).user;
    final senderId = user?['_id'] ?? user?['id'];
    
    if (senderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to send messages')),
        );
      }
      return;
    }

    final optimisticMsg = {
      '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'content': text,
      'senderId': senderId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(optimisticMsg));
    _messageCtrl.clear();
    _scrollToBottom();

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/vaults/${widget.vaultId}/messages', data: {'content': text});
      
      if (mounted) {
        setState(() {
          final idx = _messages.indexOf(optimisticMsg);
          if (idx != -1) {
            _messages[idx] = Map<String, dynamic>.from(res.data['data']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.remove(optimisticMsg));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).leaveVault(widget.vaultId);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authViewModelProvider).user;
    final currentUserId = currentUser?['_id'] ?? currentUser?['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Secure Channel', style: TextStyle(color: NTColors.primary, fontSize: 16, fontWeight: FontWeight.w900)),
            Text('Vault: #${widget.vaultId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: NTColors.outline, fontSize: 10)),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: NTColors.secondary))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['senderId'].toString() == currentUserId.toString();
                    final time = msg['createdAt'] != null 
                      ? DateFormat('HH:mm').format(DateTime.parse(msg['createdAt']))
                      : 'Just now';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? NTColors.primary : NTColors.surfaceLow,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['content'] ?? '',
                              style: TextStyle(color: isMe ? Colors.white : NTColors.primary, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(color: isMe ? Colors.white70 : NTColors.outline, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: NTColors.surfaceLow, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageCtrl,
                decoration: const InputDecoration(hintText: 'Type secure message...', border: InputBorder.none),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: NTColors.secondary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
