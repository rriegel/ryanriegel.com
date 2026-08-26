import { describe, it, expect } from 'vitest';
import {
  shouldShowPagination,
  shouldShowPrevious,
  shouldShowNext,
  getPreviousPageUrl,
  getNextPageUrl,
  formatDate,
  generateSlug,
} from './utils';

describe('Pagination Utilities', () => {
  describe('shouldShowPagination', () => {
    it('should return false when there is only 1 page', () => {
      expect(shouldShowPagination(1)).toBe(false);
    });

    it('should return true when there are multiple pages', () => {
      expect(shouldShowPagination(2)).toBe(true);
      expect(shouldShowPagination(5)).toBe(true);
    });
  });

  describe('shouldShowPrevious', () => {
    it('should return false on first page', () => {
      expect(shouldShowPrevious(1)).toBe(false);
    });

    it('should return true on subsequent pages', () => {
      expect(shouldShowPrevious(2)).toBe(true);
      expect(shouldShowPrevious(5)).toBe(true);
    });
  });

  describe('shouldShowNext', () => {
    it('should return false on last page', () => {
      expect(shouldShowNext(5, 5)).toBe(false);
    });

    it('should return true when not on last page', () => {
      expect(shouldShowNext(1, 5)).toBe(true);
      expect(shouldShowNext(3, 5)).toBe(true);
    });
  });

  describe('getPreviousPageUrl', () => {
    it('should generate correct URL for previous page', () => {
      expect(getPreviousPageUrl('/blog', 2)).toBe('/blog?page=1');
      expect(getPreviousPageUrl('/blog', 5)).toBe('/blog?page=4');
    });

    it('should work with category paths', () => {
      expect(getPreviousPageUrl('/blog/category/tech', 3)).toBe('/blog/category/tech?page=2');
    });
  });

  describe('getNextPageUrl', () => {
    it('should generate correct URL for next page', () => {
      expect(getNextPageUrl('/blog', 1)).toBe('/blog?page=2');
      expect(getNextPageUrl('/blog', 3)).toBe('/blog?page=4');
    });

    it('should work with tag paths', () => {
      expect(getNextPageUrl('/blog/tag/javascript', 2)).toBe('/blog/tag/javascript?page=3');
    });
  });
});

describe('Date Formatting', () => {
  it('should format a valid date string', () => {
    const result = formatDate('2024-06-15T12:00:00Z');
    expect(result).toContain('2024');
    expect(result).toMatch(/\d{1,2}/); // Contains a day number
    expect(result.length).toBeGreaterThan(0);
  });

  it('should return empty string for null', () => {
    expect(formatDate(null)).toBe('');
  });

  it('should handle different date formats', () => {
    const result = formatDate('2024-06-15');
    expect(result).toContain('2024');
    expect(result).toMatch(/June|Jun/);
  });

  it('should format dates with proper structure', () => {
    const result = formatDate('2024-06-15T12:00:00Z');
    // Should contain year
    expect(result).toContain('2024');
    // Should contain month name (June or Jul depending on timezone)
    expect(result).toMatch(/June|Jun|July/);
  });
});

describe('Slug Generation', () => {
  it('should convert text to lowercase slug', () => {
    expect(generateSlug('Hello World')).toBe('hello-world');
  });

  it('should replace special characters with hyphens', () => {
    expect(generateSlug('My First Post!')).toBe('my-first-post');
    expect(generateSlug('JavaScript & TypeScript')).toBe('javascript-typescript');
  });

  it('should remove leading and trailing hyphens', () => {
    expect(generateSlug('  Hello World  ')).toBe('hello-world');
    expect(generateSlug('--test--')).toBe('test');
  });

  it('should handle multiple spaces and special chars', () => {
    expect(generateSlug('This is a   test!!!')).toBe('this-is-a-test');
  });

  it('should preserve numbers', () => {
    expect(generateSlug('Post 123')).toBe('post-123');
    expect(generateSlug('2024 Review')).toBe('2024-review');
  });
});
