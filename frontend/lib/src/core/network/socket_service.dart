import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/presentation/auth_viewmodel.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(ref);
});

class SocketService {
  final Ref _ref;
  io.Socket? _socket;
  final _storage = const FlutterSecureStorage();

  SocketService(this._ref);

  static String get socketUrl {
    return ApiClient.baseUrl.replaceAll('/api/v1', '');
  }

  Future<void> connect() async {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final token = await _storage.read(key: 'nt.access_token');
    
    if (token == null) {
      print('[SOCKET] Cannot connect: No auth token found.');
      return;
    }

    _socket = io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'auth': {'token': token},
    });
    
    _socket!.onConnect((_) {
      print('[SOCKET] Connected securely to: $socketUrl');
    });

    _socket!.onReconnect((_) => print('[SOCKET] Reconnected securely'));
    
    _socket!.onDisconnect((_) {
      print('[SOCKET] Disconnected from socket server');
    });
  }

  void joinUser(String userId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_user', userId.toString());
      print('[SOCKET] Joined user room: user:$userId');
    } else {
      _socket?.once('connect', (_) => joinUser(userId));
    }
  }

  void joinVault(String vaultId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_vault', vaultId.toString());
    } else {
      _socket?.once('connect', (_) => joinVault(vaultId));
    }
  }

  void leaveVault(String vaultId) {
    _socket?.emit('leave_vault', vaultId.toString());
  }

  void onNotification(Function(dynamic) callback) {
    _socket?.on('new_notification', callback);
  }

  void onVaultStateChanged(Function(dynamic) callback) {
    _socket?.on('vault_state_changed', callback);
  }

  void onChatMessage(Function(dynamic) callback) {
    _socket?.on('new_chat_message', callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
