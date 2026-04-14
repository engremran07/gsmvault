/**
 * Normalize invoice numbers in jobs collection:
 * 1) Remove leading INV-/INV prefix from invoiceNumber.
 * 2) Merge duplicate job docs with same normalized invoice into one document.
 *
 * Usage:
 *   cd scripts
 *   node normalize_invoice_data.js
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.join(__dirname, 'service-account.json');

try {
  const serviceAccount = require(serviceAccountPath);
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: 'actechs-d415e',
    });
  }
} catch (e) {
  console.error('Missing scripts/service-account.json.');
  process.exit(1);
}

const db = admin.firestore();

function normalizeInvoice(invoice) {
  const trimmed = String(invoice || '').trim();
  if (!trimmed) return '';
  const upper = trimmed.toUpperCase();
  if (upper.startsWith('INV-')) return trimmed.slice(4).trim();
  if (upper.startsWith('INV ')) return trimmed.slice(4).trim();
  return trimmed;
}

function mergeUnits(first = [], second = []) {
  const totals = new Map();
  for (const item of [...first, ...second]) {
    const type = String(item.type || '').trim();
    const quantity = Number(item.quantity || 0);
    if (!type || quantity <= 0) continue;
    totals.set(type, (totals.get(type) || 0) + quantity);
  }
  return Array.from(totals.entries()).map(([type, quantity]) => ({ type, quantity }));
}

function mergeText(a, b) {
  const left = String(a || '').trim();
  const right = String(b || '').trim();
  if (!left) return right;
  if (!right || left === right) return left;
  return `${left} | ${right}`;
}

function mergeCharges(base, incoming) {
  const a = base || {};
  const b = incoming || {};
  const bracketAmount = Math.max(Number(a.bracketAmount || 0), Number(b.bracketAmount || 0));
  const deliveryAmount = Math.max(Number(a.deliveryAmount || 0), Number(b.deliveryAmount || 0));

  return {
    acBracket: Boolean(a.acBracket) || Boolean(b.acBracket) || bracketAmount > 0,
    bracketAmount,
    deliveryCharge: Boolean(a.deliveryCharge) || Boolean(b.deliveryCharge) || deliveryAmount > 0,
    deliveryAmount,
    deliveryNote: mergeText(a.deliveryNote, b.deliveryNote),
  };
}

async function main() {
  const snap = await db.collection('jobs').get();
  if (snap.empty) {
    console.log('No jobs found.');
    return;
  }

  const groups = new Map();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const normalized = normalizeInvoice(data.invoiceNumber);
    if (!normalized) continue;
    if (!groups.has(normalized)) groups.set(normalized, []);
    groups.get(normalized).push({ id: doc.id, data });
  }

  let updated = 0;
  let deleted = 0;

  for (const [invoice, docs] of groups.entries()) {
    const primary = docs[0];
    const merged = { ...primary.data };
    merged.invoiceNumber = invoice;

    for (let i = 1; i < docs.length; i++) {
      const current = docs[i].data;
      merged.acUnits = mergeUnits(merged.acUnits, current.acUnits);
      merged.expenseNote = mergeText(merged.expenseNote, current.expenseNote);
      merged.adminNote = mergeText(merged.adminNote, current.adminNote);
      merged.clientName = merged.clientName || current.clientName || invoice;
      merged.clientContact = merged.clientContact || current.clientContact || '';
      merged.companyName = merged.companyName || current.companyName || '';
      merged.companyId = merged.companyId || current.companyId || '';
      merged.charges = mergeCharges(merged.charges, current.charges);
    }

    await db.collection('jobs').doc(primary.id).set(merged, { merge: true });
    updated++;

    if (docs.length > 1) {
      const batch = db.batch();
      for (let i = 1; i < docs.length; i++) {
        batch.delete(db.collection('jobs').doc(docs[i].id));
        deleted++;
      }
      await batch.commit();
    }
  }

  console.log(`Updated jobs: ${updated}`);
  console.log(`Deleted duplicates: ${deleted}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
