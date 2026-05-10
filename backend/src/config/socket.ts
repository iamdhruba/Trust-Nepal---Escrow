import { Server, Socket } from 'socket.io';
import { Server as HttpServer } from 'http';
import pino from 'pino';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';

const logger = pino();

// Read public key for JWT verification
const PUBLIC_KEY = fs.readFileSync(path.join(process.cwd(), 'keys/public.pem'), 'utf8');

let io: Server;

// Extend Socket interface to hold authenticated user data
interface AuthenticatedSocket extends Socket {
  data: {
    userId: string;
  };
}

export const setupSocket = (server: HttpServer) => {
  io = new Server(server, {
    cors: {
      origin: '*', // In production, restrict to allowed origins
    },
  });

  // JWT Authentication Middleware
  io.use((socket: Socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers['authorization'];
    
    if (!token) {
      return next(new Error('Authentication token required'));
    }

    try {
      // Remove 'Bearer ' if present
      const cleanToken = token.replace('Bearer ', '');
      const payload = jwt.verify(cleanToken, PUBLIC_KEY, { algorithms: ['RS256'] }) as any;
      
      // Attach verified user ID to the socket
      socket.data.userId = payload.sub;
      next();
    } catch (error) {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const authSocket = socket as AuthenticatedSocket;
    const userId = authSocket.data.userId;
    
    logger.info({ socketId: authSocket.id, userId }, 'New authenticated socket connection');

    // Automatically join the user to their personal notification room
    const userRoom = `user:${userId}`;
    authSocket.join(userRoom);
    console.log(`[SOCKET] User ${userId} joined room: ${userRoom} (Socket: ${authSocket.id})`);

    // The client should no longer emit 'join_user' as it's handled securely on connection.
    // However, keeping this stub for backward compatibility (but ignoring the provided ID)
    authSocket.on('join_user', () => {
      logger.debug('Ignored join_user event as user is auto-joined securely.');
    });

    authSocket.on('join_vault', async (vaultId: string) => {
      // Security Check: Ensure user belongs to the vault
      try {
        const { VaultModel } = await import('../modules/vault/vault.model.js');
        const vault = await VaultModel.findById(vaultId);
        
        if (!vault) {
          return authSocket.emit('error', { message: 'Vault not found' });
        }
        
        if (vault.buyerId.toString() !== userId && vault.sellerId.toString() !== userId) {
          logger.warn({ vaultId, userId }, 'Unauthorized attempt to join vault room');
          return authSocket.emit('error', { message: 'Forbidden' });
        }
        
        authSocket.join(`vault:${vaultId}`);
        logger.info({ socketId: authSocket.id, vaultId }, 'Joined vault room securely');
      } catch (error) {
        logger.error(error, 'Error joining vault room');
      }
    });

    authSocket.on('leave_vault', (vaultId: string) => {
      authSocket.leave(`vault:${vaultId}`);
      logger.info({ socketId: authSocket.id, vaultId }, 'Left vault room');
    });

    // Chat messages now STRICTLY use the authenticated userId as the senderId
    authSocket.on('chat_message', async (data: { vaultId: string, content: string }) => {
      try {
        const { VaultModel } = await import('../modules/vault/vault.model.js');
        const vault = await VaultModel.findById(data.vaultId);
        
        if (!vault || (vault.buyerId.toString() !== userId && vault.sellerId.toString() !== userId)) {
           return authSocket.emit('error', { message: 'Forbidden' });
        }

        const { MessageModel } = await import('../modules/vault/message.model.js');
        const msg = await MessageModel.create({
          vaultId: data.vaultId,
          senderId: userId, // CRITICAL FIX: Use verified token ID, ignore client input
          content: data.content,
        });

        io.to(`vault:${data.vaultId}`).emit('new_chat_message', {
          _id: msg._id,
          vaultId: data.vaultId,
          content: data.content,
          senderId: userId,
          createdAt: msg.createdAt,
        });
        logger.info({ vaultId: data.vaultId, senderId: userId }, 'Secure chat message saved and sent');
      } catch (error) {
        logger.error(error, 'Failed to save chat message');
      }
    });

    authSocket.on('disconnect', () => {
      logger.info({ socketId: authSocket.id, userId }, 'Authenticated socket disconnected');
    });
  });

  return io;
};

export const getIO = () => {
  if (!io) {
    throw new Error('Socket.io not initialized');
  }
  return io;
};
