
import 'dotenv/config';
import http from 'node:http';
import path from 'node:path';
import { readFile } from 'node:fs/promises';
import { handleNativeApiRequest } from './router.ts';

const port = Number(process.env.PORT || 3001);
const host = process.env.HOST || '0.0.0.0';

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error(`Invalid PORT value: ${process.env.PORT}`);
}

// React production build directory
const frontendDir = path.resolve(process.cwd(), 'frontend/dist');

const mimeTypes: Record<string, string> = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

async function serveFrontend(
  req: http.IncomingMessage,
  res: http.ServerResponse
) {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405);
    res.end();
    return;
  }

  const pathname = new URL(req.url || '/', 'http://localhost').pathname;
  const requestedPath = decodeURIComponent(pathname);

  let filePath = path.resolve(frontendDir, `.${requestedPath}`);

  // Prevent directory traversal
  if (
    filePath !== frontendDir &&
    !filePath.startsWith(frontendDir + path.sep)
  ) {
    res.writeHead(403);
    res.end();
    return;
  }

  try {
    const content = await readFile(filePath);
    const extension = path.extname(filePath);

    res.writeHead(200, {
      'Content-Type': mimeTypes[extension] || 'application/octet-stream',
    });

    res.end(req.method === 'HEAD' ? undefined : content);
  } catch {
    // Return 404 for missing static assets
    // but allow React Router to handle frontend routes
    if (path.extname(requestedPath)) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }

    try {
      const indexHtml = await readFile(
        path.join(frontendDir, 'index.html')
      );

      res.writeHead(200, {
        'Content-Type': 'text/html',
      });

      res.end(req.method === 'HEAD' ? undefined : indexHtml);
    } catch {
      res.writeHead(500);
      res.end('Frontend build not found');
    }
  }
}

const server = http.createServer(async (req, res) => {
  try {
    const isHandled = await handleNativeApiRequest(req, res);

    if (!isHandled) {
      await serveFrontend(req, res);
    }
  } catch (err) {
    console.error('Unhandled server error:', err);

    if (!res.headersSent) {
      res.writeHead(500, {
        'Content-Type': 'application/json',
      });

      res.end(
        JSON.stringify({
          success: false,
          error: 'Internal server error',
        })
      );
    }
  }
});

server.listen(port, host, () => {
  console.log(`MediCart running on http://${host}:${port}`);
});
