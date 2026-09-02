import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  getPosts,
  getPost,
  getCategories,
  getTags,
  getPostsByCategory,
  getPostsByTag,
  type Post,
  type Category,
  type Tag,
  type PostsResponse,
} from '../lib/api';

// Mock fetch globally
const mockFetch = vi.fn();
globalThis.fetch = mockFetch;

const mockPost: Post = {
  id: 1,
  title: 'Test Post',
  slug: 'test-post',
  excerpt: 'Test excerpt',
  body: 'Test body content',
  status: 'published',
  published_at: '2024-01-01T00:00:00Z',
  cover_image: null,
  category: { name: 'Tech', slug: 'tech' },
  tags: [{ name: 'JavaScript', slug: 'javascript' }],
};

const mockCategory: Category = {
  id: 1,
  name: 'Tech',
  slug: 'tech',
};

const mockTag: Tag = {
  id: 1,
  name: 'JavaScript',
  slug: 'javascript',
};

const mockPostsResponse: PostsResponse = {
  data: [mockPost],
  meta: {
    current_page: 1,
    per_page: 10,
    total_entries: 1,
    total_pages: 1,
  },
};

describe('API Client', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getPosts', () => {
    it('should fetch posts with default pagination', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPostsResponse,
      } as Response);

      const result = await getPosts();

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts?page=1&per_page=10')
      );
      expect(result).toEqual(mockPostsResponse);
    });

    it('should fetch posts with custom pagination', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPostsResponse,
      } as Response);

      await getPosts(2, 20);

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts?page=2&per_page=20')
      );
    });

    it('should throw error on failed response', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
      } as Response);

      await expect(getPosts()).rejects.toThrow('API error: 500 Internal Server Error');
    });
  });

  describe('getPost', () => {
    it('should fetch a single post by slug', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPost,
      } as Response);

      const result = await getPost('test-post');

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts/test-post')
      );
      expect(result).toEqual(mockPost);
    });

    it('should throw error when post not found', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404,
        statusText: 'Not Found',
      } as Response);

      await expect(getPost('nonexistent')).rejects.toThrow('API error: 404 Not Found');
    });
  });

  describe('getCategories', () => {
    it('should fetch all categories', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => [mockCategory],
      } as Response);

      const result = await getCategories();

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/categories')
      );
      expect(result).toEqual([mockCategory]);
    });
  });

  describe('getTags', () => {
    it('should fetch all tags', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => [mockTag],
      } as Response);

      const result = await getTags();

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/tags')
      );
      expect(result).toEqual([mockTag]);
    });
  });

  describe('getPostsByCategory', () => {
    it('should fetch posts filtered by category', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPostsResponse,
      } as Response);

      const result = await getPostsByCategory(1);

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts?category_id=1&page=1')
      );
      expect(result).toEqual(mockPostsResponse);
    });

    it('should fetch posts by category with custom page', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPostsResponse,
      } as Response);

      await getPostsByCategory(1, 3);

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts?category_id=1&page=3')
      );
    });
  });

  describe('getPostsByTag', () => {
    it('should fetch posts filtered by tag', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPostsResponse,
      } as Response);

      const result = await getPostsByTag(1);

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts?tag_id=1&page=1')
      );
      expect(result).toEqual(mockPostsResponse);
    });

    it('should fetch posts by tag with custom page', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockPostsResponse,
      } as Response);

      await getPostsByTag(1, 2);

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/posts?tag_id=1&page=2')
      );
    });
  });

  describe('Pagination metadata', () => {
    it('should return pagination metadata with posts', async () => {
      const responseWithMeta: PostsResponse = {
        data: [mockPost, { ...mockPost, id: 2, slug: 'test-post-2' }],
        meta: {
          current_page: 2,
          per_page: 10,
          total_entries: 25,
          total_pages: 3,
        },
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => responseWithMeta,
      } as Response);

      const result = await getPosts(2);

      expect(result.meta.current_page).toBe(2);
      expect(result.meta.per_page).toBe(10);
      expect(result.meta.total_entries).toBe(25);
      expect(result.meta.total_pages).toBe(3);
      expect(result.data).toHaveLength(2);
    });
  });
});
