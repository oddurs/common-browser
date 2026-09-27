<script>
	let { b } = $props();
</script>

<!-- Close and minimise do nothing in the prototype; the green button switches full screen like macOS. -->
<div class="lights" class:hidden={b.fullscreen && !b.capsuleShown}>
	<button class="close" aria-label="Close window (not in the prototype)" tabindex="-1">
		<svg viewBox="0 0 12 12" aria-hidden="true"><path d="M3.8 3.8l4.4 4.4M8.2 3.8l-4.4 4.4"></path></svg>
	</button>
	<button class="minimise" aria-label="Minimise window (not in the prototype)" tabindex="-1">
		<svg viewBox="0 0 12 12" aria-hidden="true"><path d="M3.2 6h5.6"></path></svg>
	</button>
	<button class="zoom" aria-label={b.fullscreen ? 'Exit full screen' : 'Enter full screen'} onclick={() => b.toggleFullscreen()}>
		<svg viewBox="0 0 12 12" aria-hidden="true"><path class="fill" d="M3.6 8.4V5.1l3.3 3.3zM8.4 3.6v3.3L5.1 3.6z"></path></svg>
	</button>
</div>

<style>
	.lights {
		position: absolute;
		top: 14px;
		left: 14px;
		display: flex;
		gap: 8px;
		z-index: 50;
		transition: opacity var(--t-fade) ease;
	}
	.lights.hidden {
		opacity: 0;
		pointer-events: none;
	}
	button {
		width: 12px;
		height: 12px;
		padding: 0;
		border: 0;
		border-radius: 50%;
		display: grid;
		place-items: center;
		cursor: default;
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.22);
	}
	.close {
		background: #ff5f57;
	}
	.minimise {
		background: #febc2e;
	}
	.zoom {
		background: #28c840;
	}
	svg {
		width: 12px;
		height: 12px;
		opacity: 0;
		stroke: rgba(0, 0, 0, 0.55);
		stroke-width: 1.2;
		stroke-linecap: round;
		fill: none;
	}
	svg .fill {
		fill: rgba(0, 0, 0, 0.55);
		stroke: none;
	}
	.lights:hover svg {
		opacity: 1;
	}
	.zoom:focus-visible {
		outline: 2px solid var(--ring);
		outline-offset: 2px;
	}
</style>
