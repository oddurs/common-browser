<script>
	import { fade, fly } from 'svelte/transition';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';
	import { spaceName, spaceColor } from '$lib/browser.svelte.js';
	import SpaceMini from './SpaceMini.svelte';

	let { b } = $props();

	const TILE = 132;
	const height = $derived(b.size.w ? Math.round((b.size.h * TILE) / b.size.w) : 0);
</script>

<div class="strip" role="status" aria-label="{spaceName(b.ws)}, Space {b.current + 1} of {b.spaces.length}" in:fly={{ y: 10, duration: ms(MOVE), easing: settle }} out:fade={{ duration: ms(FADE * 2) }}>
	<div class="row" style:--tile="{TILE}px" style:--tile-h="{height}px">
		<!-- One frame glides along the row to where you are: the direction of travel is the point. -->
		<span class="marker" style:transform="translateX({b.current * (TILE + 12)}px)"></span>
		{#each b.spaces as space, i (space.id)}
			<div class="tile" class:current={i === b.current}>
				<SpaceMini {b} {space} width={TILE} />
				<span class="name"><i style:background={spaceColor(space)}></i><b>{i + 1}</b>{spaceName(space)}</span>
			</div>
		{/each}
	</div>
</div>

<style>
	.strip {
		position: fixed;
		left: 50%;
		bottom: 28px;
		transform: translateX(-50%);
		max-width: calc(100% - 32px);
		overflow: hidden;
		padding: 12px 12px 10px;
		border-radius: 18px;
		background: var(--glass);
		backdrop-filter: blur(30px) saturate(180%);
		-webkit-backdrop-filter: blur(30px) saturate(180%);
		border: 0.5px solid var(--line);
		box-shadow: 0 14px 40px rgba(0, 0, 0, 0.25);
		z-index: 25;
		pointer-events: none;
	}
	.row {
		position: relative;
		display: flex;
		gap: 12px;
	}
	.marker {
		position: absolute;
		top: -4px;
		left: -4px;
		width: calc(var(--tile) + 8px);
		height: calc(var(--tile-h) + 8px);
		border-radius: 10px;
		box-shadow: 0 0 0 1.5px var(--ring);
		transition: transform var(--t-space) var(--spring);
	}
	.tile {
		width: var(--tile);
		display: flex;
		flex-direction: column;
		gap: 7px;
		opacity: 0.55;
		transition: opacity var(--t-move) ease;
	}
	.tile.current {
		opacity: 1;
	}
	.name {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: 12px;
		color: var(--muted);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.name i {
		width: 7px;
		height: 7px;
		border-radius: 50%;
		flex-shrink: 0;
	}
	.name b {
		color: var(--fg);
		font-weight: 600;
		font-variant-numeric: tabular-nums;
	}
</style>
