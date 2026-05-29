// run with: cd scripts && node seed.js

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
    totalQuestions: 4,
    title_en: 'The Power of Community',
    imageUrl: '',
    sections: [
      {
        order: 1,
        title_en: 'The Power of Community',
        isMainTitle: true,
        content_en:
          'There is something remarkable that happens when teachers gather together with a shared purpose. The walls that normally separate classrooms, subjects, and schools begin to dissolve. What replaces them is something far more powerful — a sense of belonging, of being understood, and of moving forward together.\n\nFor many educators, teaching can be one of the loneliest professions. You pour yourself into your students, you prepare lessons late into the night, and you face challenges that few outside the classroom truly understand. The weight of responsibility — shaping young minds, navigating difficult families, managing an ever-changing curriculum — is rarely shared.\n\nBut it was never meant to be carried alone.',
      },
      {
        order: 2,
        title_en: 'Why Community Matters',
        isMainTitle: false,
        content_en:
          'Research consistently shows that teachers who are part of strong professional communities are more effective, more resilient, and more fulfilled in their work. A study by the Bill & Melinda Gates Foundation found that teachers who collaborated regularly with peers showed significantly higher student achievement than those who worked in isolation.\n\nBut beyond the data, there is something deeply human about community. We were created for connection. The book of Proverbs reminds us that \'as iron sharpens iron, so one person sharpens another.\' This is not just a metaphor — it is a design principle.\n\nWhen we come together — sharing what works, being honest about what doesn\'t, praying for one another\'s students and families — we become something greater than the sum of our parts.',
      },
      {
        order: 3,
        title_en: 'The ISP Vision',
        isMainTitle: false,
        content_en:
          'The International School Project was built on this conviction: that a community of Christ-directed teachers, equipped and connected, can transform not just classrooms but entire cities and nations.\n\nOver the past 30 years, ISP has seen this vision come to life in country after country. Teachers who once felt isolated discovering others who share their faith and their calling. Small groups forming in staffrooms and coffee shops. Friendships crossing language barriers, cultural differences, and denominational lines.\n\nThis week in Poland, you are part of that story. The people sitting around you — from Romania, from Bulgaria, from Ukraine, from Germany and beyond — are your community. You may have just met, but you are already connected by something deeper than geography or language.\n\nYou are connected by a calling.',
      },
      {
        order: 4,
        title_en: 'Reflection',
        isMainTitle: false,
        content_en:
          'Take a moment to consider your own experience of community in teaching.\n\nPerhaps you have been fortunate enough to work alongside colleagues who encouraged and challenged you. Perhaps you have felt the loneliness of walking into a staffroom where no one truly understood what you were carrying.\n\nEither way, this week is an invitation. An invitation to be known. To be sharpened. To be sent back to your classroom, your school, your city — not alone, but as part of a movement of educators who believe that teaching is more than a profession.\n\nIt is a calling. And callings are always better answered together.\n\n\'The harvest is great, but the workers are few. So pray to the Lord who is in charge of the harvest; ask him to send more workers into his fields.\' — Matthew 9:37-38',
      },
    ],
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
