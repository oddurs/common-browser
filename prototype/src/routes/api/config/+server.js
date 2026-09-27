import { current, subscribe } from '$lib/server/config.js';

// Server-sent events: the current config on connect, then one event per saved change.
export function GET({ request }) {
	const encoder = new TextEncoder();
	let closed = false;
	let unsubscribe = () => {};
	let heartbeat;

	// A disconnect can arrive as both a stream cancel and a request abort; clean up once.
	const stop = (controller) => {
		if (closed) return;
		closed = true;
		unsubscribe();
		clearInterval(heartbeat);
		controller?.close();
	};

	const stream = new ReadableStream({
		start(controller) {
			const write = (text) => {
				if (!closed) controller.enqueue(encoder.encode(text));
			};
			const send = (event) => write(`data: ${JSON.stringify(event)}\n\n`);
			send({ kind: 'initial', ...current() });
			unsubscribe = subscribe(send);
			heartbeat = setInterval(() => write(': keep-alive\n\n'), 25000);
			request.signal.addEventListener('abort', () => stop(controller));
		},
		cancel() {
			stop(null);
		}
	});

	return new Response(stream, {
		headers: { 'content-type': 'text/event-stream', 'cache-control': 'no-cache', connection: 'keep-alive' }
	});
}
