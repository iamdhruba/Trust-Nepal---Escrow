import { Router } from 'express';
import { authenticate } from '../../middleware/auth.middleware.js';
import { z } from 'zod';
import crypto from 'crypto';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const router = Router();

import { S3Client } from '@aws-sdk/client-s3';
import multerS3 from 'multer-s3';

const s3 = new S3Client({
  region: process.env.AWS_REGION || 'ap-south-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || ''
  }
});

// Configure Multer for S3 Storage
const storage = multerS3({
  s3: s3,
  bucket: process.env.S3_BUCKET || 'trustnepal-uploads',
  contentType: multerS3.AUTO_CONTENT_TYPE,
  key: function (req, file, cb) {
    const userId = (req as any).user?.sub || 'anonymous';
    const purpose = (req as any).body?.purpose || 'misc';
    const ext = path.extname(file.originalname);
    cb(null, `${purpose}/${userId}-${crypto.randomUUID()}${ext}`);
  }
});

// Allowed MIME types
const ALLOWED_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'video/mp4': 'mp4',
  'application/pdf': 'pdf',
};

const upload = multer({ 
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    if (ALLOWED_TYPES[file.mimetype]) {
      cb(null, true);
    } else {
      cb(new Error('Unsupported file type. Only JPG, PNG, MP4, and PDF are allowed.'));
    }
  }
});


/**
 * POST /api/v1/uploads/upload
 * Uploads a file to AWS S3.
 */
router.post('/upload', authenticate, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    // MulterS3 adds 'location' and 'key' to the file object
    const file = req.file as any;
    
    res.json({
      success: true,
      data: {
        fileUrl: file.location, // S3 Public URL
        key: file.key,          // S3 Key (path)
      }
    });
  } catch (error) {
    next(error);
  }
});

export default router;
