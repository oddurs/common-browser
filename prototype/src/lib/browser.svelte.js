import { SITES, srcFor, describe, searchSrc, splitUrl } from './sites.js';
import { THEMES, THEME_NAMES, rgba } from './themes.js';
import { computeLayout, neighbour } from './layout.js';

const LAYOUTS = ['master', 'columns', 'monocle'];
const GLYPHS = { master: '[]=', columns: '|||', monocle: '[M]' };
const HINT_ALPHABET = 'sadfjklewcmpgh';
export const TINTS = { sage: '#7f9c84', blue: '#6f8fb3', sand: '#b59b6b', clay: '#b9745a', plum: '#9a7aa8', slate: '#7e8792' };
const TINT_ORDER = Object.keys(TINTS);
const PRIVATE_TINT = '#d9534f';

let nextPaneId = 1;
let nextToastId = 1;
let nextSpaceId = 1;

// A Space is pages + layout + logins + history, and exists while it has pages.
function makeSpace(def, index) {
	const panes = (def.open ?? []).map(makePane);
	return {
		id: nextSpaceId++,
		name: def.name ?? '',
		autoName: !def.name,
		tint: def.tint ?? TINT_ORDER[index % TINT_ORDER.length],
		jar: def.jar ?? null,
		private: !!def.private,
		layout: null,
		panes,
		order: panes.map((p) => p.id),
		focus: panes[0]?.id ?? null
	};
}

export function spaceName(space) {
	return space?.name || 'New Space';
}

export function spaceColor(space) {
	return space?.private ? PRIVATE_TINT : (TINTS[space?.tint] ?? TINTS.slate);
}

// "tessera.example.dev" → "tessera": good enough to name a Space after its first site.
function shortName(url) {
	const host = splitUrl(url)[0];
	if (!host || host.startsWith('common:')) return '';
	return host.replace(/^www\./, '').split(/[.:]/)[0];
}

function isEditable(el) {
	if (!el || el.nodeType !== 1) return false;
	if (el.isContentEditable) return true;
	if (el.tagName === 'TEXTAREA' || el.tagName === 'SELECT') return true;
	if (el.tagName !== 'INPUT') return false;
	return !['button', 'submit', 'reset', 'checkbox', 'radio', 'range', 'color', 'file', 'image'].includes(el.type);
}

function makePane(target) {
	return { id: nextPaneId++, initial: srcFor(target) ?? '/site/new.html', url: '', title: 'Loading…', progress: 0, external: false };
}

// Prefix-free labels, as short as the count allows: split the first label into a full set of
// children until there are enough. 30 links get a mix of one- and two-letter labels.
function makeLabels(count) {
	const letters = HINT_ALPHABET.split('');
	let labels = [''];
	while (labels.length < count) {
		const [first, ...rest] = labels;
		labels = [...rest, ...letters.map((l) => first + l)];
	}
	return labels.slice(0, count).sort((a, b) => a.length - b.length);
}

function durationMs(value) {
	const m = /^(\d+(?:\.\d+)?)(ms|s)$/.exec(value ?? '');
	if (!m) return 800;
	return m[2] === 's' ? Number(m[1]) * 1000 : Number(m[1]);
}

function sameOriginPath(href) {
	try {
		const url = new URL(href, location.href);
		return url.origin === location.origin ? url.pathname + url.search : url.href;
	} catch {
		return href;
	}
}

export class Browser {
	config = $state(null);
	configPath = $state('');
	spaces = $state([]);
	archived = $state([]);
	overview = $state(false);
	current = $state(0);
	mode = $state('NORMAL');
	launcher = $state(null);
	hints = $state.raw(null);
	capsuleShown = $state(false);
	hud = $state(false);
	help = $state(false);
	toasts = $state([]);
	pill = $state(null);
	runtimeTheme = $state(null);
	prefersLight = $state(false);
	size = $state({ w: 0, h: 0 });
	latency = $state(0);
	connected = $state(true);
	fullscreen = $state(false);
	menu = $state(null);
	menuKey = null;
	animating = $state(false);

	frames = new Map();
	windowEl = null;
	hideTimer = 0;
	animateTimer = 0;
	pillTimer = 0;
	pending = null;
	pendingTimer = 0;
	glide = null;
	lastInput = 0;

	get ws() {
		return this.spaces[this.current];
	}
	get focusedPane() {
		const ws = this.ws;
		return ws?.panes.find((p) => p.id === ws.focus) ?? null;
	}
	get layoutName() {
		return this.ws?.layout ?? this.config?.tiling.layout ?? 'master';
	}
	get layoutGlyph() {
		return GLYPHS[this.layoutName];
	}
	get modeLabel() {
		if (this.launcher) return 'LAUNCH';
		if (this.hints) return 'HINT';
		return this.mode;
	}
	get chrome() {
		return this.config?.window.chrome ?? 'capsule';
	}
	get capsuleVisible() {
		if (this.chrome === 'bar') return true;
		if (this.chrome === 'none') return false;
		return this.capsuleShown;
	}
	get themeName() {
		if (this.runtimeTheme) return this.runtimeTheme;
		if (!this.config) return this.prefersLight ? 'paper' : 'graphite';
		return this.prefersLight ? this.config.theme_light : this.config.theme;
	}
	get theme() {
		return THEMES[this.themeName] ?? THEMES.graphite;
	}
	get cssVars() {
		const t = this.theme;
		const light = t.mode === 'light';
		const font = this.config?.font;
		const ui = !font || font.ui === 'system' ? "-apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif" : `'${font.ui}', -apple-system, system-ui, sans-serif`;
		const mono = !font || font.mono === 'SF Mono' ? "ui-monospace, 'SF Mono', 'JetBrains Mono', Menlo, monospace" : `'${font.mono}', ui-monospace, 'JetBrains Mono', Menlo, monospace`;
		const vars = {
			'--bg': t.bg,
			'--deep': t.deep,
			'--surface': t.surface,
			'--hl': t.hl,
			'--border': t.border,
			'--fg': t.fg,
			'--muted': t.muted,
			'--dim': t.dim,
			'--accent': t.accent,
			'--accent2': t.accent2,
			'--green': t.green,
			'--yellow': t.yellow,
			'--red': t.red,
			'--cyan': t.cyan,
			'--orange': t.orange,
			'--glass': rgba(t.deep, 0.74),
			'--panel': rgba(t.bg, 0.86),
			'--fill': light ? 'rgba(0, 0, 0, 0.055)' : 'rgba(255, 255, 255, 0.07)',
			'--line': light ? 'rgba(0, 0, 0, 0.1)' : 'rgba(255, 255, 255, 0.1)',
			'--glow': rgba(t.accent, 0.3),
			'--ring': rgba(t.accent, 0.7),
			'--sel': light ? 'rgba(0, 0, 0, 0.06)' : 'rgba(255, 255, 255, 0.08)',
			'--sel-strong': light ? 'rgba(0, 0, 0, 0.09)' : 'rgba(255, 255, 255, 0.13)',
			'--ink': light ? '#ffffff' : t.deep,
			'--scrim': light ? 'rgba(20, 20, 30, 0.14)' : 'rgba(0, 0, 0, 0.35)',
			'--ui': ui,
			'--mono': mono,
			'--size': `${font?.size ?? 13}px`,
			'--corner': `${this.config?.window.corner ?? 14}px`
		};
		return Object.entries(vars)
			.map(([k, v]) => `${k}: ${v}`)
			.join('; ');
	}

	rects(ws) {
		const tiling = this.config?.tiling;
		const gaps = tiling?.gaps ?? 10;
		// A window keeps a title bar strip for the traffic lights; full screen gives it back.
		const top = this.fullscreen || this.chrome === 'bar' ? gaps : Math.max(gaps, 36);
		return computeLayout(ws.order, ws.focus, ws.layout ?? tiling?.layout ?? 'master', this.size.w, this.size.h, gaps, tiling?.ratio ?? 0.58, top);
	}

	// ── lifecycle ────────────────────────────────────────────────

	start() {
		const scheme = matchMedia('(prefers-color-scheme: light)');
		this.prefersLight = scheme.matches;
		scheme.addEventListener('change', (e) => (this.prefersLight = e.matches));

		const source = new EventSource('/api/config');
		source.onmessage = (m) => {
			this.connected = true;
			this.onConfig(JSON.parse(m.data));
		};
		source.onerror = () => {
			if (this.connected) this.toast({ kind: 'error', title: 'Lost the dev server', body: 'Config changes will apply again once it is back.' });
			this.connected = false;
		};

		// Clicking into a page from another site gives no event we can read, except this window losing focus.
		window.addEventListener('blur', () =>
			setTimeout(() => {
				for (const [id, frame] of this.frames) if (frame === document.activeElement) this.focusPane(id, false);
			})
		);

		const tick = () => {
			if (this.lastInput) {
				this.latency = performance.now() - this.lastInput;
				this.lastInput = 0;
			}
			requestAnimationFrame(tick);
		};
		requestAnimationFrame(tick);
	}

	onConfig(event) {
		const first = !this.config;
		this.config = event.config;
		this.configPath = event.path;

		if (first) {
			this.buildSpaces(event.config);
			this.hud = event.config.hud.enabled;
			this.fullscreen = event.config.window.start === 'fullscreen';
		} else {
			this.syncSpaces(event.config);
			if (event.changes.some((c) => c.key === 'hud.enabled')) this.hud = event.config.hud.enabled;
			if (event.changes.some((c) => c.key === 'window.start')) this.fullscreen = event.config.window.start === 'fullscreen';
		}

		if (event.kind === 'reload') {
			if (event.changes.length) {
				const lines = event.changes.map((c) => `${c.key} = ${c.to}`);
				this.toast({ kind: 'ok', title: 'Settings applied', lines, ttl: 4000 });
			}
			if (event.changes.some((c) => c.key === 'theme' || c.key === 'theme_light')) this.runtimeTheme = null;
		}

		for (const err of event.errors) {
			const fix = err.suggestion ? ` Did you mean ${err.suggestion}?` : '';
			const kept = err.key ? ' The previous value is kept.' : '';
			this.toast({
				kind: 'error',
				title: err.line ? `common.toml, line ${err.line}` : 'common.toml',
				body: `${err.message[0].toUpperCase()}${err.message.slice(1)}.${fix}${kept}`.replace('..', '.'),
				ttl: 12000
			});
		}
	}

	buildSpaces(config) {
		const defs = config.space.length ? config.space : [{ name: 'reading', open: ['notes'] }];
		this.spaces = defs.map(makeSpace);
	}

	// Pages stay as they are on reload; only names, tints and jars follow the file.
	syncSpaces(config) {
		this.spaces.forEach((ws, i) => {
			const def = config.space[i];
			if (!def) return;
			if (def.name) {
				ws.name = def.name;
				ws.autoName = false;
			}
			ws.tint = def.tint;
			ws.jar = def.jar;
		});
	}

	newSpace(isPrivate = false) {
		this.overview = false;
		this.spaces.push(makeSpace({ name: isPrivate ? 'Private' : '', private: isPrivate }, this.spaces.length));
		this.gotoSpace(this.spaces.length - 1);
		this.openLauncher('', true);
	}

	// Closing a Space's last page archives it rather than deleting it; private Spaces just end.
	archiveSpace(i) {
		const [ws] = this.spaces.splice(i, 1);
		if (!ws.private) this.archived.unshift({ name: spaceName(ws), tint: ws.tint, open: ws.panes.map((p) => p.url || p.initial) });
		this.gotoSpace(Math.min(i, this.spaces.length - 1));
	}

	restoreSpace(i) {
		const [entry] = this.archived.splice(i, 1);
		this.overview = false;
		this.spaces.push(makeSpace({ name: entry.name, tint: entry.tint, open: entry.open.length ? entry.open : ['new'] }, this.spaces.length));
		this.gotoSpace(this.spaces.length - 1);
	}

	toggleOverview() {
		this.overview = !this.overview;
		this.hints = null;
		this.launcher = null;
		if (!this.overview && this.ws?.focus != null) this.focusFrame(this.ws.focus);
	}

	// ── panes ────────────────────────────────────────────────────

	attach = (node, pane) => {
		this.frames.set(pane.id, node);
		const onLoad = () => this.wire(pane, node);
		node.addEventListener('load', onLoad);
		return {
			destroy: () => {
				node.removeEventListener('load', onLoad);
				this.frames.delete(pane.id);
			}
		};
	};

	wire(pane, frame) {
		let win;
		let doc;
		try {
			win = frame.contentWindow;
			doc = frame.contentDocument;
		} catch {
			doc = null;
		}
		if (!doc) {
			pane.external = true;
			pane.url = frame.src;
			pane.title = frame.src;
			return;
		}
		pane.external = false;
		const where = describe(win.location);
		pane.url = where.url;
		pane.title = doc.title || where.title;
		const owner = this.spaces.find((s) => s.panes.some((p) => p.id === pane.id));
		if (owner?.autoName && !owner.name) owner.name = shortName(where.url);
		const transparent = (c) => !c || c === 'transparent' || c === 'rgba(0, 0, 0, 0)';
		const bodyBg = win.getComputedStyle(doc.body).backgroundColor;
		const rootBg = win.getComputedStyle(doc.documentElement).backgroundColor;
		pane.bg = !transparent(bodyBg) ? bodyBg : !transparent(rootBg) ? rootBg : '#ffffff';

		win.addEventListener('keydown', (e) => this.onKey(e), true);
		doc.addEventListener('focusin', (e) => isEditable(e.target) && this.setInsert(true));
		doc.addEventListener('focusout', (e) => isEditable(e.target) && this.setInsert(false));
		doc.addEventListener('mousedown', () => {
			this.menu = null;
			this.focusPane(pane.id, false);
		});
		doc.addEventListener('mousemove', (e) => this.onPointer(frame.getBoundingClientRect().top + e.clientY));
		doc.addEventListener('wheel', () => this.cancelGlide(), { passive: true });
		win.addEventListener('scroll', () => this.onScroll(pane, win, doc), { passive: true });
		this.onScroll(pane, win, doc);
	}

	frameOf(id = this.ws?.focus) {
		return this.frames.get(id) ?? null;
	}
	winOf(id) {
		const frame = this.frameOf(id);
		try {
			return frame?.contentDocument ? frame.contentWindow : null;
		} catch {
			return null;
		}
	}

	focusPane(id, moveKeyboard = true) {
		const ws = this.spaces.find((w) => w.panes.some((p) => p.id === id));
		if (!ws) return;
		ws.focus = id;
		if (moveKeyboard) this.focusFrame(id);
	}

	focusFrame(id) {
		const frame = this.frameOf(id);
		if (!frame) return;
		try {
			frame.contentWindow.focus();
		} catch {
			frame.focus();
		}
	}

	newPane(target = 'new') {
		const ws = this.ws;
		const raw = makePane(target);
		this.animateLayout();
		ws.panes.push(raw);
		const at = ws.order.indexOf(ws.focus);
		ws.order.splice(at + 1, 0, raw.id);
		ws.focus = raw.id;
		setTimeout(() => this.focusFrame(raw.id), 60);
	}

	closePane() {
		const ws = this.ws;
		const id = ws?.focus;
		if (id == null) return;
		// The last page takes its Space with it, archived with that page so it can come back.
		if (ws.panes.length === 1 && this.spaces.length > 1) return this.archiveSpace(this.current);
		const at = ws.order.indexOf(id);
		this.animateLayout();
		ws.order.splice(at, 1);
		ws.panes.splice(ws.panes.findIndex((p) => p.id === id), 1);
		ws.focus = ws.order[Math.max(0, at - 1)] ?? null;
		if (ws.focus != null) this.focusFrame(ws.focus);
	}

	step(direction) {
		const ws = this.ws;
		if (!ws || ws.focus == null) return null;
		if (this.layoutName === 'monocle') {
			const i = ws.order.indexOf(ws.focus);
			const delta = direction === 'left' || direction === 'up' ? -1 : 1;
			return ws.order[(i + delta + ws.order.length) % ws.order.length];
		}
		return neighbour(this.rects(ws), ws.focus, direction);
	}

	moveFocus(direction) {
		const target = this.step(direction);
		if (target != null) this.focusPane(target);
	}

	swap(direction) {
		const ws = this.ws;
		const target = this.step(direction);
		if (target == null) return;
		this.animateLayout();
		const a = ws.order.indexOf(ws.focus);
		const b = ws.order.indexOf(target);
		[ws.order[a], ws.order[b]] = [ws.order[b], ws.order[a]];
	}

	makeMaster() {
		const ws = this.ws;
		if (!ws || ws.focus == null) return;
		this.animateLayout();
		ws.order.splice(ws.order.indexOf(ws.focus), 1);
		ws.order.unshift(ws.focus);
	}

	cycleLayout() {
		const ws = this.ws;
		if (!ws) return;
		this.animateLayout();
		ws.layout = LAYOUTS[(LAYOUTS.indexOf(this.layoutName) + 1) % LAYOUTS.length];
		this.flashPill('layout');
	}

	setLayout(name) {
		this.animateLayout();
		if (this.ws) this.ws.layout = name;
		this.flashPill('layout');
	}

	gotoSpace(i) {
		if (i < 0 || i >= this.spaces.length) return;
		this.current = i;
		this.overview = false;
		this.flashPill('space');
		const focus = this.ws.focus;
		if (focus != null) setTimeout(() => this.focusFrame(focus), 30);
	}

	sendToSpace(i) {
		const from = this.ws;
		const to = this.spaces[i];
		if (!to || to === from || from.focus == null) return;
		const id = from.focus;
		const pane = $state.snapshot(from.panes.find((p) => p.id === id));
		// Moving a Space's only page empties it; it goes away rather than being archived as a copy.
		if (from.panes.length === 1) this.spaces.splice(this.current, 1);
		else this.closePane();
		// Moving a pane remounts its frame, which reloads the page. The real app keeps the view alive.
		const moved = { ...pane, id: nextPaneId++, initial: srcFor(pane.url) ?? pane.initial };
		to.panes.push(moved);
		to.order.push(moved.id);
		to.focus = moved.id;
		// Closing the last page may have archived the source Space and shifted positions.
		this.gotoSpace(this.spaces.indexOf(to));
	}

	navigate(src) {
		const frame = this.frameOf();
		if (!frame) return this.newPane(src);
		frame.src = src;
	}

	history(delta) {
		try {
			this.frameOf()?.contentWindow.history.go(delta);
		} catch {
			this.toast({ kind: 'info', title: 'History is out of reach', body: 'This page is from another site.' });
		}
	}

	reload() {
		const frame = this.frameOf();
		if (!frame) return;
		try {
			frame.contentWindow.location.reload();
		} catch {
			frame.src = frame.src;
		}
	}

	// ── scrolling ────────────────────────────────────────────────

	scroll(kind) {
		const win = this.winOf();
		if (!win) return;
		const base = this.glide?.win === win ? this.glide.target : win.scrollY;
		const step = this.config?.scroll.step ?? 80;
		const half = win.innerHeight / 2;
		const bottom = win.document.documentElement.scrollHeight;
		const target = { down: base + step, up: base - step, halfDown: base + half, halfUp: base - half, top: 0, bottom }[kind];
		this.glideTo(win, target);
	}

	// Keyboard scrolling glides toward a target; any trackpad or wheel input cancels it at once.
	glideTo(win, target) {
		const max = win.document.documentElement.scrollHeight - win.innerHeight;
		const clamped = Math.max(0, Math.min(max, target));
		if (this.config?.scroll.keys !== 'smooth' || matchMedia('(prefers-reduced-motion: reduce)').matches) {
			win.scrollTo(0, clamped);
			return;
		}
		if (!this.glide || this.glide.win !== win) {
			this.cancelGlide();
			this.glide = { win, y: win.scrollY, target: clamped, raf: 0, last: 0 };
		}
		const glide = this.glide;
		glide.target = clamped;
		if (glide.raf) return;
		// Close a fixed share of the distance per millisecond, not per frame, so the glide feels
		// the same at 60 Hz and 120 Hz.
		const frame = (now) => {
			const dt = glide.last ? Math.min(now - glide.last, 50) : 8;
			glide.last = now;
			const d = glide.target - glide.y;
			if (Math.abs(d) < 0.5) {
				win.scrollTo(0, glide.target);
				this.glide = null;
				return;
			}
			glide.y += d * (1 - Math.exp(-dt / 65));
			win.scrollTo(0, glide.y);
			glide.raf = requestAnimationFrame(frame);
		};
		glide.raf = requestAnimationFrame(frame);
	}

	cancelGlide() {
		if (this.glide?.raf) cancelAnimationFrame(this.glide.raf);
		this.glide = null;
	}

	onScroll(pane, win, doc) {
		const max = doc.documentElement.scrollHeight - win.innerHeight;
		pane.progress = max > 0 ? Math.min(1, win.scrollY / max) : 0;
	}

	// ── chrome ───────────────────────────────────────────────────

	// Panes glide only when the layout itself changes; a window resize should track instantly.
	animateLayout() {
		this.animating = true;
		clearTimeout(this.animateTimer);
		this.animateTimer = setTimeout(() => (this.animating = false), 280);
	}

	toggleFullscreen() {
		this.fullscreen = !this.fullscreen;
	}

	// y arrives in page coordinates; the capsule cares about the window's own top edge.
	onPointer(pageY) {
		const y = pageY - (this.windowEl?.getBoundingClientRect().top ?? 0);
		if (y >= 0 && y <= 4) this.showCapsule();
		else if (this.capsuleShown && y > 96 && !this.hideTimer) this.scheduleHide();
	}

	showCapsule() {
		clearTimeout(this.hideTimer);
		this.hideTimer = 0;
		this.capsuleShown = true;
	}

	scheduleHide() {
		clearTimeout(this.hideTimer);
		this.hideTimer = setTimeout(() => {
			this.capsuleShown = false;
			this.hideTimer = 0;
		}, durationMs(this.config?.window.hide_after));
	}

	flashPill(kind) {
		this.pill = { kind };
		clearTimeout(this.pillTimer);
		this.pillTimer = setTimeout(() => (this.pill = null), kind === 'space' ? 1100 : 1400);
	}

	toast(t) {
		const id = nextToastId++;
		this.toasts.push({ id, ...t });
		setTimeout(() => this.dismiss(id), t.ttl ?? 6000);
	}

	dismiss(id) {
		const i = this.toasts.findIndex((t) => t.id === id);
		if (i >= 0) this.toasts.splice(i, 1);
	}

	async openConfig() {
		try {
			const res = await fetch('/api/config/open', { method: 'POST' });
			const body = await res.json();
			if (body.ok) this.toast({ kind: 'info', title: 'Opened common.toml', body: 'Save it to apply.', ttl: 3000 });
			else this.toast({ kind: 'error', title: 'Could not open common.toml', body: body.message });
		} catch (err) {
			this.toast({ kind: 'error', title: 'Could not reach the dev server', body: err.message });
		}
	}

	async copyUrl() {
		const url = this.focusedPane?.url;
		if (!url) return;
		try {
			await navigator.clipboard.writeText(url);
			this.toast({ kind: 'info', title: 'Copied link', ttl: 2000 });
		} catch (err) {
			this.toast({ kind: 'error', title: 'Could not copy', body: err.message });
		}
	}

	// ── modes ────────────────────────────────────────────────────

	setInsert(on) {
		if (on) this.mode = 'INSERT';
		else if (this.mode === 'INSERT') this.mode = 'NORMAL';
	}

	leaveInsert() {
		try {
			this.frameOf()?.contentDocument?.activeElement?.blur();
		} catch {
			// Another site's page keeps its own focus.
		}
		this.mode = 'NORMAL';
	}

	focusFirstInput() {
		const doc = this.frameOf()?.contentDocument;
		doc?.querySelector('input:not([type=hidden]):not([type=checkbox]):not([type=radio]), textarea, [contenteditable="true"]')?.focus();
	}

	accelerator(key) {
		const el = this.frameOf()?.contentDocument?.querySelector(`[data-key="${key}"]`);
		if (!el) return false;
		el.click();
		return true;
	}

	// ── launcher ─────────────────────────────────────────────────

	openLauncher(text = '', newPane = false) {
		this.hints = null;
		this.launcher = { text, newPane };
	}

	closeLauncher() {
		this.launcher = null;
		const focus = this.ws?.focus;
		if (focus != null) this.focusFrame(focus);
	}

	launch(result, inNewPane = false) {
		this.closeLauncher();
		if (result.run) return result.run();
		if (inNewPane || !this.focusedPane) this.newPane(result.src);
		else this.navigate(result.src);
	}

	commands() {
		return [
			...THEME_NAMES.map((name) => ({ kind: 'cmd', label: `:theme ${name}`, detail: 'until common.toml changes', run: () => (this.runtimeTheme = name) })),
			...LAYOUTS.map((name) => ({ kind: 'cmd', label: `:layout ${name}`, detail: 'this Space', run: () => this.setLayout(name) })),
			{ kind: 'cmd', label: ':config', detail: 'open common.toml', run: () => this.openConfig() },
			{ kind: 'cmd', label: ':hud', detail: 'performance overlay', run: () => (this.hud = !this.hud) },
			{ kind: 'cmd', label: ':help', detail: 'every key', run: () => (this.help = true) },
			{ kind: 'cmd', label: ':close', detail: 'close this pane', run: () => this.closePane() }
		];
	}

	allPanes() {
		return this.spaces.flatMap((ws, i) =>
			ws.panes.map((pane) => ({
				kind: 'pane',
				label: pane.title,
				detail: `${pane.url} · ${spaceName(ws)}`,
				run: () => {
					this.gotoSpace(i);
					this.focusPane(pane.id);
				}
			}))
		);
	}

	results(text) {
		const q = text.trim();
		const lower = q.toLowerCase();
		const bangs = this.config?.launcher.bangs ?? {};

		if (q.startsWith(':')) return this.commands().filter((c) => c.label.startsWith(lower) || c.label.includes(lower.slice(1)));
		if (q.startsWith('@')) {
			const needle = lower.slice(1);
			return this.allPanes().filter((p) => `${p.label} ${p.detail}`.toLowerCase().includes(needle));
		}
		if (q.startsWith('!')) {
			const m = q.match(/^!(\S*)\s*(.*)$/);
			const [name, rest] = [m[1], m[2]];
			if (bangs[name]) {
				return [{ kind: 'bang', label: rest ? `Search ${name} for “${rest}”` : `Search ${name}`, detail: bangs[name].replace('%s', encodeURIComponent(rest)), src: searchSrc(rest, name) }];
			}
			return Object.entries(bangs)
				.filter(([bang]) => bang.startsWith(name))
				.map(([bang, url]) => ({ kind: 'bang', label: `!${bang}`, detail: url, complete: `!${bang} ` }));
		}

		const results = [];
		const direct = srcFor(q);
		if (q && direct && !direct.startsWith('/site/')) results.push({ kind: 'url', label: q, detail: 'open this address (other sites may refuse to load inside a pane)', src: direct });
		// Skip only sites already open in this Space; elsewhere they're still worth opening here.
		const open = new Set((this.ws?.panes ?? []).map((p) => p.url));
		for (const site of SITES) {
			if (site.slug === 'search' || site.slug === 'new' || (q && open.has(site.url))) continue;
			if (!q || `${site.title} ${site.url}`.toLowerCase().includes(lower)) results.push({ kind: 'site', label: site.title, detail: site.url, src: site.path });
		}
		if (q) {
			results.push(...this.allPanes().filter((p) => `${p.label} ${p.detail}`.toLowerCase().includes(lower)).slice(0, 3));
			const search = this.config?.launcher.search ?? '';
			results.push({ kind: 'search', label: `Search for “${q}”`, detail: search.replace('%s', encodeURIComponent(q)), src: searchSrc(q) });
		}
		return results;
	}

	// ── link hints ───────────────────────────────────────────────

	startHints(newPane) {
		const pane = this.focusedPane;
		const frame = this.frameOf();
		const doc = frame?.contentDocument;
		if (!pane || !doc) {
			this.toast({ kind: 'info', title: 'No hints here', body: 'This page is from another site, so the prototype cannot reach into it.' });
			return;
		}
		const win = frame.contentWindow;
		const rect = this.rects(this.ws).get(pane.id);
		const elements = [...doc.querySelectorAll('a[href], button, input, textarea, select, [data-key]')].filter((el) => {
			const b = el.getBoundingClientRect();
			return b.width > 0 && b.height > 0 && b.bottom > 0 && b.right > 0 && b.top < win.innerHeight && b.left < win.innerWidth && win.getComputedStyle(el).visibility !== 'hidden';
		});
		if (!elements.length) return;
		const labels = makeLabels(elements.length);
		this.hints = {
			newPane,
			typed: '',
			items: elements.map((el, i) => {
				const b = el.getBoundingClientRect();
				// Hints sit in the margin just left of the link, so the words stay readable.
				const left = Math.max(0, b.left);
				return { label: labels[i], x: rect.x + left, y: rect.y + Math.max(0, b.top) + Math.min(b.height, 40) / 2, inside: left < 34, el };
			})
		};
	}

	hintKey(e) {
		e.preventDefault();
		e.stopPropagation();
		const hints = this.hints;
		if (e.key === 'Escape') {
			this.hints = null;
			return;
		}
		if (e.key === 'Backspace') {
			this.hints = { ...hints, typed: hints.typed.slice(0, -1) };
			return;
		}
		if (e.key.length !== 1) return;
		const typed = hints.typed + e.key.toLowerCase();
		const matches = hints.items.filter((h) => h.label.startsWith(typed));
		if (!matches.length) return;
		const exact = matches.find((h) => h.label === typed);
		if (exact && matches.length === 1) {
			this.hints = null;
			this.followHint(exact.el, hints.newPane);
			return;
		}
		this.hints = { ...hints, typed };
	}

	followHint(el, newPane) {
		if (newPane && el.href) {
			this.newPane(sameOriginPath(el.href));
			return;
		}
		if (isEditable(el)) {
			el.focus();
			return;
		}
		el.click();
		this.focusFrame(this.ws.focus);
	}

	// ── keys ─────────────────────────────────────────────────────

	onKey = (e) => {
		this.lastInput = performance.now();
		if (e.defaultPrevented || this.launcher) return;
		if (this.hints) return this.hintKey(e);
		if (e.key === 'Escape' && this.closeOverlay()) {
			e.preventDefault();
			return;
		}
		if (this.menu !== null) return this.menuKey?.(e);
		// ⌘ is the command key; ⌃ stands in for it here because a host browser keeps ⌘T, ⌘W and ⌘1–9.
		if (e.metaKey || e.ctrlKey) {
			if (this.command(e)) e.preventDefault();
			return;
		}
		if (this.mode === 'INSERT' || isEditable(e.target)) {
			if (e.key === 'Escape') {
				e.preventDefault();
				this.leaveInsert();
			}
			return;
		}
		if (this.config?.keys.mode === 'vim' && this.normal(e)) e.preventDefault();
	};

	closeOverlay() {
		if (this.help) return (this.help = false), true;
		if (this.overview) return this.toggleOverview(), true;
		if (this.menu !== null) return (this.menu = null), true;
		return false;
	}

	// The whole standard keymap. Every entry also appears in the menu bar.
	command(e) {
		const cmd = e.metaKey || e.ctrlKey;
		if (!cmd) return false;
		if (e.metaKey && e.ctrlKey && e.code === 'KeyF') return this.toggleFullscreen(), true;

		const digit = e.code.match(/^Digit([1-9])$/);
		if (digit && !e.altKey) {
			const i = Number(digit[1]) - 1;
			if (e.shiftKey) this.sendToSpace(i);
			else this.gotoSpace(i);
			return true;
		}

		const arrows = { ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down' };
		if (e.altKey && arrows[e.code]) {
			if (e.shiftKey) this.swap(arrows[e.code]);
			else this.moveFocus(arrows[e.code]);
			return true;
		}
		if (e.altKey && e.code === 'KeyP') return (this.hud = !this.hud), true;
		if (e.code === 'ArrowUp' && !e.altKey && !e.shiftKey && !isEditable(e.target)) return this.toggleOverview(), true;
		if (e.altKey) return false;

		const plain = {
			KeyL: () => this.openLauncher(),
			KeyN: () => this.newSpace(false),
			KeyT: () => this.openLauncher('', true),
			KeyW: () => this.closePane(),
			KeyR: () => this.reload(),
			BracketLeft: () => this.history(-1),
			BracketRight: () => this.history(1),
			KeyJ: () => this.startHints(false),
			Backslash: () => this.cycleLayout(),
			Comma: () => this.openConfig(),
			Slash: () => (this.help = !this.help)
		};
		const shifted = {
			KeyN: () => this.newSpace(true),
			BracketLeft: () => this.gotoSpace(Math.max(0, this.current - 1)),
			BracketRight: () => this.gotoSpace(Math.min(this.spaces.length - 1, this.current + 1)),
			KeyJ: () => this.startHints(true),
			KeyC: () => this.copyUrl()
		};
		const action = (e.shiftKey ? shifted : plain)[e.code];
		if (!action) return false;
		action();
		return true;
	}

	normal(e) {
		const key = e.key;
		if (this.pending) {
			const sequence = this.pending + key;
			this.pending = null;
			clearTimeout(this.pendingTimer);
			if (sequence === 'gg') return this.scroll('top'), true;
			if (sequence === 'yy') return this.copyUrl(), true;
		}
		switch (key) {
			case 'j':
				this.scroll('down');
				return true;
			case 'k':
				this.scroll('up');
				return true;
			case 'd':
				this.scroll('halfDown');
				return true;
			case 'u':
				this.scroll('halfUp');
				return true;
			case 'G':
				this.scroll('bottom');
				return true;
			case 'g':
			case 'y':
				this.pending = key;
				this.pendingTimer = setTimeout(() => (this.pending = null), 600);
				return true;
			case 'H':
				this.history(-1);
				return true;
			case 'L':
				this.history(1);
				return true;
			case 'r':
				this.reload();
				return true;
			case 'f':
				this.startHints(false);
				return true;
			case 'F':
				this.startHints(true);
				return true;
			case 'o':
				this.openLauncher();
				return true;
			case 'O':
				this.openLauncher('', true);
				return true;
			case ':':
				this.openLauncher(':');
				return true;
			case '@':
				this.openLauncher('@');
				return true;
			case 'x':
				this.closePane();
				return true;
			case 'i':
				this.focusFirstInput();
				return true;
			case '?':
				this.help = !this.help;
				return true;
			default:
				return /^[1-9]$/.test(key) && this.accelerator(key);
		}
	}
}
