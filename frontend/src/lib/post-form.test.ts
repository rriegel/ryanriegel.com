import { describe, it, expect } from 'vitest';
import {
  EMPTY_FORM,
  buildPayload,
  ApiError,
  type PostFormData,
} from '../lib/post-form';

function baseForm(overrides: Partial<PostFormData> = {}): PostFormData {
  return { ...EMPTY_FORM, ...overrides };
}

describe('buildPayload', () => {
  it('includes required fields for a minimal draft', () => {
    const payload = buildPayload(
      baseForm({ title: 'Hello', bodyHtml: '<p>World</p>' })
    );
    expect(payload.post).toMatchObject({
      title: 'Hello',
      body: '<p>World</p>',
      status: 'draft',
      tag_ids: [],
    });
    expect(payload.post.published_at).toBeUndefined();
    expect(payload.post.slug).toBeUndefined();
    expect(payload.post.category_id).toBeUndefined();
    expect(payload.post.excerpt).toBeUndefined();
    expect(payload.post.cover_image_signed_id).toBeUndefined();
  });

  it('sets published_at when publishing without an explicit date', () => {
    const before = Date.now();
    const payload = buildPayload(
      baseForm({ title: 'T', bodyHtml: 'B', status: 'published' })
    );
    const ts = new Date(payload.post.published_at as string).getTime();
    expect(ts).toBeGreaterThanOrEqual(before);
    expect(ts).toBeLessThanOrEqual(Date.now());
  });

  it('passes through slug, category, excerpt, and tags when present', () => {
    const payload = buildPayload(
      baseForm({
        title: 'T',
        bodyHtml: 'B',
        slug: 'my-slug',
        categoryId: '3',
        excerpt: '  An excerpt  ',
        tagIds: [1, 2, 3],
      })
    );
    expect(payload.post).toMatchObject({
      slug: 'my-slug',
      category_id: 3,
      excerpt: 'An excerpt',
      tag_ids: [1, 2, 3],
    });
  });

  it('does not set published_at for drafts even with a date in the form', () => {
    const payload = buildPayload(
      baseForm({ title: 'T', bodyHtml: 'B', publishedAt: '2026-01-01T00:00:00Z' })
    );
    expect(payload.post.published_at).toBeUndefined();
  });

  it('includes cover_image_signed_id only when a new upload exists', () => {
    const withCover = buildPayload(
      baseForm({
        title: 'T',
        bodyHtml: 'B',
        coverImageSignedId: 'abc123',
      })
    );
    expect(withCover.post.cover_image_signed_id).toBe('abc123');

    // Existing cover preview without a fresh upload → no signed_id param
    const existingCoverOnly = buildPayload(
      baseForm({
        title: 'T',
        bodyHtml: 'B',
        coverImageSignedId: null,
        coverImageUrl: 'http://x/y.jpg',
      })
    );
    expect(existingCoverOnly.post.cover_image_signed_id).toBeUndefined();
  });

  it('includes lock_version when provided (optimistic locking)', () => {
    const payload = buildPayload(baseForm({ title: 'T', bodyHtml: 'B' }), 4);
    expect(payload.post.lock_version).toBe(4);
  });

  it('omits lock_version for new posts', () => {
    const payload = buildPayload(baseForm({ title: 'T', bodyHtml: 'B' }));
    expect(payload.post.lock_version).toBeUndefined();
  });
});

describe('ApiError', () => {
  it('joins error arrays from Rails unprocessable_entity responses', () => {
    const err = new ApiError(422, ['Title can\'t be blank', 'Body can\'t be blank']);
    expect(err.status).toBe(422);
    expect(err.message).toBe("Title can't be blank, Body can't be blank");
    expect(err.errors).toHaveLength(2);
  });

  it('prefers the single error message (401/404/409 style responses)', () => {
    const err = new ApiError(409, undefined, 'This post has been modified');
    expect(err.status).toBe(409);
    expect(err.message).toBe('This post has been modified');
  });

  it('falls back to a generic message', () => {
    const err = new ApiError(500);
    expect(err.message).toBe('API error 500');
  });
});
