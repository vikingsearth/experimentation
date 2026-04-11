#!/usr/bin/env node

// {{SCRIPT_NAME}} — {{SCRIPT_PURPOSE}}
//
// Usage:
//   node scripts/{{SCRIPT_NAME}} <required-arg> [optional-arg]
//
// Arguments:
//   required-arg   Description of required argument.
//   optional-arg   Description of optional argument. Defaults to "default".
//
// Output:
//   JSON to stdout, diagnostics to stderr.

import process from 'node:process';

function main() {
	const args = process.argv.slice(2);

	if (args.includes('--help') || args.includes('-h')) {
		console.log('Usage: node scripts/{{SCRIPT_NAME}} <required-arg> [optional-arg]');
		process.exit(0);
	}

	const requiredArg = args[0];
	const optionalArg = args[1] ?? 'default';

	if (!requiredArg) {
		console.error('Error: required-arg is required.');
		console.error('Usage: node scripts/{{SCRIPT_NAME}} <required-arg> [optional-arg]');
		process.exit(2);
	}

	// --- Main logic ---

	console.log(JSON.stringify({ status: 'ok', input: requiredArg, option: optionalArg }));
}

main();
