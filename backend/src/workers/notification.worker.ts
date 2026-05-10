import { getAgenda } from '../config/agenda.js';
import pino from 'pino';
import { createNotification } from '../modules/notifications/notification.model.js';
import { VaultState } from '../modules/vault/vault.model.js';
import { getIO } from '../config/socket.js';
import { UserModel } from '../modules/user/user.model.js';
import { getFirebaseAdmin } from '../config/firebase.js';

const logger = pino({ name: 'notification-worker' });

export const defineNotificationJobs = () => {
  const agenda = getAgenda();

  agenda.define('notification.send', async (job: any) => {
    const { vaultId, state, buyerId, sellerId } = job.attrs.data;
    
    console.log(`[WORKER] Received notification job for vault ${vaultId}, state ${state}`);
    logger.info({ vaultId, state }, 'Processing notification');

    try {
      let buyerTitle = '';
      let buyerBody = '';
      let sellerTitle = '';
      let sellerBody = '';

      switch (state) {
        case VaultState.INITIATED:
          buyerTitle = 'Vault Initiated';
          buyerBody = 'You have successfully created an escrow vault. The seller has been notified.';
          sellerTitle = 'New Escrow Vault';
          sellerBody = 'A buyer has initiated an escrow vault for you. Please check the details.';
          break;
        case VaultState.FUNDED:
          buyerTitle = 'Payment Secured';
          buyerBody = 'Your payment is safely held in escrow. The seller can now ship the item.';
          sellerTitle = 'Funds Secured';
          sellerBody = 'The buyer has funded the vault. You can now proceed with shipping.';
          break;
        case VaultState.SHIPPED:
          buyerTitle = 'Item Shipped';
          buyerBody = 'The seller has marked the item as shipped. Track your delivery.';
          sellerTitle = 'Shipment Confirmed';
          sellerBody = 'You have successfully marked the item as shipped.';
          break;
        case VaultState.DELIVERED:
          buyerTitle = 'Item Delivered';
          buyerBody = 'The item has been marked as delivered. Please confirm receipt to release funds.';
          sellerTitle = 'Delivery Confirmed';
          sellerBody = 'The item has been delivered. Funds will be released once the buyer confirms.';
          break;
        case VaultState.COMPLETED:
          buyerTitle = 'Transaction Complete';
          buyerBody = 'Transaction successful! Funds have been released to the seller.';
          sellerTitle = 'Funds Released';
          sellerBody = 'The buyer has confirmed receipt. Funds are being transferred to your account.';
          break;
        case VaultState.DISPUTED:
          buyerTitle = 'Dispute Opened';
          buyerBody = 'A dispute has been opened for this vault. Our team will review the case.';
          sellerTitle = 'Dispute Opened';
          sellerBody = 'The buyer has opened a dispute. Please provide any necessary evidence.';
          break;
        case VaultState.CANCELLED:
          buyerTitle = 'Vault Cancelled';
          buyerBody = 'The vault has been cancelled.';
          sellerTitle = 'Vault Cancelled';
          sellerBody = 'The buyer has cancelled the vault.';
          break;
        case VaultState.REFUNDED:
          buyerTitle = 'Refund Issued';
          buyerBody = 'Funds have been refunded to your original payment method.';
          sellerTitle = 'Refund Processed';
          sellerBody = 'The vault funds have been refunded to the buyer.';
          break;
      }

      const jobs = [];
      if (buyerTitle && buyerId) {
        jobs.push(createNotification(buyerId, state, buyerTitle, buyerBody, { vaultId }));
      }
      if (sellerTitle && sellerId) {
        jobs.push(createNotification(sellerId, state, sellerTitle, sellerBody, { vaultId }));
      }

      if (jobs.length > 0) {
        const notifications = await Promise.all(jobs);
        console.log(`[WORKER] Successfully created ${notifications.length} notifications in DB`);
        logger.info({ vaultId, state }, 'Notifications created in database');
        
        // Real-time socket emission
        try {
          const io = getIO();
          notifications.forEach(notif => {
            const room = `user:${notif.userId.toString()}`;
            console.log(`[WORKER] Emitting new_notification to room: ${room}`);
            io.to(room).emit('new_notification', notif);
          });
          logger.info('Notifications emitted via socket');
        } catch (ioErr: any) {
          console.error(`[WORKER_SOCKET_ERROR] ${ioErr.message}`);
          logger.warn('Socket.io not available for notification emission');
        }
      }
      
      // FCM Push Logic
      try {
        const admin = getFirebaseAdmin();
        const fcmMessages: any[] = [];

        // Fetch users to get FCM tokens
        const userIds = [buyerId, sellerId].filter(Boolean);
        if (userIds.length > 0) {
          const users = await UserModel.find({ _id: { $in: userIds } }).select('_id fcmTokens');
          
          for (const user of users) {
            if (!user.fcmTokens || user.fcmTokens.length === 0) continue;

            const isBuyer = user._id.toString() === buyerId?.toString();
            const title = isBuyer ? buyerTitle : sellerTitle;
            const body = isBuyer ? buyerBody : sellerBody;

            if (title && body) {
              user.fcmTokens.forEach((token: string) => {
                fcmMessages.push({
                  notification: { title, body },
                  data: { vaultId: vaultId.toString(), state },
                  token
                });
              });
            }
          }
        }

        if (fcmMessages.length > 0) {
          const response = await admin.messaging().sendEach(fcmMessages);
          logger.info({ successCount: response.successCount, failureCount: response.failureCount }, 'FCM notifications sent');
        }
      } catch (fcmErr: any) {
        logger.error({ error: fcmErr.message }, 'Failed to send FCM notifications');
      }
    } catch (error: any) {
      logger.error({ vaultId, error: error.message }, 'Failed to process notification');
      throw error;
    }
  });
};
