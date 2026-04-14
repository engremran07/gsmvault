const fs = require('fs');
const path = require('path');

const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const rules = fs.readFileSync(rulesPath, 'utf8');

function fail(message) {
  console.error(`STRICT RULES LINT FAILED: ${message}`);
  process.exitCode = 1;
}

function checkReservedFunctionNames(source) {
  const reserved = new Set(['exists', 'existsAfter', 'get', 'getAfter']);
  const functionPattern = /function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/g;
  let match;
  while ((match = functionPattern.exec(source)) !== null) {
    if (reserved.has(match[1])) {
      fail(`Function name '${match[1]}' is reserved in Firestore rules.`);
    }
  }
}

function checkUnusedFunctions(source) {
  const functionPattern = /function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/g;
  const functionNames = [];
  let match;

  while ((match = functionPattern.exec(source)) !== null) {
    functionNames.push(match[1]);
  }

  for (const name of functionNames) {
    const usagePattern = new RegExp(`\\b${name}\\s*\\(`, 'g');
    const uses = source.match(usagePattern) || [];

    if (uses.length <= 1) {
      fail(`Function '${name}' is declared but never used.`);
    }
  }
}

function checkForbiddenTokens(source) {
  const forbidden = ['TODO', 'FIXME'];
  for (const token of forbidden) {
    if (source.includes(token)) {
      fail(`Forbidden token '${token}' found in firestore.rules.`);
    }
  }
}

checkReservedFunctionNames(rules);
checkUnusedFunctions(rules);
checkForbiddenTokens(rules);

if (!process.exitCode) {
  console.log('Strict Firestore rules lint passed.');
}
