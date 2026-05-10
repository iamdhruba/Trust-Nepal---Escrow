import { Router } from 'express';
import { DisputeService } from './dispute.service.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = Router();
const disputeService = new DisputeService();

router.post('/', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const dispute = await disputeService.raiseDispute(req.body, actorId);
    res.status(201).json({ success: true, data: dispute });
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/resolve', authenticate, async (req, res, next) => {
  try {
    const adminId = (req as any).user.sub;
    // TODO: Add admin role check middleware
    const dispute = await disputeService.resolveDispute(req.params.id!, req.body, adminId);
    res.json({ success: true, data: dispute });
  } catch (error) {
    next(error);
  }
});

export default router;
