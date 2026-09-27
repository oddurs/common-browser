<script>
	import { splitUrl } from '$lib/sites.js';
	import { fade, scale } from 'svelte/transition';
	import { FADE, MOVE, ms, settle } from '$lib/motion.js';

	let { b } = $props();

	let text = $state(b.launcher.text);
	let selected = $state(0);
	let input;

	const results = $derived(b.results(text));

	$effect(() => {
		input.focus();
		input.setSelectionRange(text.length, text.length);
	});

	function glyph(r) {
		if (r.kind === 'site' || r.kind === 'url' || r.kind === 'pane') return (splitUrl(r.detail)[0].replace(/^www\./, '')[0] ?? '·').toUpperCase();
		return '';
	}

	// Details are for recognising a result, so show the site, not the full address.
	function subtitle(r) {
		if (r.kind === 'site' || r.kind === 'url') return splitUrl(r.detail)[0];
		if (r.kind === 'search' || r.kind === 'bang') return splitUrl(r.detail)[0];
		return r.detail;
	}

	function onkeydown(e) {
		e.stopPropagation();
		if (e.key === 'Escape') {
			e.preventDefault();
			b.closeLauncher();
		} else if (e.key === 'ArrowDown' || (e.ctrlKey && e.key === 'n')) {
			e.preventDefault();
			selected = Math.min(selected + 1, results.length - 1);
		} else if (e.key === 'ArrowUp' || (e.ctrlKey && e.key === 'p')) {
			e.preventDefault();
			selected = Math.max(selected - 1, 0);
		} else if (e.key === 'Tab') {
			e.preventDefault();
			const r = results[selected];
			if (r?.complete) text = r.complete;
			else if (r?.kind === 'cmd') text = r.label;
		} else if (e.key === 'Enter') {
			e.preventDefault();
			const r = results[selected];
			if (r?.complete && !r.src && !r.run) text = r.complete;
			else if (r) b.launch(r, e.altKey || b.launcher.newPane);
		}
	}
</script>

<div class="scrim" role="presentation" onmousedown={() => b.closeLauncher()} transition:fade|global={{ duration: ms(FADE) }}></div>
<div class="launcher" role="dialog" aria-label="Launcher" in:scale|global={{ start: 0.97, duration: ms(MOVE), easing: settle }} out:scale|global={{ start: 0.98, duration: ms(FADE) }}>
	<label class="field">
		<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-3.5-3.5"></path></svg>
		<input
			id="launcher-input"
			bind:this={input}
			bind:value={text}
			oninput={() => (selected = 0)}
			{onkeydown}
			placeholder={b.launcher.newPane ? 'Open in a new pane' : 'Search or enter address'}
			spellcheck="false"
			autocomplete="off"
			aria-label="Launcher"
		/>
	</label>
	{#if results.length}
		<ul role="listbox" aria-label="Results">
			{#each results as r, i (r.kind + r.label + i)}
				<li role="option" aria-selected={i === selected} class:selected={i === selected} onmousemove={() => (selected = i)} onmousedown={(e) => (e.preventDefault(), b.launch(r, e.altKey || b.launcher.newPane))}>
					<span class="icon" aria-hidden="true">
						{#if r.kind === 'search' || r.kind === 'bang'}
							<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-3.5-3.5"></path></svg>
						{:else if r.kind === 'cmd'}
							<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"></path></svg>
						{:else}
							{glyph(r)}
						{/if}
					</span>
					<span class="text">
						<span class="label">{r.label}</span>
						{#if subtitle(r)}<span class="detail">{subtitle(r)}</span>{/if}
					</span>
					{#if i === selected}<span class="enter" aria-hidden="true">↵</span>{/if}
				</li>
			{/each}
		</ul>
	{/if}
</div>

<style>
	/* Blurring a backdrop layer is cheaper than filtering every page behind it. */
	.scrim {
		position: fixed;
		inset: 0;
		background: var(--scrim);
		backdrop-filter: blur(10px);
		-webkit-backdrop-filter: blur(10px);
		z-index: 40;
	}
	.launcher {
		position: fixed;
		top: 18vh;
		left: calc(50% - min(320px, 50vw - 16px));
		width: min(640px, calc(100vw - 32px));
		display: flex;
		flex-direction: column;
		background: var(--panel);
		backdrop-filter: blur(40px) saturate(180%);
		-webkit-backdrop-filter: blur(40px) saturate(180%);
		border: 0.5px solid var(--line);
		border-radius: 18px;
		box-shadow: 0 30px 90px rgba(0, 0, 0, 0.3);
		overflow: hidden;
		z-index: 41;
		transform-origin: 50% 0;
	}
	.field {
		height: 58px;
		padding: 0 20px;
		display: flex;
		align-items: center;
		gap: 12px;
		color: var(--muted);
	}
	input {
		flex: 1;
		min-width: 0;
		border: 0;
		outline: none;
		background: transparent;
		color: var(--fg);
		font: 400 21px var(--ui);
		letter-spacing: -0.01em;
		caret-color: var(--accent);
	}
	input::placeholder {
		color: var(--dim);
	}
	ul {
		list-style: none;
		margin: 0;
		padding: 6px;
		border-top: 0.5px solid var(--line);
		max-height: 52vh;
		overflow-y: auto;
	}
	li {
		display: flex;
		align-items: center;
		gap: 12px;
		min-height: 46px;
		padding: 0 12px;
		border-radius: 10px;
		cursor: default;
	}
	li.selected {
		background: var(--sel-strong);
	}
	.icon {
		flex-shrink: 0;
		width: 28px;
		height: 28px;
		border-radius: 7px;
		display: grid;
		place-items: center;
		background: var(--sel);
		color: var(--muted);
		font: 600 12px var(--ui);
	}
	.text {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 1px;
	}
	.label {
		font-size: 14px;
		color: var(--fg);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.detail {
		font-size: 12px;
		color: var(--muted);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.enter {
		color: var(--muted);
		font-size: 13px;
	}
</style>
