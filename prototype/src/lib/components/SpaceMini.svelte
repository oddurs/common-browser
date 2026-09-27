<script>
	// A Space drawn small from its real layout and page colours, so it is recognised by shape.
	let { b, space, width } = $props();

	const scale = $derived(b.size.w ? width / b.size.w : 0);
	const panes = $derived(
		[...b.rects(space)]
			.filter(([, r]) => r.visible)
			.map(([id, r]) => ({ id, r, bg: space.panes.find((p) => p.id === id)?.bg ?? '#ffffff', focus: id === space.focus && !r.bare }))
	);
</script>

<div class="mini" style:width="{width}px" style:height="{Math.round(b.size.h * scale)}px">
	{#each panes as p (p.id)}
		<span
			class="pane"
			class:focus={p.focus}
			style:left="{p.r.x * scale}px"
			style:top="{p.r.y * scale}px"
			style:width="{p.r.w * scale}px"
			style:height="{p.r.h * scale}px"
			style:background={p.bg}
		></span>
	{/each}
</div>

<style>
	.mini {
		position: relative;
		border-radius: 7px;
		overflow: hidden;
		background: var(--deep);
		box-shadow: inset 0 0 0 0.5px var(--line);
		flex-shrink: 0;
	}
	.pane {
		position: absolute;
		border-radius: 2px;
		box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.18);
	}
	.pane.focus {
		box-shadow: 0 0 0 1px var(--ring);
	}
</style>
