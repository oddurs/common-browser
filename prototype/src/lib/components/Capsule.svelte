<script>
	import { splitUrl } from '$lib/sites.js';
	import { spaceName, spaceColor } from '$lib/browser.svelte.js';

	let { b } = $props();

	const host = $derived(splitUrl(b.focusedPane?.url ?? '')[0]);
	// Modes only mean something with vim keys; standard users see nothing but hints and the launcher.
	const mode = $derived.by(() => {
		const label = b.modeLabel;
		if (label === 'NORMAL' || (label === 'INSERT' && b.config?.keys.mode !== 'vim')) return '';
		return label.toLowerCase();
	});
</script>

<div
	class="capsule"
	class:bar={b.chrome === 'bar'}
	class:shown={b.capsuleVisible}
	role="toolbar"
	aria-label="Common Browser"
	tabindex="-1"
	onmouseenter={() => b.showCapsule()}
	onmouseleave={() => b.chrome === 'capsule' && b.scheduleHide()}
>
	<button class="space" onclick={() => b.toggleOverview()} title="All Spaces (⌘↑)">
		<i style:background={spaceColor(b.ws)}></i>
		<b>{spaceName(b.ws)}</b>
		<span>{b.current + 1} of {b.spaces.length}</span>
	</button>
	<button class="address" onclick={() => b.openLauncher()} title={b.focusedPane?.url ?? ''}>
		{#if host}
			{#if b.focusedPane && !b.focusedPane.external}
				<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2"></rect><path d="M8 11V7a4 4 0 0 1 8 0v4"></path></svg>
			{/if}
			<span>{host}</span>
		{:else}
			<span class="none">Search or enter address</span>
		{/if}
	</button>
	{#if mode}<span class="mode">{mode}</span>{/if}
</div>

<style>
	.capsule {
		position: fixed;
		top: 12px;
		left: 50%;
		height: 36px;
		min-width: 300px;
		max-width: min(560px, calc(100vw - 32px));
		box-sizing: border-box;
		padding: 0 5px;
		display: flex;
		align-items: center;
		gap: 4px;
		border-radius: 18px;
		background: var(--glass);
		backdrop-filter: blur(30px) saturate(180%);
		-webkit-backdrop-filter: blur(30px) saturate(180%);
		border: 0.5px solid var(--line);
		box-shadow: 0 8px 30px rgba(0, 0, 0, 0.18);
		color: var(--fg);
		font-size: 13px;
		font-variant-numeric: tabular-nums;
		transform: translate(-50%, -8px) scale(0.97);
		opacity: 0;
		pointer-events: none;
		transition:
			transform var(--t-move) var(--spring),
			opacity var(--t-fade) ease;
		z-index: 30;
	}
	.capsule.shown {
		transform: translate(-50%, 0) scale(1);
		opacity: 1;
		pointer-events: auto;
	}
	.capsule.bar {
		top: 0;
		left: 0;
		max-width: none;
		width: 100%;
		height: 38px;
		padding: 0 10px 0 84px;
		border-radius: 0;
		border-width: 0 0 0.5px;
		box-shadow: none;
		transform: none;
		opacity: 1;
		pointer-events: auto;
	}
	.space {
		height: 26px;
		padding: 0 10px;
		display: flex;
		align-items: center;
		gap: 7px;
		border: 0;
		border-radius: 13px;
		background: transparent;
		color: var(--fg);
		font: 13px var(--ui);
		white-space: nowrap;
		cursor: default;
		transition: background-color var(--t-fade) ease;
	}
	.space:hover {
		background: var(--sel);
	}
	.space i {
		width: 8px;
		height: 8px;
		border-radius: 50%;
	}
	.space b {
		font-weight: 600;
	}
	.space span {
		color: var(--muted);
		font-variant-numeric: tabular-nums;
	}
	.address {
		flex: 1;
		min-width: 0;
		height: 26px;
		padding: 0 12px;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 6px;
		border: 0;
		border-radius: 13px;
		background: transparent;
		color: var(--fg);
		font: 500 13px var(--ui);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		cursor: text;
		transition: background-color var(--t-fade) ease;
	}
	.address:hover {
		background: var(--sel);
	}
	.address svg {
		flex-shrink: 0;
		color: var(--muted);
	}
	.none {
		color: var(--muted);
		font-weight: 400;
	}
	.mode {
		padding: 0 10px 0 4px;
		color: var(--muted);
		font-size: 11px;
		font-weight: 500;
		letter-spacing: 0.02em;
	}
	button:focus-visible {
		outline: 2px solid var(--ring);
		outline-offset: 1px;
	}
	@media (prefers-reduced-motion: reduce) {
		.capsule {
			transition: none;
		}
	}
</style>
