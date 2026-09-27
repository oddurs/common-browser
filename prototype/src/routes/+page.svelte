<script>
	import { onMount } from 'svelte';
	import { Browser } from '$lib/browser.svelte.js';
	import Capsule from '$lib/components/Capsule.svelte';
	import Launcher from '$lib/components/Launcher.svelte';
	import Toasts from '$lib/components/Toasts.svelte';
	import Hud from '$lib/components/Hud.svelte';
	import Help from '$lib/components/Help.svelte';
	import TrafficLights from '$lib/components/TrafficLights.svelte';
	import MenuBar from '$lib/components/MenuBar.svelte';
	import SpaceStrip from '$lib/components/SpaceStrip.svelte';
	import SpacesOverview from '$lib/components/SpacesOverview.svelte';
	import { spaceName } from '$lib/browser.svelte.js';
	import { fade, fly } from 'svelte/transition';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';


	const b = new Browser();
	onMount(() => b.start());

	const focus = $derived(b.config?.tiling.focus ?? 'border');
	const LAYOUT_NAMES = { master: 'Master and stack', columns: 'Columns', monocle: 'One at a time' };
</script>

<svelte:window onkeydown={b.onKey} onmousemove={(e) => b.onPointer(e.clientY)} />

<div class="desktop" class:fullscreen={b.fullscreen} class:light={b.theme.mode === 'light'}>
<MenuBar {b} />
<div class="app" bind:this={b.windowEl} style={b.cssVars}>
	<div class="stage" class:bar={b.chrome === 'bar'} class:animate={b.animating} bind:clientWidth={b.size.w} bind:clientHeight={b.size.h}>
		{#each b.spaces as ws, i (ws.id)}
			{@const rects = b.rects(ws)}
			<section class="workspace" style:transform="translateX({(i - b.current) * 100}%)" aria-hidden={i !== b.current} aria-label="{spaceName(ws)}, Space {i + 1}">
				{#if !ws.panes.length}
					<div class="empty">
						<span class="n">{spaceName(ws)}</span>
						<p>Nothing open yet. <kbd>⌘L</kbd> to go somewhere.</p>
					</div>
				{/if}
				{#each ws.panes as pane (pane.id)}
					{@const r = rects.get(pane.id) ?? { x: 0, y: 0, w: 0, h: 0, visible: false, bare: true }}
					<div
						in:fade|local={{ duration: ms(MOVE) }}
						out:fade|local={{ duration: ms(FADE) }}
						class="pane focus-{focus}"
						class:focused={pane.id === ws.focus && !r.bare}
						class:bare={r.bare}
						style:left="{r.x}px"
						style:top="{r.y}px"
						style:width="{r.w}px"
						style:height="{r.h}px"
						style:visibility={r.visible ? 'visible' : 'hidden'}
					>
						<iframe src={pane.initial} title={pane.title} use:b.attach={pane}></iframe>
					</div>
				{/each}
			</section>
		{/each}

		{#if b.hints}
			<div class="hints" aria-hidden="true" transition:fade={{ duration: ms(80) }}>
				{#each b.hints.items as h (h.label)}
					{#if h.label.startsWith(b.hints.typed)}
						<span class="hint" class:inside={h.inside} style:left="{h.x}px" style:top="{h.y}px"><b>{b.hints.typed}</b>{h.label.slice(b.hints.typed.length)}</span>
					{/if}
				{/each}
			</div>
		{/if}
	</div>

	{#if b.overview}
		<SpacesOverview {b} />
	{:else if b.pill?.kind === 'space'}
		<SpaceStrip {b} />
	{:else if b.pill?.kind === 'layout'}
		<div class="pill" role="status" in:fly={{ y: 6, duration: ms(MOVE), easing: settle }} out:fade={{ duration: ms(FADE) }}>
			<span>{LAYOUT_NAMES[b.layoutName]}</span>
		</div>
	{/if}

	<Capsule {b} />
	{#if b.launcher}<Launcher {b} />{/if}
	{#if b.hud}<Hud {b} />{/if}
	{#if b.help}<Help {b} />{/if}
	<Toasts {b} />
	<TrafficLights {b} />
</div>
</div>

<style>
	:global(html, body) {
		height: 100%;
		margin: 0;
		overflow: hidden;
		background: #111;
	}
	:global(kbd) {
		font-family: var(--mono);
		font-size: 0.85em;
		padding: 1px 5px;
		border-radius: 4px;
		background: var(--fill);
		border: 1px solid var(--line);
	}
	/* A stand-in desktop so the window reads as a Mac app: wallpaper, menu bar, padding. */
	.desktop {
		--spring: cubic-bezier(0.32, 0.72, 0, 1);
		--t-fade: 140ms;
		--t-move: 220ms;
		--t-space: 300ms;
		--t-window: 380ms;
		position: fixed;
		inset: 0;
		overflow: hidden;
		background:
			radial-gradient(1100px 800px at 12% 18%, #43303a 0%, transparent 62%),
			radial-gradient(1000px 900px at 88% 85%, #1d3445 0%, transparent 60%),
			radial-gradient(800px 640px at 72% 8%, #4d3526 0%, transparent 58%),
			#121418;
	}
	.desktop.light {
		background:
			radial-gradient(1100px 800px at 12% 18%, #f1d6c4 0%, transparent 62%),
			radial-gradient(1000px 900px at 88% 85%, #c9dde9 0%, transparent 60%),
			radial-gradient(800px 640px at 72% 8%, #eadbc8 0%, transparent 58%),
			#e7e4e0;
	}
	/* The transform makes this the containing block for every fixed overlay inside, so the
	   launcher, capsule and notifications stay within the window. */
	.app {
		position: absolute;
		top: 50px;
		left: 48px;
		right: 48px;
		bottom: 40px;
		overflow: hidden;
		border-radius: 12px;
		transform: translateZ(0);
		box-shadow:
			0 0 0 0.5px rgba(0, 0, 0, 0.55),
			0 34px 90px rgba(0, 0, 0, 0.45),
			0 10px 28px rgba(0, 0, 0, 0.25);
		transition:
			top var(--t-window) var(--spring),
			left var(--t-window) var(--spring),
			right var(--t-window) var(--spring),
			bottom var(--t-window) var(--spring),
			border-radius var(--t-window) var(--spring);
		background: var(--deep);
		color: var(--fg);
		font-family: var(--ui);
		font-size: var(--size);
		-webkit-font-smoothing: antialiased;
	}
	.fullscreen .app {
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		border-radius: 0;
	}
	/* Hairline highlight on the window edge, as macOS draws it. */
	.app::after {
		content: '';
		position: absolute;
		inset: 0;
		border-radius: inherit;
		box-shadow: inset 0 0 0 0.5px rgba(255, 255, 255, 0.14);
		pointer-events: none;
		z-index: 100;
	}
	.stage {
		position: absolute;
		inset: 0;
		overflow: hidden;
	}
	.stage.bar {
		top: 40px;
	}
	.workspace {
		position: absolute;
		inset: 0;
		transition: transform var(--t-space) var(--spring);
		will-change: transform;
	}
	.pane {
		position: absolute;
		overflow: hidden;
		background: #fff;
		border-radius: var(--corner);
		box-shadow: 0 0 0 1px var(--line);
		transition: box-shadow var(--t-fade) ease;
	}
	.stage.animate .pane {
		transition:
			left var(--t-move) var(--spring),
			top var(--t-move) var(--spring),
			width var(--t-move) var(--spring),
			height var(--t-move) var(--spring),
			box-shadow var(--t-fade) ease;
	}
	.pane.bare {
		border-radius: 0;
		box-shadow: none;
	}
	.pane.focused.focus-border {
		box-shadow: 0 0 0 1.5px var(--ring);
	}
	.pane.focused.focus-glow {
		box-shadow:
			0 0 0 1.5px var(--ring),
			0 0 24px var(--glow);
	}
	/* Unfocused panes step back a little; a veil that lets clicks through. */
	.pane:not(.bare)::after {
		content: '';
		position: absolute;
		inset: 0;
		background: rgba(0, 0, 0, 0.07);
		pointer-events: none;
		opacity: 0;
		transition: opacity var(--t-fade) ease;
	}
	.pane:not(.focused):not(.bare)::after {
		opacity: 1;
	}
	iframe {
		display: block;
		width: 100%;
		height: 100%;
		border: 0;
	}
	.empty {
		position: absolute;
		inset: 0;
		display: grid;
		place-content: center;
		justify-items: center;
		gap: 12px;
		color: var(--muted);
	}
	.empty .n {
		font-size: 34px;
		font-weight: 300;
		color: var(--dim);
	}
	.empty p {
		margin: 0;
	}
	.hints {
		position: absolute;
		inset: 0;
		pointer-events: none;
	}
	/* Neutral chips so hints read as part of the app, not paint on the page. */
	.hint {
		position: absolute;
		transform: translate(calc(-100% - 6px), -50%);
		padding: 1px 5px;
		border-radius: 5px;
		background: rgba(28, 28, 30, 0.9);
		color: #fff;
		font: 600 11px/1.45 var(--mono);
		letter-spacing: 0.02em;
		box-shadow:
			0 0 0 0.5px rgba(255, 255, 255, 0.18),
			0 2px 8px rgba(0, 0, 0, 0.25);
	}
	.hint.inside {
		transform: translate(2px, -50%);
	}
	.hint b {
		font-weight: 600;
		opacity: 0.4;
	}
	.pill {
		position: fixed;
		left: 50%;
		bottom: 28px;
		transform: translateX(-50%);
		height: 34px;
		padding: 0 16px;
		display: flex;
		align-items: center;
		gap: 8px;
		border-radius: 17px;
		background: var(--glass);
		backdrop-filter: blur(24px) saturate(180%);
		-webkit-backdrop-filter: blur(24px) saturate(180%);
		border: 0.5px solid var(--line);
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.18);
		color: var(--fg);
		font-size: 13px;
		font-variant-numeric: tabular-nums;
		z-index: 20;
	}
	.pill span {
		color: var(--muted);
	}
	@media (prefers-reduced-motion: reduce) {
		.desktop {
			--t-fade: 0ms;
			--t-move: 0ms;
			--t-space: 0ms;
			--t-window: 0ms;
		}
		.workspace,
		.pane,
		.stage,
		.app {
			transition: none;
		}
	}
</style>
