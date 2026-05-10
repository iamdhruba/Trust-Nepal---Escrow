import { Router } from 'express';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { authenticate } from '../../middleware/auth.middleware.js';
import { VaultModel } from '../vault/vault.model.js';
import { AppError } from '../../errors/AppError.js';

const router = Router();
const s3 = new S3Client({ region: process.env.AWS_REGION || 'ap-south-1' });
const BUCKET = process.env.S3_BUCKET || 'nepaltrust-uploads-dev';

/**
 * GET /api/v1/invoices/:vaultId
 * Returns a presigned S3 URL for the invoice PDF.
 * Only the buyer, seller, or admin can access.
 */
router.get('/:vaultId', authenticate, async (req, res, next) => {
  try {
    const { vaultId } = req.params;
    const userId = (req as any).user.sub;
    const userRoles: string[] = (req as any).user.roles || [];

    const vault = await VaultModel.findById(vaultId);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');

    const isAdmin = userRoles.some(r => ['ADMIN', 'COMPLIANCE', 'SUPPORT'].includes(r));
    const isBuyer = vault.buyerId.toString() === userId;
    const isSeller = vault.sellerId.toString() === userId;

    if (!isAdmin && !isBuyer && !isSeller) {
      throw new AppError('Forbidden', 403, 'FORBIDDEN');
    }

    const key = `invoice/${vaultId}/invoice.pdf`;
    const command = new GetObjectCommand({ Bucket: BUCKET, Key: key });
    const presignedUrl = await getSignedUrl(s3, command, { expiresIn: 300 }); // 5 min

    res.json({ success: true, data: { url: presignedUrl, expiresIn: 300 } });
  } catch (error) {
    next(error);
  }
});

export default router;
