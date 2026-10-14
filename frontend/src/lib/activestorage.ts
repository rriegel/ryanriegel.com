import { DirectUpload } from '@rails/activestorage';

// All URLs here run IN THE BROWSER and go through the Astro dev proxy
// (see vite.server.proxy in astro.config.mjs) as same-origin relative
// requests. Absolute http://localhost:3000 URLs break for any browsing
// origin other than localhost:4321 (LAN/Tailscale/prod) — the browser
// would resolve `localhost` to the viewer's own machine.

export interface DirectUploadResult {
  /** Signed ID — pass as cover_image_signed_id when saving the post. */
  signedId: string;
  /** Public URL for immediate preview / editor insertion. */
  url: string;
}

/**
 * Upload a file straight to Rails ActiveStorage via the direct-upload endpoint.
 *
 * Flow (matches the plan in vault/Projects/ryanriegel-com-admin-panel.md):
 *  1. POST /rails/active_storage/direct_uploads  → blob URL
 *  2. PUT the file bytes to that URL
 *  3. Blob is created server-side; signed_id + URL come back from our
 *     /api/v1/uploads/create_blob convenience wrapper.
 */
export function uploadToActiveStorage(file: File): Promise<DirectUploadResult> {
  return new Promise((resolve, reject) => {
    // Step 1+2: DirectUpload handles the two-step direct upload protocol.
    const uploader = new DirectUpload(
      file,
      '/rails/active_storage/direct_uploads'
    );

    uploader.create((error, blob) => {
      if (error) {
        reject(new Error(error.message || 'Upload failed'));
        return;
      }
      if (!blob) {
        reject(new Error('Upload failed: no blob returned'));
        return;
      }

      // Step 3: ask Rails for the signed_id and a usable URL for the blob.
      fetch('/api/v1/uploads/create_blob', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ blob_id: blob.id ?? blob.signed_id ?? blob }),
      })
        .then(async (res) => {
          if (!res.ok) {
            const text = await res.text().catch(() => '');
            reject(
              new Error(`Blob registration failed (${res.status}): ${text.slice(0, 200)}`)
            );
            return;
          }
          const data = (await res.json()) as {
            signed_id: string;
            url: string;
          };
          resolve({ signedId: data.signed_id, url: data.url });
        })
        .catch((err: unknown) => {
          reject(
            err instanceof Error
              ? err
              : new Error('Blob registration failed: network error')
          );
        });
    });
  });
}
