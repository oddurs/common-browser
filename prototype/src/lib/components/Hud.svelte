<script>
	import { onMount } from 'svelte';
	import { fly } from 'svelte/transition';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';

	let { b } = $props();

	let canvas;
	let fps = $state(0);
	let p50 = $state(0);
	let p99 = $state(0);
	let late = $state(0);
	let heap = $state(null);

	const SAMPLES = 120;

	onMount(() => {
		const frames = [];
		let last = performance.now();
		let raf;
		let lastStats = 0;
		const ctx = canvas.getContext('2d');
		const style = getComputedStyle(canvas);

		const draw = (now) => {
			frames.push(now - last);
			last = now;
			if (frames.length > SAMPLES) frames.shift();

			if (now - lastStats > 250) {
				lastStats = now;
				const sorted = [...frames].sort((a, c) => a - c);
				const pick = (q) => sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))] ?? 0;
				p50 = pick(0.5);
				p99 = pick(0.99);
				fps = p50 ? 1000 / p50 : 0;
				late = frames.filter((f) => f > p50 * 1.5).length;
				heap = performance.memory ? performance.memory.usedJSHeapSize / 1048576 : null;
			}

			const w = canvas.width;
			const h = canvas.height;
			const scale = h / 34;
			ctx.clearRect(0, 0, w, h);
			const barW = w / SAMPLES;
			frames.forEach((f, i) => {
				ctx.fillStyle = f > p50 * 1.5 ? style.getPropertyValue('--accent') : style.getPropertyValue('--muted');
				const bh = Math.min(h, f * scale);
				ctx.fillRect(i * barW, h - bh, Math.max(1, barW - 1), bh);
			});
			if (p50) {
				ctx.strokeStyle = style.getPropertyValue('--dim');
				ctx.setLineDash([3, 3]);
				ctx.beginPath();
				ctx.moveTo(0, h - p50 * scale);
				ctx.lineTo(w, h - p50 * scale);
				ctx.stroke();
				ctx.setLineDash([]);
			}
			raf = requestAnimationFrame(draw);
		};
		raf = requestAnimationFrame(draw);
		return () => cancelAnimationFrame(raf);
	});
</script>

<aside class="hud" aria-label="Performance" in:fly|global={{ y: 8, duration: ms(MOVE), easing: settle }} out:fly|global={{ y: 8, duration: ms(FADE) }}>
	<header><b>HUD</b><span>measured in this browser tab</span><kbd>⌥P</kbd></header>
	<canvas bind:this={canvas} width="656" height="140"></canvas>
	<dl>
		<dt>frames</dt>
		<dd>{fps.toFixed(0)} fps · p50 {p50.toFixed(1)} · p99 {p99.toFixed(1)} ms</dd>
		<dt>late frames</dt>
		<dd class:warn={late > 0}>{late} of the last {SAMPLES}</dd>
		<dt>key → next frame</dt>
		<dd>{b.latency ? `${b.latency.toFixed(1)} ms` : 'press a key'}</dd>
		<dt>panes</dt>
		<dd>{b.spaces.reduce((n, ws) => n + ws.panes.length, 0)} open · {b.ws?.jar ?? 'own'} logins</dd>
		<dt>JS heap</dt>
		<dd>{heap === null ? 'not exposed by this browser' : `${heap.toFixed(0)} MB`}</dd>
		<dt>scroll</dt>
		<dd>native · keys {b.config?.scroll.keys ?? 'smooth'}</dd>
	</dl>
</aside>

<style>
	.hud {
		position: fixed;
		left: 20px;
		bottom: 20px;
		width: 360px;
		padding: 16px;
		display: flex;
		flex-direction: column;
		gap: 12px;
		border-radius: 14px;
		background: var(--panel);
		backdrop-filter: blur(30px) saturate(180%);
		-webkit-backdrop-filter: blur(30px) saturate(180%);
		border: 0.5px solid var(--line);
		box-shadow: 0 20px 50px rgba(0, 0, 0, 0.35);
		color: var(--fg);
		font: 12px var(--ui);
		font-variant-numeric: tabular-nums;
		z-index: 50;
	}
	header {
		display: flex;
		align-items: center;
		gap: 10px;
	}
	header span {
		flex: 1;
		color: var(--muted);
		font-family: var(--ui);
	}
	canvas {
		width: 100%;
		height: 70px;
		border-radius: 6px;
		background: var(--deep);
	}
	dl {
		margin: 0;
		display: grid;
		grid-template-columns: auto 1fr;
		gap: 6px 14px;
	}
	dt {
		color: var(--muted);
	}
	dd {
		margin: 0;
		text-align: right;
		font-variant-numeric: tabular-nums;
	}
	.warn {
		color: var(--accent);
	}
</style>
