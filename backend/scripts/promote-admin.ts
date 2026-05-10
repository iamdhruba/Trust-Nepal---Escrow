import 'dotenv/config';
import mongoose from 'mongoose';
import { UserModel } from '../src/modules/user/user.model.js';

const phone = process.argv[2];

if (!phone) {
  console.error('Please provide a phone number: npm run promote-admin -- 98XXXXXXXX');
  process.exit(1);
}

const MONGO_URI = process.env.MONGO_URI || 'mongodb://admin:password123@localhost:27017/nepaltrust?authSource=admin';

async function promote() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    const user = await UserModel.findOne({ phone });
    if (!user) {
      console.log(`User with phone ${phone} not found. Creating new ADMIN user...`);
      await UserModel.create({
        phone,
        role: ['ADMIN', 'BUYER', 'VERIFIED_USER'],
        isActive: true,
        kyc: { status: 'APPROVED' }
      });
      console.log(`User ${phone} created with ADMIN role.`);
    } else {
      if (!user.role.includes('ADMIN')) {
        user.role.push('ADMIN');
      }
      if (!user.role.includes('VERIFIED_USER')) {
        user.role.push('VERIFIED_USER');
      }
      user.kyc.status = 'APPROVED';
      await user.save();
      console.log(`User ${phone} promoted to ADMIN.`);
    }

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

promote();
