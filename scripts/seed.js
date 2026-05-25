// HOW TO RUN:
// 1. cd scripts
// 2. npm init -y
// 3. npm install firebase-admin
// 4. node seed.js

// SERVICE ACCOUNT KEY:
// Download from Firebase Console:
//   Project Settings → Service Accounts → Generate New Private Key
// Save the downloaded file as: scripts/serviceAccountKey.json

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'ispapp-9f09d',
});

const db = admin.firestore();

async function seed() {
  await db.collection('lessons').doc('lesson_1').set({
    order: 1,
    dayNumber: 1,
    isVisible: true,
    pointsForReading: 10,
    title_en: 'The Power of Community',
    content_en:
      'When teachers come together, something remarkable happens. The isolation that so many educators feel begins to dissolve, replaced by a sense of shared purpose and mutual support. Research consistently shows that teacher communities not only improve professional outcomes, but transform the emotional landscape of schools entirely. As educators, we are called to more than just deliver content — we are called to build each other up, to sharpen one another, and to walk together through the challenges of our calling.',
    imageUrl: '',
    totalQuestions: 0,
  });
  console.log('✓ lessons/lesson_1 written');

  await db.collection('config').doc('appSettings').set({
    eventName: 'ISP Europe Conference 2026',
    eventLocation: 'Poland',
    totalLessons: 1,
    pointsForReading: 10,
    pointsForCorrectAnswer: 20,
    pointsForSpeedBonus: 5,
    pointsForCompletingAllQuestions: 15,
    speedBonusHours: 24,
  });
  console.log('✓ config/appSettings written');

  console.log('Seed complete.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
