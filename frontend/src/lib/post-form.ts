/**
 * Shared form state and submit logic for the post create/edit pages.
 * Kept framework-agnostic so the logic is unit-testable without a DOM.
 */

export interface Tag {
  id: number;
  name: string;
  slug: string;
}

export interface PostFormData {
  title: string;
  slug: string;
  slugEdited: boolean;
  categoryId: string;
  tagIds: number[];
  coverImageSignedId: string | null;
  coverImageUrl: string | null;
  bodyHtml: string;
  excerpt: string;
  status: 'draft' | 'published';
  publishedAt: string;
}

export const EMPTY_FORM: PostFormData = {
  title: '',
  slug: '',
  slugEdited: false,
  categoryId: '',
  tagIds: [],
  coverImageSignedId: null,
  coverImageUrl: null,
  bodyHtml: '',
  excerpt: '',
  status: 'draft',
  publishedAt: '',
};

export interface PostPayload {
  post: {
    title: string;
    slug?: string;
    body: string;
    excerpt?: string;
    status: string;
    category_id?: number | null;
    tag_ids: number[];
    published_at?: string | null;
    cover_image_signed_id?: string | null;
    lock_version?: number;
  };
}

export function buildPayload(form: PostFormData, lockVersion?: number): PostPayload {
  const post: PostPayload['post'] = {
    title: form.title,
    body: form.bodyHtml,
    status: form.status,
    tag_ids: form.tagIds,
  };
  if (form.slug.trim()) post.slug = form.slug.trim();
  if (form.categoryId) post.category_id = Number(form.categoryId);
  if (form.excerpt.trim()) post.excerpt = form.excerpt.trim();
  if (form.status === 'published') {
    post.published_at = form.publishedAt || new Date().toISOString();
  }
  if (form.coverImageSignedId) {
    post.cover_image_signed_id = form.coverImageSignedId;
  }
  if (typeof lockVersion === 'number') post.lock_version = lockVersion;
  return { post };
}

export class ApiError extends Error {
  status: number;
  errors?: string[];

  constructor(status: number, errors?: string[], message?: string) {
    super(message || errors?.join(', ') || `API error ${status}`);
    this.status = status;
    this.errors = errors;
  }
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

export function createPost(payload: PostPayload): Promise<unknown> {
  return request('/api/v1/posts', 'POST', payload);
}

export function updatePost(slug: string, payload: PostPayload): Promise<unknown> {
  return request(`/api/v1/posts/${slug}`, 'PATCH', payload);
}

export function createTag(name: string): Promise<Tag> {
  return request<Tag>('/api/v1/tags', 'POST', { tag: { name } });
}
