import net from 'node:net';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

// 5317 avoids the default 5173, which the fake "localhost:5173" page pretends to be.
const PORT = 5317;

// The server binds IPv4 loopback only, but browsers often resolve `localhost` to ::1 first and
// fail there. Relay ::1 to 127.0.0.1 so http://localhost:5317 and http://127.0.0.1:5317 both work,
// without opening the server to the network the way binding every interface would.
function ipv6Loopback() {
	let relay;
	const start = () => {
		relay = net.createServer((client) => {
			const upstream = net.connect(PORT, '127.0.0.1');
			client.pipe(upstream).pipe(client);
			client.on('error', () => upstream.destroy());
			upstream.on('error', () => client.destroy());
		});
		relay.on('error', (err) => console.warn(`[ipv6-loopback] http://localhost:${PORT} over IPv6 unavailable: ${err.message}`));
		relay.listen(PORT, '::1');
	};
	return {
		name: 'ipv6-loopback',
		configureServer(server) {
			start();
			server.httpServer?.on('close', () => relay?.close());
		},
		configurePreviewServer(server) {
			start();
			server.httpServer?.on('close', () => relay?.close());
		}
	};
}

export default defineConfig({
	plugins: [sveltekit(), ipv6Loopback()],
	server: { host: '127.0.0.1', port: PORT, strictPort: true },
	preview: { host: '127.0.0.1', port: PORT, strictPort: true }
});
