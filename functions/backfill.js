const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

function generateSearchTokens(topic, summary, keywords) {
  const combined = `${topic} ${summary} ${keywords.join(' ')}`;
  const rawTokens = combined.toLowerCase().replace(/[^\w\s]/g, '').split(/\s+/);
  return [...new Set(rawTokens.filter((t) => t.length > 1))];
}

(async () => {
  console.log('Fetching all transcript segments...');
  const snapshot = await db.collection('transcript_segments').get();
  
  if (snapshot.empty) {
    console.log('No segments found.');
    process.exit(0);
  }

  const batch = db.batch();
  let count = 0;

  snapshot.forEach((doc) => {
    const data = doc.data();
    if (!data.searchTerms && data.topic && data.summary && data.keywords) {
      const searchTerms = generateSearchTokens(data.topic, data.summary, data.keywords);
      batch.update(doc.ref, { searchTerms });
      count++;
    }
  });

  if (count > 0) {
    await batch.commit();
    console.log(`Successfully updated ${count} segments with searchTerms.`);
  } else {
    console.log('All segments already have searchTerms.');
  }

  process.exit(0);
})();
