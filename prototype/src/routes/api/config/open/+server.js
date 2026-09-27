import { spawn } from 'node:child_process';
import { json } from '@sveltejs/kit';
import { CONFIG_PATH } from '$lib/server/config.js';

// A browser can't launch $EDITOR, so the dev server does it. COMMON_EDITOR overrides the
// default, e.g. COMMON_EDITOR="zed" or "code -w"; a terminal editor needs a terminal wrapper.
function command() {
	if (process.env.COMMON_EDITOR) {
		const [cmd, ...args] = process.env.COMMON_EDITOR.split(/\s+/);
		return [cmd, [...args, CONFIG_PATH]];
	}
	if (process.platform === 'darwin') return ['open', ['-t', CONFIG_PATH]];
	return ['xdg-open', [CONFIG_PATH]];
}

export function POST() {
	const [cmd, args] = command();
	return new Promise((resolve) => {
		const child = spawn(cmd, args, { detached: true, stdio: 'ignore' });
		child.on('error', (err) => resolve(json({ ok: false, message: `Could not run ${cmd}: ${err.message}` }, { status: 500 })));
		child.on('spawn', () => {
			child.unref();
			resolve(json({ ok: true, path: CONFIG_PATH, via: cmd }));
		});
	});
}
