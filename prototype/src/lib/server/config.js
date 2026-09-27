import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'smol-toml';
import { THEME_NAMES } from '$lib/themes.js';

export const CONFIG_PATH = path.resolve(process.env.COMMON_CONFIG ?? 'common.toml');

export const DEFAULTS = {
	theme: 'graphite',
	theme_light: 'paper',
	font: { ui: 'system', mono: 'SF Mono', size: 13 },
	window: { start: 'windowed', chrome: 'capsule', fullscreen: 'native', hide_after: '0.8s', corner: 14 },
	tiling: { layout: 'master', ratio: 0.58, gaps: 10, focus: 'border' },
	scroll: { physics: 'native', keys: 'smooth', step: 80 },
	keys: { mode: 'standard', bindings: {} },
	launcher: { search: 'https://duckduckgo.com/?q=%s', bangs: {} },
	space: [],
	hud: { enabled: false, show: [] }
};

const oneOf = (...options) => ({
	check: (v) => options.includes(v),
	expect: options.map((o) => JSON.stringify(o)).join(' | '),
	options
});
const int = (min, max) => ({
	check: (v) => Number.isInteger(v) && v >= min && v <= max,
	expect: `a whole number from ${min} to ${max}`
});
const num = (min, max) => ({
	check: (v) => typeof v === 'number' && v >= min && v <= max,
	expect: `a number from ${min} to ${max}`
});
const str = { check: (v) => typeof v === 'string' && v.length > 0, expect: 'a string' };
const bool = { check: (v) => typeof v === 'boolean', expect: 'true or false' };
const list = { check: (v) => Array.isArray(v), expect: 'an array' };
const duration = {
	check: (v) => typeof v === 'string' && /^\d+(\.\d+)?(ms|s)$/.test(v),
	expect: 'a duration like "0.8s" or "800ms"'
};
const stringTable = {
	check: (v) => v && typeof v === 'object' && !Array.isArray(v) && Object.values(v).every((x) => typeof x === 'string'),
	expect: 'a table of strings'
};

const SCHEMA = {
	'': { theme: oneOf(...THEME_NAMES), theme_light: oneOf(...THEME_NAMES) },
	font: { ui: str, mono: str, size: int(10, 24) },
	window: { start: oneOf('windowed', 'fullscreen'), chrome: oneOf('capsule', 'bar', 'none'), fullscreen: oneOf('native'), hide_after: duration, corner: int(0, 32) },
	tiling: { layout: oneOf('master', 'columns', 'monocle'), ratio: num(0.3, 0.8), gaps: int(0, 48), focus: oneOf('glow', 'border', 'none') },
	scroll: { physics: oneOf('native'), keys: oneOf('smooth', 'instant'), step: int(20, 400) },
	keys: { mode: oneOf('vim', 'standard') },
	launcher: { search: str, bangs: stringTable },
	hud: { enabled: bool, show: list }
};

// Sections the real app will read. The prototype accepts them so a full config file still loads.
const LATER = ['privacy', 'downloads', 'userscript'];
const TINT_NAMES = ['sage', 'blue', 'sand', 'clay', 'plum', 'slate'];
const SPACE_KEYS = ['name', 'tint', 'jar', 'open'];
const SECTIONS = [...Object.keys(SCHEMA).filter(Boolean), 'space', ...LATER];

const store = (globalThis.__commonConfig ??= {
	config: null,
	text: null,
	last: null,
	subscribers: new Set(),
	watcher: null,
	timer: null
});

function distance(a, b) {
	const row = Array.from({ length: b.length + 1 }, (_, i) => i);
	for (let i = 1; i <= a.length; i++) {
		let prev = row[0];
		row[0] = i;
		for (let j = 1; j <= b.length; j++) {
			const next = Math.min(row[j] + 1, row[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
			prev = row[j];
			row[j] = next;
		}
	}
	return row[b.length];
}

function nearest(word, candidates) {
	let best = null;
	let bestDistance = Infinity;
	for (const candidate of candidates) {
		const d = distance(String(word).toLowerCase(), String(candidate).toLowerCase());
		if (d < bestDistance) {
			best = candidate;
			bestDistance = d;
		}
	}
	return bestDistance <= Math.max(2, Math.floor(String(word).length / 3)) ? best : null;
}

function escapeRegExp(s) {
	return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// TOML parsers drop positions, so find the key's line by scanning for it under its section header.
function findLine(text, section, key) {
	const lines = text.split(/\r?\n/);
	const keyPattern = new RegExp(`^\\s*"?${escapeRegExp(key)}"?\\s*[=.]`);
	let current = '';
	for (let i = 0; i < lines.length; i++) {
		const header = lines[i].match(/^\s*\[\[?\s*([^\]\s]+)\s*\]\]?/);
		if (header) {
			current = header[1];
			continue;
		}
		if (current === section && keyPattern.test(lines[i])) return i + 1;
	}
	return null;
}

function isTable(v) {
	return v !== null && typeof v === 'object' && !Array.isArray(v);
}

function validate(doc, previous, text) {
	const next = structuredClone(DEFAULTS);
	const errors = [];
	const later = [];

	const report = (section, key, message, suggestion = null) =>
		errors.push({ line: findLine(text, section, key), key: section ? `${section}.${key}` : key, message, suggestion });

	const keep = (section, key) => {
		const before = section ? previous?.[section]?.[key] : previous?.[key];
		if (before === undefined) return;
		if (section) next[section][key] = structuredClone(before);
		else next[key] = structuredClone(before);
	};

	const apply = (section, key, value, sectionDoc) => {
		const rule = SCHEMA[section][key];
		if (!rule) {
			if (section === 'keys' && typeof value === 'string') {
				next.keys.bindings[key] = value;
				return;
			}
			const suggestion = nearest(key, Object.keys(SCHEMA[section]));
			const where = section ? ` in [${section}]` : '';
			report(section, key, `unknown key "${key}"${where}`, suggestion);
			// A typo like `gap` for `gaps` should not reset `gaps` to its default.
			if (suggestion && !(suggestion in sectionDoc)) keep(section, suggestion);
			return;
		}
		if (!rule.check(value)) {
			const suggestion = rule.options ? nearest(value, rule.options) : null;
			report(section, key, `${key} must be ${rule.expect}, not ${JSON.stringify(value)}`, suggestion);
			keep(section, key);
			return;
		}
		if (section) next[section][key] = structuredClone(value);
		else next[key] = structuredClone(value);
	};

	for (const [key, value] of Object.entries(doc)) {
		if (key in SCHEMA['']) {
			apply('', key, value, doc);
		} else if (key === 'space' || key === 'workspace') {
			if (key === 'workspace') report('', key, '[[workspace]] is now [[space]]; loaded it anyway');
			if (!Array.isArray(value)) {
				report('', key, 'Spaces are written as [[space]] tables');
				continue;
			}
			next.space = value.map((space, i) => {
				for (const k of Object.keys(space)) {
					if (!SPACE_KEYS.includes(k)) report(key, k, `unknown key "${k}" in [[space]]`, nearest(k, SPACE_KEYS));
				}
				if (space.tint !== undefined && !TINT_NAMES.includes(space.tint)) {
					report(key, 'tint', `tint must be one of ${TINT_NAMES.join(', ')}, not ${JSON.stringify(space.tint)}`, nearest(space.tint, TINT_NAMES));
				}
				return {
					name: typeof space.name === 'string' ? space.name : '',
					tint: TINT_NAMES.includes(space.tint) ? space.tint : TINT_NAMES[i % TINT_NAMES.length],
					jar: typeof space.jar === 'string' ? space.jar : null,
					open: Array.isArray(space.open) ? space.open.filter((x) => typeof x === 'string') : []
				};
			});
		} else if (LATER.includes(key)) {
			later.push(key);
		} else if (key in SCHEMA) {
			if (!isTable(value)) {
				report('', key, `${key} should be a [${key}] table`);
				continue;
			}
			for (const [k, v] of Object.entries(value)) apply(key, k, v, value);
		} else {
			const suggestion = nearest(key, [...Object.keys(SCHEMA['']), ...SECTIONS]);
			report('', key, `unknown key "${key}"`, suggestion);
		}
	}

	return { config: next, errors, later };
}

function flatten(value, prefix = '', out = {}) {
	if (isTable(value)) {
		for (const [k, v] of Object.entries(value)) flatten(v, prefix ? `${prefix}.${k}` : k, out);
	} else {
		out[prefix] = JSON.stringify(value);
	}
	return out;
}

function diff(before, after) {
	const a = flatten(before);
	const b = flatten(after);
	const changes = [];
	for (const key of new Set([...Object.keys(a), ...Object.keys(b)])) {
		if (a[key] !== b[key]) changes.push({ key, from: a[key] ?? null, to: b[key] ?? null });
	}
	return changes;
}

function load() {
	let text;
	try {
		text = fs.readFileSync(CONFIG_PATH, 'utf8');
	} catch (err) {
		if (err.code !== 'ENOENT') throw err;
		const config = store.config ?? structuredClone(DEFAULTS);
		store.config = config;
		return { text: null, config, changes: [], later: [], errors: [{ line: null, key: null, message: `No config at ${CONFIG_PATH}. Using defaults.`, suggestion: null }] };
	}

	let doc;
	try {
		doc = parse(text);
	} catch (err) {
		const config = store.config ?? structuredClone(DEFAULTS);
		store.config = config;
		const message = `${err.message.split('\n')[0].replace(/^Invalid TOML document: /, '')}. Kept the previous config.`;
		return { text, config, changes: [], later: [], errors: [{ line: err.line ?? null, key: null, message, suggestion: null }] };
	}

	const { config, errors, later } = validate(doc, store.config, text);
	const changes = store.config ? diff(store.config, config) : [];
	store.config = config;
	return { text, config, changes, errors, later };
}

function snapshot(result) {
	return { path: CONFIG_PATH, config: result.config, errors: result.errors, changes: result.changes, later: result.later };
}

export function current() {
	if (!store.last) {
		const result = load();
		store.text = result.text;
		store.last = snapshot(result);
	}
	return { ...store.last, changes: [] };
}

function reload() {
	let result;
	try {
		result = load();
	} catch (err) {
		result = { text: store.text, config: store.config, changes: [], later: [], errors: [{ line: null, key: null, message: `Could not read ${CONFIG_PATH}: ${err.message}`, suggestion: null }] };
	}
	// Editors often fire several events for one save; only a real content change counts.
	if (result.text !== null && result.text === store.text) return;
	store.text = result.text;
	store.last = snapshot(result);
	for (const send of store.subscribers) send({ kind: 'reload', ...store.last });
}

function ensureWatcher() {
	if (store.watcher) return;
	// Watch the folder, not the file: editors that save by rename would orphan a file watcher.
	store.watcher = fs.watch(path.dirname(CONFIG_PATH), (_event, name) => {
		if (name !== path.basename(CONFIG_PATH)) return;
		clearTimeout(store.timer);
		store.timer = setTimeout(() => store.reload(), 60);
	});
}

// The store outlives this module when the dev server hot-reloads it. Point the long-lived watcher
// at the newest code and drop results computed by the old schema.
store.reload = reload;
store.last = null;
store.text = null;

export function subscribe(send) {
	ensureWatcher();
	store.subscribers.add(send);
	return () => store.subscribers.delete(send);
}
