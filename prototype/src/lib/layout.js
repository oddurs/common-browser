// Pane geometry for one workspace. Pure, so the tiling rules can be tested without a browser.
// `top` reserves room above tiled panes (the title bar strip of a window); it defaults to the gap.
export function computeLayout(order, focus, layout, width, height, gaps, ratio, top = gaps) {
	const rects = new Map();
	if (!order.length) return rects;

	// A single page, or monocle, owns the whole screen: no gaps, no corners, no glow.
	if (layout === 'monocle' || order.length === 1) {
		const shown = layout === 'monocle' ? focus : order[0];
		for (const id of order) rects.set(id, { x: 0, y: 0, w: width, h: height, visible: id === shown, bare: true });
		return rects;
	}

	const g = gaps;
	const innerW = width - 2 * g;
	const innerH = height - top - g;

	if (layout === 'columns') {
		const w = (innerW - g * (order.length - 1)) / order.length;
		order.forEach((id, i) => rects.set(id, { x: g + i * (w + g), y: top, w, h: innerH, visible: true, bare: false }));
		return rects;
	}

	const masterW = Math.round((innerW - g) * ratio);
	const stackW = innerW - g - masterW;
	const stack = order.slice(1);
	const stackH = (innerH - g * (stack.length - 1)) / stack.length;
	rects.set(order[0], { x: g, y: top, w: masterW, h: innerH, visible: true, bare: false });
	stack.forEach((id, i) =>
		rects.set(id, { x: g + masterW + g, y: top + i * (stackH + g), w: stackW, h: stackH, visible: true, bare: false })
	);
	return rects;
}

// Nearest visible pane in a direction, measured centre to centre; sideways drift counts double.
export function neighbour(rects, from, direction) {
	const a = rects.get(from);
	if (!a) return null;
	const ax = a.x + a.w / 2;
	const ay = a.y + a.h / 2;
	const horizontal = direction === 'left' || direction === 'right';
	let best = null;
	let bestScore = Infinity;
	for (const [id, r] of rects) {
		if (id === from || !r.visible) continue;
		const dx = r.x + r.w / 2 - ax;
		const dy = r.y + r.h / 2 - ay;
		const ahead = { left: dx < -1, right: dx > 1, up: dy < -1, down: dy > 1 }[direction];
		if (!ahead) continue;
		const score = horizontal ? Math.abs(dx) + 2 * Math.abs(dy) : Math.abs(dy) + 2 * Math.abs(dx);
		if (score < bestScore) {
			best = id;
			bestScore = score;
		}
	}
	return best;
}
