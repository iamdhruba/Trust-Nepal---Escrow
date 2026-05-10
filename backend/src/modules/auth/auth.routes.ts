import { Router } from 'express';
import * as AuthController from './auth.controller.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = Router();

router.post('/otp/send', AuthController.sendOTP);
router.post('/otp/verify', AuthController.verifyOTP);
router.post('/firebase/verify', AuthController.verifyFirebase);
router.post('/refresh', AuthController.refresh);
router.post('/logout', authenticate, AuthController.logout);

export default router;
