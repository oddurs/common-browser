// The prototype's web is a handful of local pages served from static/site. Each has the address
// it pretends to live at, so the capsule and launcher read like a real browser.
export const SITES = [
	{ slug: 'notes', path: '/site/notes.html', url: 'notes.example.org/scroll-physics', title: 'The physics of a good scroll' },
	{ slug: 'forum', path: '/site/forum.html', url: 'forum.example.net/front', title: 'Forum — front' },
	{ slug: 'tessera', path: '/site/tessera.html', url: 'tessera.example.dev/guide/layout', title: 'Layout primitives — tessera' },
	{ slug: 'pr', path: '/site/pr.html', url: 'code.example.dev/common/browser/pull/418', title: 'Pull request #418 · common/browser' },
	{ slug: 'playground', path: '/site/playground.html', url: 'localhost:5173/boards/new', title: 'tessera playground' },
	{ slug: 'new', path: '/site/new.html', url: 'common://new', title: 'New pane' },
	{ slug: 'search', path: '/site/search.html', url: 'search.example/?q=', title: 'Search' }
];

export function srcFor(target) {
	const t = String(target ?? '').trim();
	if (!t) return null;
	const bySlug = SITES.find((s) => s.slug === t);
	if (bySlug) return bySlug.path;
	if (t.startsWith('/site/')) return t;
	const byUrl = SITES.find((s) => s.url === t || s.url.split('/')[0] === t);
	if (byUrl) return byUrl.path;
	if (/^https?:\/\//.test(t)) return t;
	if (/^[\w-]+(\.[\w-]+)+(:\d+)?(\/\S*)?$/.test(t)) return `https://${t}`;
	return null;
}

export function searchSrc(query, via = '') {
	const params = new URLSearchParams({ q: query });
	if (via) params.set('via', via);
	return `/site/search.html?${params}`;
}

export function describe(location) {
	const site = SITES.find((s) => s.path === location.pathname);
	if (!site) return { url: location.href, title: location.href };
	if (site.slug === 'search') {
		const q = new URLSearchParams(location.search).get('q') ?? '';
		return { url: `${site.url}${encodeURIComponent(q)}`, title: `${q} — Search` };
	}
	return { url: site.url, title: site.title };
}

export function splitUrl(url) {
	const clean = String(url ?? '').replace(/^https?:\/\//, '');
	const slash = clean.indexOf('/');
	return slash < 0 ? [clean, ''] : [clean.slice(0, slash), clean.slice(slash)];
}
