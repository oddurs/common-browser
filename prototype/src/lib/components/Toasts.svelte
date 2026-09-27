<script>
	import { fade, fly } from 'svelte/transition';
	import { flip } from 'svelte/animate';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';

	let { b } = $props();
</script>

<div class="toasts" class:under-capsule={b.capsuleVisible && b.chrome === 'capsule'} class:under-bar={b.chrome === 'bar'} aria-live="polite">
	{#each b.toasts as t (t.id)}
		<button
			class="toast"
			class:error={t.kind === 'error'}
			onclick={() => b.dismiss(t.id)}
			title="Dismiss"
			in:fly={{ y: -8, duration: ms(MOVE), easing: settle }}
			out:fade={{ duration: ms(FADE) }}
			animate:flip={{ duration: ms(MOVE), easing: settle }}
		>
			<span class="title">{t.title}</span>
			{#if t.lines?.length}
				<span class="code">{#each t.lines as line (line)}<span>{line}</span>{/each}</span>
			{/if}
			{#if t.body}<span class="text">{t.body}</span>{/if}
		</button>
	{/each}
</div>

<style>
	.toasts {
		position: fixed;
		top: 16px;
		right: 16px;
		width: min(340px, calc(100vw - 32px));
		display: flex;
		flex-direction: column;
		gap: 8px;
		z-index: 60;
		transition: top var(--t-move) var(--spring);
	}
	/* Clear the capsule instead of sitting on top of it. */
	.toasts.under-capsule {
		top: 60px;
	}
	.toasts.under-bar {
		top: 48px;
	}
	.toast {
		display: flex;
		flex-direction: column;
		gap: 4px;
		padding: 12px 14px;
		text-align: left;
		border-radius: 14px;
		background: var(--glass);
		backdrop-filter: blur(30px) saturate(180%);
		-webkit-backdrop-filter: blur(30px) saturate(180%);
		border: 0.5px solid var(--line);
		box-shadow: 0 10px 30px rgba(0, 0, 0, 0.18);
		color: var(--fg);
		font: 13px var(--ui);
		cursor: default;
	}
	.title {
		display: flex;
		align-items: center;
		gap: 7px;
		font-weight: 600;
	}
	.error .title::before {
		content: '';
		width: 7px;
		height: 7px;
		border-radius: 50%;
		background: var(--red);
	}
	.code {
		display: flex;
		flex-direction: column;
		font: 11.5px/1.5 var(--mono);
		color: var(--muted);
		overflow-wrap: anywhere;
	}
	.text {
		color: var(--muted);
		line-height: 1.45;
	}
</style>
