<script>
	import { fade, scale } from 'svelte/transition';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';

	let { b } = $props();

	const groups = [
		{
			title: 'Browse',
			keys: [
				['⌘L', 'Open location'],
				['⌘T', 'New pane'],
				['⌘W', 'Close pane'],
				['⌘[  ⌘]', 'Back, forward'],
				['⌘R', 'Reload'],
				['⌘J', 'Link hints'],
				['⇧⌘J', 'Link into a new pane'],
				['⇧⌘C', 'Copy link']
			]
		},
		{
			title: 'Spaces and panes',
			keys: [
				['⌘N  ⇧⌘N', 'New Space, New Private Space'],
				['⌘1 – ⌘9', 'Go to a Space by position'],
				['⇧⌘[  ⇧⌘]', 'Previous, next Space'],
				['⌘↑', 'All Spaces'],
				['⇧⌘1 – ⇧⌘9', 'Send page to a Space'],
				['⌥⌘ arrows', 'Focus pane'],
				['⇧⌥⌘ arrows', 'Move pane'],
				['⌘\\', 'Next layout'],
				['⌃⌘F', 'Full screen']
			]
		},
		{
			title: 'Vim keys',
			vim: true,
			keys: [
				['j  k', 'Scroll'],
				['d  u', 'Half page'],
				['gg  G', 'Top, bottom'],
				['H  L', 'Back, forward'],
				['f  F', 'Link hints'],
				['o  O  :', 'Launcher'],
				['i  esc', 'Type in page, stop']
			]
		}
	];
	const vim = $derived(b.config?.keys.mode === 'vim');
</script>

<div class="scrim" role="presentation" onmousedown={() => (b.help = false)} transition:fade|global={{ duration: ms(FADE) }}></div>
<div class="help-wrap" in:scale|global={{ start: 0.97, duration: ms(MOVE), easing: settle }} out:fade|global={{ duration: ms(FADE) }}>
<div class="help" role="dialog" aria-label="Keys">
	<header>
		<h2>Keys</h2>
		<span>Every command is also in the menu bar. In this prototype, use ⌃ wherever your browser keeps a ⌘ shortcut.</span>
	</header>
	<div class="groups">
		{#each groups as group (group.title)}
			<section class:off={group.vim && !vim}>
				<h3>{group.title}{#if group.vim && !vim}<span class="hint"> · off, set keys.mode = "vim"</span>{/if}</h3>
				{#each group.keys as [key, what] (key)}
					<div class="row"><span>{what}</span><kbd>{key}</kbd></div>
				{/each}
			</section>
		{/each}
	</div>
</div>
</div>

<style>
	.scrim {
		position: fixed;
		inset: 0;
		background: var(--scrim);
		z-index: 44;
	}
	.help-wrap {
		position: fixed;
		inset: 0;
		display: grid;
		place-items: center;
		pointer-events: none;
		z-index: 45;
	}
	.help {
		pointer-events: auto;
		width: min(1040px, calc(100vw - 32px));
		max-height: calc(100vh - 48px);
		overflow-y: auto;
		box-sizing: border-box;
		padding: 26px 30px;
		display: flex;
		flex-direction: column;
		gap: 20px;
		border-radius: 20px;
		background: var(--panel);
		backdrop-filter: blur(40px) saturate(180%);
		-webkit-backdrop-filter: blur(40px) saturate(180%);
		border: 0.5px solid var(--line);
		box-shadow: 0 40px 100px rgba(0, 0, 0, 0.4);
		color: var(--fg);
		z-index: 45;
	}
	header {
		display: flex;
		align-items: baseline;
		gap: 16px;
		flex-wrap: wrap;
	}
	h2 {
		margin: 0;
		font-size: 20px;
	}
	header span {
		color: var(--muted);
	}
	code {
		font-family: var(--mono);
		font-size: 0.92em;
		color: var(--fg);
	}
	.groups {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
		gap: 28px;
	}
	h3 {
		margin: 0 0 8px;
		font-size: 11px;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--muted);
	}
	.row {
		display: flex;
		justify-content: space-between;
		gap: 12px;
		padding: 5px 0;
		color: var(--muted);
	}
	.row kbd {
		color: var(--fg);
		white-space: nowrap;
	}
	.off .row {
		opacity: 0.45;
	}
	.hint {
		text-transform: none;
		letter-spacing: 0;
		font-weight: 400;
	}
</style>
