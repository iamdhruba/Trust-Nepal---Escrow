import { Router } from 'express';
import { authenticate } from '../../middleware/auth.middleware.js';
import { NotificationModel } from './notification.model.js';

const router = Router();

// ── GET /notifications — Paginated notification list ──────────────────────
router.get('/', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    const [notifications, total, unread] = await Promise.all([
      NotificationModel.find({ userId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      NotificationModel.countDocuments({ userId }),
      NotificationModel.countDocuments({ userId, read: false }),
    ]);

    res.json({
      success: true,
      data: notifications,
      meta: { page, limit, total, unread, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
});

// ── PATCH /notifications/:id/read — Mark single as read ───────────────────
router.patch('/:id/read', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    await NotificationModel.findOneAndUpdate(
      { _id: req.params.id, userId },
      { read: true },
    );
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

// ── PATCH /notifications/read-all — Mark all as read ──────────────────────
router.patch('/read-all', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    await NotificationModel.updateMany({ userId, read: false }, { read: true });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

export default router;
