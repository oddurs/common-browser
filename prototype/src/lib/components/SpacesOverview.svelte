<script>
	import { onMount } from 'svelte';
	import { fade, scale } from 'svelte/transition';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';
	import { spaceName, spaceColor, TINTS } from '$lib/browser.svelte.js';
	import SpaceMini from './SpaceMini.svelte';

	let { b } = $props();

	const TILE = 220;
	let grid;

	onMount(() => grid.querySelector('.current')?.focus());

	// Arrow keys walk the tiles; Tab works too, since every tile is a button.
	function onkeydown(e) {
		const tiles = [...grid.querySelectorAll('button')];
		const at = tiles.indexOf(document.activeElement);
		const step = { ArrowRight: 1, ArrowLeft: -1 }[e.key];
		if (!step) return;
		e.preventDefault();
		e.stopPropagation();
		tiles[(at + step + tiles.length) % tiles.length]?.focus();
	}
</script>

<div class="overview" role="dialog" aria-label="All Spaces" transition:fade|global={{ duration: ms(FADE) }}>
	<div class="grid" bind:this={grid} {onkeydown} role="presentation" in:scale|global={{ start: 0.97, duration: ms(MOVE), easing: settle }}>
		{#each b.spaces as space, i (space.id)}
			<button class="tile" class:current={i === b.current} onclick={() => b.gotoSpace(i)}>
				<SpaceMini {b} {space} width={TILE} />
				<span class="name"><i style:background={spaceColor(space)}></i>{spaceName(space)}</span>
				<span class="meta">{i < 9 ? `⌘${i + 1} · ` : ''}{space.panes.length} {space.panes.length === 1 ? 'page' : 'pages'}{space.jar ? ` · ${space.jar} logins` : ''}</span>
			</button>
		{/each}
		<button class="tile add" onclick={() => b.newSpace(false)}>
			<span class="blank" style:width="{TILE}px">+</span>
			<span class="name">New Space</span>
			<span class="meta">⌘N</span>
		</button>
	</div>
	{#if b.archived.length}
		<div class="archived">
			<span class="label">Recently closed</span>
			{#each b.archived as entry, i (i)}
				<button class="chip" onclick={() => b.restoreSpace(i)}><i style:background={TINTS[entry.tint]}></i>{entry.name}<span>{entry.open.length} {entry.open.length === 1 ? 'page' : 'pages'}</span></button>
			{/each}
		</div>
	{/if}
	<p class="hint">Click a Space or use ← → and Return. <kbd>esc</kbd> closes.</p>
</div>

<style>
	.overview {
		position: fixed;
		inset: 0;
		z-index: 42;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 28px;
		padding: 40px;
		background: var(--glass);
		backdrop-filter: blur(26px) saturate(160%);
		-webkit-backdrop-filter: blur(26px) saturate(160%);
	}
	.grid {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 28px;
		max-width: 100%;
	}
	.tile {
		display: flex;
		flex-direction: column;
		gap: 8px;
		padding: 0;
		border: 0;
		background: none;
		color: var(--fg);
		font: inherit;
		text-align: left;
		cursor: default;
		border-radius: 9px;
	}
	.tile :global(.mini) {
		transition: box-shadow var(--t-fade) ease;
	}
	.tile.current :global(.mini) {
		box-shadow: 0 0 0 2px var(--ring);
	}
	.tile:hover :global(.mini),
	.tile:focus-visible :global(.mini) {
		box-shadow:
			0 0 0 2px var(--line),
			0 0 0 4px var(--ring);
	}
	.tile:focus-visible {
		outline: none;
	}
	.name {
		display: flex;
		align-items: center;
		gap: 7px;
		font-size: 13px;
		font-weight: 600;
	}
	.name i,
	.chip i {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		flex-shrink: 0;
	}
	.meta {
		margin-top: -4px;
		font-size: 12px;
		color: var(--muted);
		font-variant-numeric: tabular-nums;
	}
	.blank {
		aspect-ratio: 16 / 10;
		border-radius: 7px;
		display: grid;
		place-items: center;
		font-size: 28px;
		font-weight: 300;
		color: var(--muted);
		box-shadow: inset 0 0 0 1px var(--line);
	}
	.archived {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: center;
		gap: 8px;
	}
	.label {
		font-size: 12px;
		color: var(--muted);
		margin-right: 6px;
	}
	.chip {
		height: 28px;
		padding: 0 12px;
		display: flex;
		align-items: center;
		gap: 7px;
		border: 0.5px solid var(--line);
		border-radius: 14px;
		background: var(--fill);
		color: var(--fg);
		font: 12.5px var(--ui);
		opacity: 0.75;
	}
	.chip:hover,
	.chip:focus-visible {
		opacity: 1;
		outline: none;
	}
	.chip span {
		color: var(--muted);
	}
	.hint {
		margin: 0;
		font-size: 12px;
		color: var(--muted);
	}
</style>
