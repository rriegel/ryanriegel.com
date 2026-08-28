const API_BASE = import.meta.env.API_URL || 'http://localhost:3000';

export interface Post {
  id: number;
  title: string;
  slug: string;
  excerpt: string | null;
  body?: string;
  status: string;
  published_at: string | null;
  cover_image: string | null;
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

export interface PaginationMeta {
  current_page: number;
  per_page: number;
  total_entries: number;
  total_pages: number;
}

export interface PostsResponse {
  data: Post[];
  meta: PaginationMeta;
}

async function fetchApi<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) {
    throw new Error(`API error: ${res.status} ${res.statusText}`);
  }
  return res.json() as Promise<T>;
}

export async function getPosts(page: number = 1, perPage: number = 10): Promise<PostsResponse> {
  return fetchApi<PostsResponse>(`/api/v1/posts?page=${page}&per_page=${perPage}`);
}

export async function getPostsByCategory(categoryId: number, page: number = 1): Promise<PostsResponse> {
  return fetchApi<PostsResponse>(`/api/v1/posts?category_id=${categoryId}&page=${page}`);
}

export async function getPostsByTag(tagId: number, page: number = 1): Promise<PostsResponse> {
  return fetchApi<PostsResponse>(`/api/v1/posts?tag_id=${tagId}&page=${page}`);
}

export async function getPost(slug: string): Promise<Post> {
  return fetchApi<Post>(`/api/v1/posts/${slug}`);
}

export async function getCategories(): Promise<Category[]> {
  return fetchApi<Category[]>('/api/v1/categories');
}

export async function getTags(): Promise<Tag[]> {
  return fetchApi<Tag[]>('/api/v1/tags');
}
