export const THEMES = {
	// Common's own pair: macOS-neutral greys with one copper accent. The default.
	graphite: { mode: 'dark', bg: '#1e1e20', deep: '#161618', surface: '#2a2a2d', hl: '#2f2f33', border: '#3a3a3e', fg: '#ececee', muted: '#a1a1a6', dim: '#6b6b70', accent: '#d9895b', accent2: '#b7a3d9', green: '#8fbf8a', yellow: '#d8b36a', red: '#e0736a', cyan: '#86b8c8', orange: '#d9895b' },
	paper: { mode: 'light', bg: '#f6f5f3', deep: '#eceae6', surface: '#ffffff', hl: '#e6e4df', border: '#d6d3cd', fg: '#1d1d1f', muted: '#6e6e73', dim: '#a1a09c', accent: '#b8643a', accent2: '#7d6aa8', green: '#4f8a4a', yellow: '#a87a1e', red: '#c2463d', cyan: '#3b7c8c', orange: '#b8643a' },
	'tokyo-night': { mode: 'dark', bg: '#1a1b26', deep: '#16161e', surface: '#24283b', hl: '#292e42', border: '#3b4261', fg: '#c0caf5', muted: '#a9b1d6', dim: '#565f89', accent: '#7aa2f7', accent2: '#bb9af7', green: '#9ece6a', yellow: '#e0af68', red: '#f7768e', cyan: '#7dcfff', orange: '#ff9e64' },
	catppuccin: { mode: 'dark', bg: '#1e1e2e', deep: '#181825', surface: '#313244', hl: '#313244', border: '#45475a', fg: '#cdd6f4', muted: '#a6adc8', dim: '#6c7086', accent: '#89b4fa', accent2: '#cba6f7', green: '#a6e3a1', yellow: '#f9e2af', red: '#f38ba8', cyan: '#94e2d5', orange: '#fab387' },
	gruvbox: { mode: 'dark', bg: '#282828', deep: '#1d2021', surface: '#3c3836', hl: '#3c3836', border: '#504945', fg: '#ebdbb2', muted: '#a89984', dim: '#7c6f64', accent: '#fabd2f', accent2: '#d3869b', green: '#b8bb26', yellow: '#fabd2f', red: '#fb4934', cyan: '#8ec07c', orange: '#fe8019' },
	nord: { mode: 'dark', bg: '#2e3440', deep: '#242933', surface: '#3b4252', hl: '#434c5e', border: '#4c566a', fg: '#eceff4', muted: '#d8dee9', dim: '#7b88a1', accent: '#88c0d0', accent2: '#b48ead', green: '#a3be8c', yellow: '#ebcb8b', red: '#bf616a', cyan: '#8fbcbb', orange: '#d08770' },
	'rose-pine': { mode: 'dark', bg: '#191724', deep: '#13111c', surface: '#1f1d2e', hl: '#26233a', border: '#403d52', fg: '#e0def4', muted: '#908caa', dim: '#6e6a86', accent: '#c4a7e7', accent2: '#ebbcba', green: '#9ccfd8', yellow: '#f6c177', red: '#eb6f92', cyan: '#9ccfd8', orange: '#ebbcba' },
	everforest: { mode: 'dark', bg: '#2d353b', deep: '#232a2e', surface: '#343f44', hl: '#3d484d', border: '#475258', fg: '#d3c6aa', muted: '#9da9a0', dim: '#7a8478', accent: '#a7c080', accent2: '#d699b6', green: '#a7c080', yellow: '#dbbc7f', red: '#e67e80', cyan: '#83c092', orange: '#e69875' },
	'catppuccin-latte': { mode: 'light', bg: '#eff1f5', deep: '#e6e9ef', surface: '#ccd0da', hl: '#dce0e8', border: '#bcc0cc', fg: '#4c4f69', muted: '#6c6f85', dim: '#9ca0b0', accent: '#1e66f5', accent2: '#8839ef', green: '#40a02b', yellow: '#df8e1d', red: '#d20f39', cyan: '#179299', orange: '#fe640b' },
	'rose-pine-dawn': { mode: 'light', bg: '#faf4ed', deep: '#f2e9e1', surface: '#fffaf3', hl: '#f4ede8', border: '#dfdad9', fg: '#575279', muted: '#797593', dim: '#9893a5', accent: '#286983', accent2: '#907aa9', green: '#56949f', yellow: '#ea9d34', red: '#b4637a', cyan: '#56949f', orange: '#d7827e' }
};

export const THEME_NAMES = Object.keys(THEMES);

export function rgba(hex, alpha) {
	const n = parseInt(hex.slice(1), 16);
	return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}
