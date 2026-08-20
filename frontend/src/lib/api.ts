const API_BASE = import.meta.env.API_URL || 'http://localhost:3000';

export interface Post {
  id: number;
  title: string;
  slug: string;
  excerpt: string | null;
  body?: string;
  status: string;
  published_at: string | null;
  category: { name: string; slug: string } | null;
  tags: { name: string; slug: string }[];
}

export interface Category {
  id: number;
  name: string;
  slug: string;
}

export interface Tag {
  id: number;
  name: string;
  slug: string;
}

async function fetchApi<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) {
    throw new Error(`API error: ${res.status} ${res.statusText}`);
  }
  return res.json() as Promise<T>;
}

export async function getPosts(): Promise<Post[]> {
  return fetchApi<Post[]>('/api/posts');
}

export async function getPost(slug: string): Promise<Post> {
  return fetchApi<Post>(`/api/posts/${slug}`);
}

export async function getCategories(): Promise<Category[]> {
  return fetchApi<Category[]>('/api/categories');
}

export async function getTags(): Promise<Tag[]> {
  return fetchApi<Tag[]>('/api/tags');
}
