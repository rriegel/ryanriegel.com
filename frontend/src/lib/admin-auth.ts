import type { APIContext } from 'astro';

const API_BASE = import.meta.env.API_URL || 'http://localhost:3000';

/**
 * Check if the user has an auth cookie.
 */
export function hasAuthCookie(context: APIContext): boolean {
  return !!context.cookies.get('auth_token')?.value;
}

/**
 * Get the auth token from the cookie.
 */
export function getAuthToken(context: APIContext): string | undefined {
  return context.cookies.get('auth_token')?.value;
}

/**
 * Validate the auth token by making a server-side API call.
 * Returns true if the token is valid, false otherwise.
 */
export async function validateToken(token: string): Promise<boolean> {
  try {
    const res = await fetch(`${API_BASE}/api/v1/posts?per_page=1`, {
      headers: {
        Cookie: `auth_token=${token}`,
      },
    });
    return res.status !== 401;
  } catch {
    // API unreachable — assume valid, let client-side handle errors
    return true;
  }
}

/**
 * Clear the auth cookie (used on logout).
 */
export function clearAuthCookie(context: APIContext): void {
  context.cookies.delete('auth_token', { path: '/' });
}
