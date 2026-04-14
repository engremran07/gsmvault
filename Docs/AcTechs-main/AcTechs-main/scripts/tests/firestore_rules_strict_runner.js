const { spawn } = require('child_process');

const command =
  'firebase emulators:exec --config ../firebase.json --only firestore --project demo-actechs-rules-test "node tests/firestore_rules_test.js && node tests/firestore_rules_settlement_shared_test.js"';

// Patterns that indicate genuine rule evaluation problems.
const disallowedPatterns = [
  /maximum of 1000 expressions/i,
  /Null value error\./i,
];

// `firebase emulators:exec` prints this exact line when the inner script exits 0.
// We use it as the authoritative success signal instead of the outer process exit code
// because the emulator subprocess may receive SIGINT during shutdown on Windows,
// causing the outer process to exit non-zero even though all tests passed.
const SCRIPT_SUCCESS_PATTERN = /Script exited successfully \(code 0\)/;

const child = spawn(command, {
  shell: true,
  stdio: ['inherit', 'pipe', 'pipe'],
  env: {
    ...process.env,
    NODE_OPTIONS: '--no-deprecation',
  },
});

let output = '';

child.stdout.on('data', (chunk) => {
  const text = chunk.toString();
  output += text;
  process.stdout.write(text);
});

child.stderr.on('data', (chunk) => {
  const text = chunk.toString();
  output += text;
  process.stderr.write(text);
});

child.on('close', (code) => {
  // Determine test success from the inner script's own exit report rather than
  // the outer emulator-exec process exit code.  The emulator may exit with a
  // non-zero signal code (SIGINT/130) on Windows during normal shutdown even
  // when every test passed — using the inner script report avoids false failures.
  const innerScriptPassed = SCRIPT_SUCCESS_PATTERN.test(output);

  if (!innerScriptPassed) {
    // Inner script genuinely failed — propagate failure.
    process.exitCode = code || 1;
    return;
  }

  for (const pattern of disallowedPatterns) {
    if (pattern.test(output)) {
      console.error(`STRICT FIRESTORE RULES GATE FAILED: matched pattern ${pattern}`);
      process.exitCode = 1;
      return;
    }
  }

  console.log('Strict Firestore rules runner passed: no expression-limit or null-eval errors detected.');
  // Hard-exit 0 so that the emulator SIGINT shutdown (which causes firebase emulators:exec
  // to exit non-zero) cannot pollute the npm exit code.  All tests genuinely passed.
  process.exit(0);
});

