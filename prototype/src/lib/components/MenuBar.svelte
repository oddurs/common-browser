<script>
	import { onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import { FADE, ms } from '$lib/motion.js';
	import { spaceName } from '$lib/browser.svelte.js';

	let { b } = $props();

	let bar;
	let active = $state(-1);

	const vim = $derived(b.config?.keys.mode === 'vim');
	const hasPane = $derived(!!b.focusedPane);

	// The menu bar is the map of the app: every command lives here with its shortcut beside it.
	const menus = $derived([
		{
			title: 'Common Browser',
			items: [
				{ label: 'Settings…', keys: '⌘,', run: () => b.openConfig() },
				{ label: 'Keyboard Shortcuts', keys: '⌘/', run: () => (b.help = true) },
				{ sep: true },
				{ label: vim ? 'Vim Keys Are On' : 'Turn On Vim Keys…', run: () => b.openConfig() }
			]
		},
		{
			title: 'File',
			items: [
				{ label: 'New Space', keys: '⌘N', run: () => b.newSpace(false) },
				{ label: 'New Private Space', keys: '⇧⌘N', run: () => b.newSpace(true) },
				{ sep: true },
				{ label: 'New Pane', keys: '⌘T', run: () => b.openLauncher('', true) },
				{ label: 'Open Location…', keys: '⌘L', run: () => b.openLauncher() },
				{ sep: true },
				{ label: 'Close Pane', keys: '⌘W', run: () => b.closePane(), disabled: !hasPane }
			]
		},
		{
			title: 'Edit',
			items: [{ label: 'Copy Link', keys: '⇧⌘C', run: () => b.copyUrl(), disabled: !hasPane }]
		},
		{
			title: 'View',
			items: [
				{ label: 'Show Link Hints', keys: '⌘J', run: () => b.startHints(false), disabled: !hasPane },
				{ label: 'Open Link in New Pane…', keys: '⇧⌘J', run: () => b.startHints(true), disabled: !hasPane },
				{ sep: true },
				{ label: 'Next Layout', keys: '⌘\\', run: () => b.cycleLayout() },
				{ label: 'Reload Page', keys: '⌘R', run: () => b.reload(), disabled: !hasPane },
				{ sep: true },
				{ label: b.hud ? 'Hide Performance HUD' : 'Show Performance HUD', keys: '⌥⌘P', run: () => (b.hud = !b.hud) },
				{ label: b.fullscreen ? 'Exit Full Screen' : 'Enter Full Screen', keys: '⌃⌘F', run: () => b.toggleFullscreen() }
			]
		},
		{
			title: 'History',
			items: [
				{ label: 'Back', keys: '⌘[', run: () => b.history(-1), disabled: !hasPane },
				{ label: 'Forward', keys: '⌘]', run: () => b.history(1), disabled: !hasPane }
			]
		},
		{
			title: 'Window',
			items: [
				{ label: 'Show All Spaces', keys: '⌘↑', run: () => b.toggleOverview() },
				{ label: 'Previous Space', keys: '⇧⌘[', run: () => b.gotoSpace(b.current - 1) },
				{ label: 'Next Space', keys: '⇧⌘]', run: () => b.gotoSpace(b.current + 1) },
				{ sep: true },
				{ label: 'Focus Pane on the Left', keys: '⌥⌘←', run: () => b.moveFocus('left') },
				{ label: 'Focus Pane on the Right', keys: '⌥⌘→', run: () => b.moveFocus('right') },
				{ label: 'Focus Pane Above', keys: '⌥⌘↑', run: () => b.moveFocus('up') },
				{ label: 'Focus Pane Below', keys: '⌥⌘↓', run: () => b.moveFocus('down') },
				{ sep: true },
				{ label: 'Move Pane Left', keys: '⇧⌥⌘←', run: () => b.swap('left') },
				{ label: 'Move Pane Right', keys: '⇧⌥⌘→', run: () => b.swap('right') },
				{ sep: true },
				...b.spaces.map((space, i) => ({
					label: spaceName(space).replace(/^./, (c) => c.toUpperCase()),
					keys: i < 9 ? `⌘${i + 1}` : '',
					checked: i === b.current,
					run: () => b.gotoSpace(i)
				}))
			]
		},
		{
			title: 'Help',
			items: [
				{ label: 'Keyboard Shortcuts', keys: '⌘/', run: () => (b.help = true) },
				{ label: 'Edit common.toml', keys: '⌘,', run: () => b.openConfig() }
			]
		}
	]);

	const open = $derived(b.menu === null ? null : menus[b.menu]);
	const choices = $derived(open ? open.items.map((item, i) => ({ item, i })).filter(({ item }) => !item.sep && !item.disabled) : []);
	const hidden = $derived(b.fullscreen && !b.capsuleShown && b.menu === null);

	function toggle(i) {
		b.menu = b.menu === i ? null : i;
		active = -1;
	}

	function choose(item) {
		if (!item || item.sep || item.disabled) return;
		b.menu = null;
		item.run();
		const focus = b.ws?.focus;
		if (focus != null && !b.launcher && !b.help && !b.hints) b.focusFrame(focus);
	}

	// Keys reach the browser's single handler first (focus is often inside a page), which hands
	// them here while a menu is open.
	onMount(() => {
		b.menuKey = menuKey;
		return () => (b.menuKey = null);
	});

	function menuKey(e) {
		const at = choices.findIndex(({ i }) => i === active);
		if (e.key === 'ArrowDown') active = choices[(at + 1) % choices.length]?.i ?? -1;
		else if (e.key === 'ArrowUp') active = choices[(at - 1 + choices.length) % choices.length]?.i ?? -1;
		else if (e.key === 'ArrowRight') b.menu = (b.menu + 1) % menus.length;
		else if (e.key === 'ArrowLeft') b.menu = (b.menu - 1 + menus.length) % menus.length;
		else if (e.key === 'Enter') choose(open.items[active]);
		else return;
		e.preventDefault();
		e.stopImmediatePropagation();
	}

	function onmousedown(e) {
		if (b.menu !== null && !bar.contains(e.target)) b.menu = null;
	}
</script>

<svelte:window {onmousedown} />

<header class="menubar" class:hidden class:light={b.theme.mode === 'light'} bind:this={bar} aria-label="Menu bar">
	{#each menus as menu, i (menu.title)}
		<div class="menu">
			<button
				class="title"
				class:app={i === 0}
				class:open={b.menu === i}
				aria-haspopup="menu"
				aria-expanded={b.menu === i}
				onmousedown={(e) => (e.preventDefault(), toggle(i))}
				onmouseenter={() => b.menu !== null && b.menu !== i && ((b.menu = i), (active = -1))}
			>
				{menu.title}
			</button>
			{#if b.menu === i}
				<div class="dropdown" role="menu" aria-label={menu.title} transition:fade={{ duration: ms(FADE) }}>
					{#each menu.items as item, j (j)}
						{#if item.sep}
							<div class="sep" role="separator"></div>
						{:else}
							<button
								role="menuitem"
								class="item"
								class:active={active === j}
								disabled={item.disabled}
								onmouseenter={() => (active = j)}
								onmouseup={() => choose(item)}
							>
								<span class="check" aria-hidden="true">{item.checked ? '✓' : ''}</span>
								<span class="label">{item.label}</span>
								{#if item.keys}<span class="keys">{item.keys}</span>{/if}
							</button>
						{/if}
					{/each}
				</div>
			{/if}
		</div>
	{/each}
</header>

<style>
	.menubar {
		--text: rgba(255, 255, 255, 0.92);
		--muted: rgba(255, 255, 255, 0.5);
		--panel: rgba(38, 38, 42, 0.84);
		--bar: rgba(20, 20, 24, 0.3);
		--edge: rgba(255, 255, 255, 0.14);
		--hover: rgba(255, 255, 255, 0.16);
		--select: #b8643a;
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 26px;
		padding: 0 10px;
		display: flex;
		align-items: center;
		gap: 2px;
		color: var(--text);
		font: 13px -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
		user-select: none;
		z-index: 10;
		transition: transform var(--t-window) var(--spring);
	}
	.menubar.light {
		--text: rgba(0, 0, 0, 0.85);
		--muted: rgba(0, 0, 0, 0.42);
		--panel: rgba(246, 246, 246, 0.88);
		--bar: rgba(255, 255, 255, 0.4);
		--edge: rgba(0, 0, 0, 0.12);
		--hover: rgba(0, 0, 0, 0.1);
	}
	/* The bar's blur lives on its own layer: a blurred parent would stop the dropdown blurring. */
	.menubar::before {
		content: '';
		position: absolute;
		inset: 0;
		z-index: -1;
		background: var(--bar);
		backdrop-filter: blur(30px) saturate(160%);
		-webkit-backdrop-filter: blur(30px) saturate(160%);
	}
	.menubar.hidden {
		transform: translateY(-100%);
	}
	.menu {
		position: relative;
	}
	.title {
		height: 22px;
		padding: 0 9px;
		border: 0;
		border-radius: 5px;
		background: transparent;
		color: inherit;
		font: inherit;
		cursor: default;
	}
	.title.app {
		font-weight: 700;
	}
	.title.open {
		background: var(--hover);
	}
	.dropdown {
		position: absolute;
		top: 25px;
		left: 0;
		min-width: 240px;
		padding: 5px;
		display: flex;
		flex-direction: column;
		border-radius: 8px;
		background: var(--panel);
		backdrop-filter: blur(40px) saturate(180%);
		-webkit-backdrop-filter: blur(40px) saturate(180%);
		box-shadow:
			0 0 0 0.5px var(--edge),
			0 12px 36px rgba(0, 0, 0, 0.3);
	}
	.item {
		height: 22px;
		padding: 0 10px 0 4px;
		display: flex;
		align-items: center;
		border: 0;
		border-radius: 4px;
		background: transparent;
		color: var(--text);
		font: inherit;
		text-align: left;
		cursor: default;
	}
	.item.active:not(:disabled) {
		background: var(--select);
		color: #fff;
	}
	.item:disabled {
		color: var(--muted);
	}
	.check {
		width: 18px;
		flex-shrink: 0;
		text-align: center;
		font-size: 11px;
	}
	.label {
		flex: 1;
		white-space: nowrap;
	}
	.keys {
		padding-left: 28px;
		color: var(--muted);
		letter-spacing: 0.04em;
		font-variant-numeric: tabular-nums;
	}
	.item.active:not(:disabled) .keys {
		color: rgba(255, 255, 255, 0.8);
	}
	.sep {
		height: 1px;
		margin: 5px 10px;
		background: var(--edge);
	}
</style>
