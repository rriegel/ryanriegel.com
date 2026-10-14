/**
 * Admin taxonomy CRUD (categories & tags) — shared by the /admin/categories
 * and /admin/tags pages. Framework-agnostic and unit-testable, mirroring
 * post-form.ts conventions: same-origin relative paths (requests ride the
 * Astro proxy), cookie auth, and ApiError with the API's error array.
 */

import { ApiError } from './post-form';

export interface TaxonomyItem {
  id: number;
  name: string;
  slug: string;
  posts_count: number;
}

async function request<T>(path: string, method: string, body?: unknown): Promise<T> {
  const res = await fetch(path, {
    method,
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const errors = Array.isArray((data as { errors?: string[] }).errors)
      ? (data as { errors: string[] }).errors
      : undefined;
    const single = (data as { error?: string }).error;
    throw new ApiError(res.status, errors, single);
  }
  return data as T;
}

export async function fetchTaxonomy(kind: 'categories' | 'tags'): Promise<TaxonomyItem[]> {
  const res = await fetch(`/api/v1/${kind}`, { credentials: 'include' });
  if (!res.ok) {
    throw new ApiError(res.status, undefined, `Failed to load ${kind} (${res.status})`);
  }
  return (await res.json()) as TaxonomyItem[];
}

export function createCategory(name: string): Promise<TaxonomyItem> {
  return request<TaxonomyItem>('/api/v1/categories', 'POST', { category: { name } });
}

export function updateCategory(slug: string, name: string): Promise<TaxonomyItem> {
  return request<TaxonomyItem>(`/api/v1/categories/${encodeURIComponent(slug)}`, 'PATCH', {
    category: { name },
  });
}

export function deleteCategory(slug: string): Promise<void> {
  return request<void>(`/api/v1/categories/${encodeURIComponent(slug)}`, 'DELETE');
}

export function createTag(name: string): Promise<TaxonomyItem> {
  return request<TaxonomyItem>('/api/v1/tags', 'POST', { tag: { name } });
}

export function updateTag(slug: string, name: string): Promise<TaxonomyItem> {
  return request<TaxonomyItem>(`/api/v1/tags/${encodeURIComponent(slug)}`, 'PATCH', {
    tag: { name },
  });
}

export function deleteTag(slug: string): Promise<void> {
  return request<void>(`/api/v1/tags/${encodeURIComponent(slug)}`, 'DELETE');
}
