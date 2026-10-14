const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seed() {

  // ─── CONFIG ───────────────────────────────────────────
  await db.collection('config').doc('appSettings').set({
    eventName: 'ISP Europe Conference 2026',
    eventLocation: 'Poland',
    totalLessons: 4,
    pointsForReading: 10,
    pointsForCorrectAnswer: 20,
    pointsForSpeedBonus: 5,
    pointsForCompletingAllQuestions: 15,
    speedBonusHours: 24,
  });
  console.log('✓ config/appSettings written');

  // ─── LESSON 1 ──────────────────────────────────────────
  await db.collection('lessons').doc('lesson_1').set({
    order: 1,
    dayNumber: 1,
    isVisible: true,
    pointsForReading: 10,
    totalQuestions: 6,
    title_en: 'Beginning Your Relationship with God',
    imageUrl: '',
    sections: [
      {
        order: 1,
        title_en: 'Beginning Your Relationship with God',
        isMainTitle: true,
        content_en: `The Bible explains that a Christian — a follower of Christ — is someone who has a personal relationship with God.

God uses the imagery of hospitality to give us a picture of this special relationship. In Revelation 3:20, Jesus says:

"Behold, I stand at the door and knock. If anyone hears my voice and opens the door, I will come in to him and eat with him, and he with me."

This is not a distant, formal connection. It is an intimate picture — sharing a meal together, talking, being present with one another. Christ offers to come in and dwell with those who invite Him.

The Bible also describes your relationship with God in terms of family. In John 1:12:

"But to all who received him, who believed in his name, he gave the right to become children of God."

To receive Christ and believe in His name means you are not just an acquaintance of God — you become His child. This is the foundation of what it means to be a Christian.`,
      },
      {
        order: 2,
        title_en: 'The Basis of Your Relationship with God',
        isMainTitle: false,
        content_en: `Many people think a person becomes a Christian based on where they were born, what kind of person they are, or what they have done for God. But the Bible says you become a Christian by faith — accepting what God has done for you through Jesus Christ.

In Colossians 1:21-22, Paul describes the before and after:

"Once you were alienated from God and were enemies in your minds because of your evil behavior. But now He has reconciled you by Christ's physical body through death to present you holy in his sight, without blemish and free from accusation."

Before Christ, we were separated from God — not strangers, but enemies. Yet God took action. Through the death of Jesus, He reconciled us and now sees us as holy, without blemish, and free from accusation.

Ephesians 2:4-5, 8-9 describes this as a gift:

"But God, being rich in mercy, because of the great love with which he loved us, even when we were dead in our sins, made us alive together with Christ — by grace you have been saved… For by grace you have been saved through faith. And this is not your own doing; it is the gift of God, not a result of works, so that no one may boast."

Salvation is not earned. It is received. God's gift comes to us not because of what we have done, but because of His great love and mercy. Our role is faith — trusting and receiving what He has already done.`,
      },
      {
        order: 3,
        title_en: 'Three Aspects of Your New Life',
        isMainTitle: false,
        content_en: `Jesus was clear about His purpose. In John 10:10 He says:

"I came that they may have life and have it abundantly."

2 Corinthians 5:17:

"Therefore, if anyone is in Christ, he is a new creation. The old has passed away; behold, the new has come."

The life God gives through Christ is not just life after death — it is a transformed life now. Abundant life means a new quality of living: new purpose, new identity, new direction. And it is accompanied by eternal life — a relationship with God that does not end at physical death.`,
      },
    ],
    questions: [
      {
        order: 1,
        type: 'multiple_choice',
        text_en: 'Colossians 1:21-22 says we were once alienated from God and enemies in our minds. What does it say God did about that?',
        options_en: [
          'He waited for us to change our behavior before approaching us',
          'He gave us a second chance to prove ourselves worthy',
          'He reconciled us through Christ\'s death, presenting us holy and free from accusation',
          'He forgave us conditionally, based on our future obedience',
        ],
        correctIndex: 2,
        points: 20,
      },
      {
        order: 2,
        type: 'open',
        text_en: 'Colossians 1:21 says we were enemies toward God in our minds. Looking back, how did that show up in your own thinking or attitude before you came to faith?',
        points: 0,
      },
      {
        order: 3,
        type: 'multiple_choice',
        text_en: 'Revelation 3:20 uses the image of sharing a meal. What does this communicate about the relationship God is offering?',
        options_en: [
          'A formal agreement between two parties',
          'A reward given to those who have been faithful',
          'A one-time encounter that opens the door to future blessing',
          'An intimate, unhurried presence — the kind shared between close friends',
        ],
        correctIndex: 3,
        points: 20,
      },
      {
        order: 4,
        type: 'open',
        text_en: 'Ephesians 2 says salvation is entirely a gift — nothing you contributed made it possible. Is that genuinely freeing, or does part of you resist that? Why?',
        points: 0,
      },
      {
        order: 5,
        type: 'multiple_choice',
        text_en: 'According to John 1:12, what happens when we receive Christ and believe in His name?',
        options_en: [
          'We commit to a life of religious discipline',
          'We become children of God',
          'We acknowledge His historical existence',
          'We are baptized and join a community of believers',
        ],
        correctIndex: 1,
        points: 20,
      },
      {
        order: 6,
        type: 'open',
        text_en: 'John 10:10 promises abundant life, and 2 Corinthians 5:17 says you are already a new creation. Where do you most see — or most want to see — evidence of that in your actual life right now?',
        points: 0,
      },
    ],
  });
  console.log('✓ lessons/lesson_1 written');

  // ─── LESSON 2 ──────────────────────────────────────────
  await db.collection('lessons').doc('lesson_2').set({
    order: 2,
    dayNumber: 2,
    isVisible: true,
    pointsForReading: 10,
    totalQuestions: 6,
    title_en: 'The Security of Your Relationship with God',
    imageUrl: '',
    sections: [
      {
        order: 1,
        title_en: 'The Security of Your Relationship with God',
        isMainTitle: true,
        content_en: `We have seen that God offers abundant life and a completely new identity in Christ. There is a third aspect of this new life: eternal life.

In 1 John 5:11-13, the apostle John writes:

"And this is the testimony that God gave us eternal life, and this life is in his Son. Whoever has the Son has life; whoever does not have the Son of God does not have life. I write these things to you who believe in the name of the Son of God that you may know that you have eternal life."

Notice that John does not say you might have eternal life, or that you will have it one day. He says you can know that you have it — right now. Eternal life is not simply about what happens after death; it begins the moment you place your faith in Christ.

Jesus himself defines what eternal life means in John 17:3:

"This is eternal life, that they know you the only true God, and Jesus Christ whom you have sent."

Eternal life is knowing God. It is a relationship — deep, personal, and lasting. The relationship you begin with God is eternal and continues forever, through difficult times and even through physical death. It is the most significant relationship you can have, and you can depend on it.`,
      },
      {
        order: 2,
        title_en: 'Certainty in Your Relationship with God',
        isMainTitle: false,
        content_en: `Trust is an essential element in any relationship. Christianity is based on faith, but the Bible is clear that you can know your relationship with God is secure — not merely hope for it.

1 John 5:13 says God wrote these things specifically so that you may know with certainty. When God gives us promises in the Bible, we can be sure they are true because God does not lie. His promises build a strong foundation.

There may be times when it is difficult to feel that God is with you. But your relationship with God is based on His trustworthy promise, not on your feelings.

Hebrews 13:5b-6:

"He has said, 'I will never leave you or forsake you.' So we can confidently say, 'The Lord is my helper; I will not fear; what can man do to me?'"

God's commitment to you is unconditional. He does not leave when life gets hard, when you struggle, or when you doubt.

Romans 8:38-39:

"For I am sure that neither death nor life, nor angels nor rulers, nor things present nor things to come, nor powers, nor height nor depth, nor anything else in all creation, will be able to separate us from the love of God in Christ Jesus our Lord."

Paul lists every possible category — death, life, supernatural powers, time, space — and declares that none of them can separate you from God's love. The security of your relationship does not rest on your ability to hold on to God. It rests on His ability to hold on to you.`,
      },
      {
        order: 3,
        title_en: 'The Shepherd Who Will Not Let Go',
        isMainTitle: false,
        content_en: `God describes our relationship with Jesus as one of care and protection. In John 10:27-29, Jesus uses the image of a shepherd:

"My sheep hear my voice, and I know them, and they follow me. I give them eternal life, and they will never perish, and no one will snatch them out of my hand. My Father, who has given them to me, is greater than all, and no one is able to snatch them out of the Father's hand."

Jesus says two things simultaneously: He knows you personally, and He holds you securely. Your name is known. Your life is held. The security of your relationship with God does not depend on your grip — it depends on His.

This is the foundation you can build your life on: not your feelings on a given day, not your performance, not how consistently you have followed — but the unbreakable promise of a God who says He will never let you go.`,
      },
    ],
    questions: [
      {
        order: 1,
        type: 'multiple_choice',
        text_en: 'John 17:3 defines eternal life not as endless duration but as something else entirely. What is it?',
        options_en: [
          'Knowing the only true God and Jesus Christ',
          'Freedom from suffering and death',
          'A reward granted at the final judgment',
          'A state of perfect peace after this life ends',
        ],
        correctIndex: 0,
        points: 20,
      },
      {
        order: 2,
        type: 'open',
        text_en: 'John 17:3 defines eternal life as knowing God — present tense, relational, not primarily future. How does that definition change what you think you already have?',
        points: 0,
      },
      {
        order: 3,
        type: 'multiple_choice',
        text_en: 'Romans 8:38-39 lists every possible force that cannot separate us from God\'s love. What is the theological weight of that exhaustive list?',
        options_en: [
          'It means there is no category of experience or power that can undo what God has secured',
          'It shows that most situations are covered, with a few exceptions',
          'It applies only to believers who have not deliberately walked away',
          'God\'s love is conditional on avoiding the most extreme circumstances',
        ],
        correctIndex: 0,
        points: 20,
      },
      {
        order: 4,
        type: 'open',
        text_en: 'Romans 8:38-39 says nothing in all creation can separate you from God\'s love. Is there anything in your life — a season, a pattern, a failure — that has made you doubt that? How does this verse speak to it?',
        points: 0,
      },
      {
        order: 5,
        type: 'multiple_choice',
        text_en: 'In John 10:27-29, Jesus references both His own hand and the Father\'s hand. What does this double reference emphasize?',
        options_en: [
          'The believer must hold on to both the Father and the Son',
          'The security of the believer is grounded in both — doubly guaranteed',
          'That there is a chain of command in the Trinity',
          'Physical protection is promised in addition to spiritual security',
        ],
        correctIndex: 1,
        points: 20,
      },
      {
        order: 6,
        type: 'open',
        text_en: 'Jesus says in John 10 that He knows His sheep and holds them securely. Your security rests on His grip, not yours. What does it look like, practically, to rest in that today?',
        points: 0,
      },
    ],
  });
  console.log('✓ lessons/lesson_2 written');

  // ─── LESSON 3 ──────────────────────────────────────────
  await db.collection('lessons').doc('lesson_3').set({
    order: 3,
    dayNumber: 3,
    isVisible: true,
    pointsForReading: 10,
    totalQuestions: 6,
    title_en: 'Fellowship and Its Hindrances',
    imageUrl: '',
    sections: [
      {
        order: 1,
        title_en: 'Fellowship and Its Hindrances',
        isMainTitle: true,
        content_en: `As you grow in your walk with God, it is helpful to understand that there are two distinct dimensions to your life with Him: your permanent relationship and your ongoing fellowship.

Your relationship with God is the foundation. When you placed your faith in Jesus Christ, God made you His child. John 1:12 says:

"But to all who did receive Him, who believed in His name, He gave the right to become children of God."

That relationship is secure and enduring. You will always be His child, and that will never change regardless of what you do or what may happen.

But God also wants that relationship to be close and fulfilling. He wants you to enjoy the kind of fellowship described in Revelation 3:20 — sharing a meal together, talking openly, being present with one another.

The difference between relationship and fellowship can be illustrated by a parent and child. The parent-child blood bond will always exist. However, certain things may cause the fellowship between them to be broken, affecting the quality of the relationship. The bond remains, but the closeness suffers.

1 John 1:3-4:

"And indeed our fellowship is with the Father and with his Son Jesus Christ. And we are writing these things so that our joy may be complete."

God's desire is not just that you belong to Him, but that your fellowship with Him brings you complete joy.`,
      },
      {
        order: 2,
        title_en: 'What Hinders Fellowship',
        isMainTitle: false,
        content_en: `Unlike the eternal relationship, fellowship with God is affected by the choices we make. Sin is the primary hindrance.

Sin can be a wrong action or attitude, or even the failure to do what pleases God. Before you accepted Jesus, your sin — your rejection of God and His will — kept you entirely from having a relationship with Him. But God provided a solution.

Romans 3:23-25:

"For all have sinned and fall short of the glory of God, and are justified by his grace as a gift, through the redemption that is in Christ Jesus, whom God put forward as a propitiation by his blood, to be received by faith."

Hebrews 10:10, 17-18:

"We have been made holy through the sacrifice of the body of Jesus Christ once for all… He adds, 'Their sins and lawless acts I will remember no more.' And where these have been forgiven, sacrifice for sin is no longer necessary."

Christ's death paid for sin — once, completely, and for all time. There is nothing you need to add to what He has already done.

Yet as a Christian, even though your sins are forgiven and you have new life, you still have the ability to sin. Old habits and desires can pull you away from God. When this happens, your fellowship with God is broken even though your relationship as His child remains intact.

How does God respond when His children sin? Psalm 103:10-13 gives a remarkable answer:

"He does not deal with us according to our sins, nor repay us according to our iniquities. For as high as the heavens are above the earth, so great is his steadfast love toward those who fear him; as far as the east is from the west, so far does he remove our sins from us. As a father shows compassion to his children, so the Lord shows compassion to those who fear him."

God does not respond to your sin with the punishment it deserves. He responds with steadfast love and compassion — the love of a Father for His child.`,
      },
      {
        order: 3,
        title_en: 'The Consequence of Sin on Fellowship',
        isMainTitle: false,
        content_en: `While God's love for you does not change, sin does carry consequences for the quality of your fellowship with Him. Isaiah 59:2 puts it plainly:

"But your iniquities have made a separation between you and your God, and your sins have hidden his face from you so that he does not hear."

When you sin as a Christian, you are still His child — nothing changes that. But the closeness, the openness, the joy of fellowship becomes strained. It is not that God turns away from you; it is that sin creates a barrier that affects your experience of His presence.

You do not lose your relationship with God when you sin, but you do lose the richness of fellowship with Him. And God, as a compassionate Father, has made a way to restore that closeness.`,
      },
    ],
    questions: [
      {
        order: 1,
        type: 'multiple_choice',
        text_en: 'What is the practical difference between relationship and fellowship with God, and why does it matter?',
        options_en: [
          'Relationship is the permanent bond; fellowship is the day-to-day closeness that can be affected by sin',
          'They are essentially the same, just described from different angles',
          'Relationship is for new believers; fellowship develops later with maturity',
          'Fellowship is corporate — it only happens in community with others',
        ],
        correctIndex: 0,
        points: 20,
      },
      {
        order: 2,
        type: 'open',
        text_en: 'The parent-child illustration separates relationship from fellowship. Is there a difference in your own experience between knowing you belong to God and actually feeling close to Him? What tends to widen or narrow that gap?',
        points: 0,
      },
      {
        order: 3,
        type: 'multiple_choice',
        text_en: 'Psalm 103:10-13 says God does not deal with us according to our sins. What does this reveal about His response to a believer who has sinned?',
        options_en: [
          'God overlooks sin entirely because of His love',
          'God responds with measured discipline proportional to each offense',
          'God waits silently until the believer initiates reconciliation',
          'God responds with compassion exceeding what justice would demand — not punishment we deserve',
        ],
        correctIndex: 3,
        points: 20,
      },
      {
        order: 4,
        type: 'open',
        text_en: 'Psalm 103:10-13 says God\'s response to our sin is compassion — not what we deserve. Does that picture of God match the one you carry day to day, or is there a gap between what you intellectually know and what you emotionally expect from Him?',
        points: 0,
      },
      {
        order: 5,
        type: 'multiple_choice',
        text_en: 'Isaiah 59:2 says sin hides God\'s face from us. In the context of the relationship vs. fellowship distinction, what is this describing?',
        options_en: [
          'A disruption in the experiential closeness of fellowship, not the loss of the relationship itself',
          'A sign that the person was never truly saved',
          'God\'s permanent withdrawal from unrepentant believers',
          'Loss of salvation',
        ],
        correctIndex: 0,
        points: 20,
      },
      {
        order: 6,
        type: 'open',
        text_en: '1 John 1:3-4 says complete joy comes through fellowship with the Father and Son. Where are you experiencing that joy right now, and where do you feel its absence?',
        points: 0,
      },
    ],
  });
  console.log('✓ lessons/lesson_3 written');

  // ─── LESSON 4 ──────────────────────────────────────────
  await db.collection('lessons').doc('lesson_4').set({
    order: 4,
    dayNumber: 4,
    isVisible: true,
    pointsForReading: 10,
    totalQuestions: 6,
    title_en: 'Restoring Fellowship — and Carrying It Outward',
    imageUrl: '',
    sections: [
      {
        order: 1,
        title_en: 'Restoring Fellowship — and Carrying It Outward',
        isMainTitle: true,
        content_en: `We have seen that sin creates a barrier in our fellowship with God, even though our relationship as His children remains secure. Isaiah 59:2 describes the effect:

"But your iniquities have made a separation between you and your God, and your sins have hidden his face from you so that he does not hear."

When you sin as a Christian, you do not lose your salvation. But you begin to become estranged from God — the closeness fades, the joy dims, and the connection feels distant. God has not moved; the barrier is on our side.

The good news is that God, as a compassionate Father, has made it possible to fully restore that fellowship — even after you have disobeyed, ignored, or betrayed Him. He is willing to do this because you are now in Christ, and every sin — past, present, and future — was paid for when Christ gave His life for you.`,
      },
      {
        order: 2,
        title_en: 'How Fellowship Is Restored: Confession',
        isMainTitle: false,
        content_en: `You restore fellowship by turning back to God and expressing your sorrow for the sin, your thankfulness for His forgiveness, and your desire to change. This is called confession or repentance.

1 John 1:8-9:

"If we say we have no sin, we deceive ourselves, and the truth is not in us. If we confess our sins, he is faithful and just to forgive us our sins and to cleanse us from all unrighteousness."

God's response to honest confession is not reluctant — He is faithful and just to forgive. Forgiveness is not uncertain. It flows from His character.

Three steps to restoring fellowship:

1. Acknowledge to God that your sin was wrong — and that it has become a barrier to your fellowship with Him.

2. Thank God that He has already paid for that sin and forgives you — on the basis of Jesus' death.

3. Ask God to change your heart — so that next time you choose God's way rather than your own.

Romans 8:1:

"There is therefore now no condemnation for those who are in Christ Jesus."

There is no reason to carry guilt after genuine confession. No shame, no lingering condemnation — you are clean.`,
      },
      {
        order: 3,
        title_en: 'David\'s Experience: The Cost and the Relief',
        isMainTitle: false,
        content_en: `In Psalm 32:1-5, David shares what it felt like to carry unconfessed sin — and what it felt like when fellowship was finally restored:

"Blessed is the one whose transgression is forgiven, whose sin is covered. Blessed is the man against whom the Lord counts no iniquity, and in whose spirit there is no deceit. For when I kept silent, my bones wasted away through my groaning all day long. For day and night your hand was heavy upon me; my strength was dried up as by the heat of summer. I acknowledged my sin to you, and I did not cover my iniquity; I said, 'I will confess my transgressions to the Lord,' and you forgave the guilt of my sin."

Before confession, David describes physical and emotional weight — groaning, weakness, a heaviness that wore him down. This is what unconfessed sin does: it burdens us even when we think we are managing it.

After confession, the guilt is gone. The relationship is open again. He begins with the word blessed — not because his life is suddenly perfect, but because the weight has been lifted and fellowship is restored.`,
      },
      {
        order: 4,
        title_en: 'Building on Love, Not Guilt',
        isMainTitle: false,
        content_en: `Thankfulness for what God has graciously done and continues to do for you is vital to developing a closer relationship with Him.

Your relationship with God should be built on love and appreciation, not on guilt and obligation. When you come to God primarily out of fear of punishment, you are not experiencing the fellowship He designed. But when you come to Him with gratitude — aware of what He has done, how He has forgiven, and how He has remained faithful — that becomes the soil in which a deep and lasting friendship with God grows.

This is the pattern: you sin, you confess, you receive forgiveness, and you respond with gratitude. Over time, that cycle of grace and thankfulness shapes you into someone who increasingly chooses God's way — not because you have to, but because you want to.`,
      },
      {
        order: 5,
        title_en: 'Carrying It Outward: Salt and Light',
        isMainTitle: false,
        content_en: `A restored, living fellowship with God is not meant to stay private. In Colossians 4:2-3, Paul writes:

"Devote yourselves to prayer, being watchful and thankful. And pray for us, too, that God may open a door for our message, so that we may proclaim the mystery of Christ."

God uses people who are walking closely with Him to open doors for others to find Him. He has given us a practical framework for how that happens — not through confrontation or pressure, but through six natural steps:

PRAY · NOTICE · SERVE · ASK · LISTEN · SHARE

PRAY — Colossians 4:2-3: "Devote yourselves to prayer, being watchful and thankful. And pray for us, too, that God may open a door for our message." Everything begins with prayer. Pray for the people around you who do not yet know God. Pray that you will be watchful and thankful for what God is already doing in their lives to draw them toward Himself.

NOTICE — Matthew 9:36: "When he saw the crowds, he had compassion on them, because they were harassed and helpless, like sheep without a shepherd." Jesus noticed people — their pain, their lostness, what they were carrying. To notice someone the way Jesus did means paying attention to what brings them joy, what they're struggling with, what questions they carry.

SERVE — Mark 10:45: "...did not come to be served, but to serve, and to give his life as a ransom for many." Serving someone shows genuine care. It builds trust and relationship, and it often creates curiosity — people begin to wonder why you treat them this way.

ASK — Jesus regularly asked questions that caused people to think about what they actually wanted. Asking sincere questions invites someone into a real conversation. Begin with what is casual and easy; as trust grows, move toward deeper questions.

LISTEN — James 1:19: "Let every person be quick to hear, slow to speak." Listening carefully demonstrates that you genuinely value the other person. If you are quiet and present, without rushing to offer answers, you will hear what is actually on their heart.

SHARE — 1 Peter 3:15: "Always be prepared to give an answer to everyone who asks you to give the reason for the hope that you have. But do this with gentleness and respect." Sharing is not a monologue or a presentation — it is offering a glimpse of what God has done in your life.

The foundation of all six steps is the same fellowship with God you have been building across these lessons. You cannot give away what you do not have. But as you walk closely with Him — confessing, receiving forgiveness, responding with gratitude — you become the kind of person whose life naturally creates questions in others.`,
      },
    ],
    questions: [
      {
        order: 1,
        type: 'multiple_choice',
        text_en: '1 John 1:9 says God is faithful and just to forgive. Why is "just" a significant word — not just merciful or kind?',
        options_en: [
          'It suggests God forgives reluctantly because justice requires it',
          'It means God has a legal obligation based on our sincerity',
          'It points to the fact that Christ already paid for the sin, so forgiveness is legally grounded in what He did',
          'It is a reminder that unforgiven sin will still be judged at the end',
        ],
        correctIndex: 2,
        points: 20,
      },
      {
        order: 2,
        type: 'open',
        text_en: '1 John 1:9 says God is faithful and just to forgive. Is there anything you are still carrying — guilt, shame, a sense that a particular sin is too much — that this promise speaks directly to?',
        points: 0,
      },
      {
        order: 3,
        type: 'multiple_choice',
        text_en: 'David in Psalm 32 describes unconfessed sin as "bones wasting away" and "strength dried up." What does this suggest?',
        options_en: [
          'Only major sins produce this kind of weight',
          'The burden of hidden sin affects us whether we acknowledge it or not',
          'David had a weaker faith than most believers today',
          'God actively punishes us physically when we sin',
        ],
        correctIndex: 1,
        points: 20,
      },
      {
        order: 4,
        type: 'open',
        text_en: 'The lesson distinguishes between a relationship built on love and appreciation versus one built on guilt and obligation. Which of those two is more honest about where you are right now?',
        points: 0,
      },
      {
        order: 5,
        type: 'multiple_choice',
        text_en: 'In the Six Steps, why does Pray come first — before any action toward another person?',
        options_en: [
          'It orients your heart toward what God is already doing and guards against treating people as a project',
          'Prayer is a religious formality that must precede other activities',
          'It is the easiest step and builds momentum for the harder ones',
          'It ensures God is obligated to bless your efforts',
        ],
        correctIndex: 0,
        points: 20,
      },
      {
        order: 6,
        type: 'open',
        text_en: 'Of the six steps — Pray, Notice, Serve, Ask, Listen, Share — which comes most naturally to you, and which genuinely challenges you? What do you think that reveals?',
        points: 0,
      },
    ],
  });
  console.log('✓ lessons/lesson_4 written');

  console.log('\nSeed complete.');
  process.exit(0);
}

seed().catch(err => {
  console.error(err);
  process.exit(1);
});
