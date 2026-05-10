import { Router } from 'express';
import * as KYCController from './kyc.controller.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = Router();

router.post('/', authenticate, KYCController.submitKYC);
router.get('/status', authenticate, KYCController.getKYCStatus);

export default router;
