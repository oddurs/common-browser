import { cubicOut, quintOut } from 'svelte/easing';

const reduced = typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches;

// One motion vocabulary for the whole app: short fades, quick settles, nothing that waits on you.
export const FADE = 120;
export const MOVE = 200;
export const ms = (n) => (reduced ? 0 : n);
export const settle = quintOut;
export const ease = cubicOut;
