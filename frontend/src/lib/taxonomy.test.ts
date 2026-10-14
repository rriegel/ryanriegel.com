import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  fetchTaxonomy,
  createCategory,
  updateCategory,
  deleteCategory,
  createTag,
  updateTag,
  deleteTag,
  type TaxonomyItem,
} from './taxonomy';
import { ApiError } from './post-form';

const mockFetch = vi.fn();
globalThis.fetch = mockFetch;

const item: TaxonomyItem = { id: 1, name: 'Tech', slug: 'tech', posts_count: 3 };

describe('taxonomy lib', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('fetchTaxonomy', () => {
    it('fetches categories from the categories endpoint', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => [item],
      } as Response);

      const result = await fetchTaxonomy('categories');

      expect(fetch).toHaveBeenCalledWith('/api/v1/categories', { credentials: 'include' });
      expect(result).toEqual([item]);
    });

    it('fetches tags from the tags endpoint', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => [item],
      } as Response);

      const result = await fetchTaxonomy('tags');

      expect(fetch).toHaveBeenCalledWith('/api/v1/tags', { credentials: 'include' });
      expect(result).toEqual([item]);
    });

    it('throws ApiError on failed response', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
      } as Response);

      await expect(fetchTaxonomy('categories')).rejects.toThrow(ApiError);
    });
  });

  describe('createCategory', () => {
    it('posts to /api/v1/categories with the name', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => item,
      } as Response);

      const result = await createCategory('Tech');

      expect(fetch).toHaveBeenCalledWith('/api/v1/categories', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ category: { name: 'Tech' } }),
      });
      expect(result).toEqual(item);
    });

    it('surfaces validation errors via ApiError', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 422,
        json: async () => ({ errors: ['Name has already been taken'] }),
      } as Response);

      const err = await createCategory('Tech').catch((e) => e);
      expect(err).toBeInstanceOf(ApiError);
      expect(err.errors).toEqual(['Name has already been taken']);
    });
  });

  describe('updateCategory', () => {
    it('patches the category by slug with the new name', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ...item, name: 'Technology', slug: 'technology' }),
      } as Response);

      const result = await updateCategory('tech', 'Technology');

      expect(fetch).toHaveBeenCalledWith('/api/v1/categories/tech', {
        method: 'PATCH',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ category: { name: 'Technology' } }),
      });
      expect(result.name).toBe('Technology');
      expect(result.slug).toBe('technology');
    });

    it('encodes slugs with special characters', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => item,
      } as Response);

      await updateCategory('web dev', 'Web Dev');

      expect(fetch).toHaveBeenCalledWith('/api/v1/categories/web%20dev', expect.anything());
    });
  });

  describe('deleteCategory', () => {
    it('sends DELETE to the category slug URL', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({}),
      } as Response);

      await deleteCategory('tech');

      expect(fetch).toHaveBeenCalledWith('/api/v1/categories/tech', {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: undefined,
      });
    });
  });

  describe('tag CRUD mirror the category functions', () => {
    it('createTag posts to /api/v1/tags', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => item,
      } as Response);

      await createTag('ruby');

      expect(fetch).toHaveBeenCalledWith('/api/v1/tags', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tag: { name: 'ruby' } }),
      });
    });

    it('updateTag patches /api/v1/tags/:slug', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => item,
      } as Response);

      await updateTag('ruby', 'Ruby');

      expect(fetch).toHaveBeenCalledWith('/api/v1/tags/ruby', {
        method: 'PATCH',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tag: { name: 'Ruby' } }),
      });
    });

    it('deleteTag sends DELETE to /api/v1/tags/:slug', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({}),
      } as Response);

      await deleteTag('ruby');

      expect(fetch).toHaveBeenCalledWith('/api/v1/tags/ruby', {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: undefined,
      });
    });
  });
});
