export interface PaginationInfo {
  currentPage: number;
  totalPages: number;
  basePath: string;
}

export function shouldShowPagination(totalPages: number): boolean {
  return totalPages > 1;
}

export function shouldShowPrevious(currentPage: number): boolean {
  return currentPage > 1;
}

export function shouldShowNext(currentPage: number, totalPages: number): boolean {
  return currentPage < totalPages;
}

export function getPreviousPageUrl(basePath: string, currentPage: number): string {
  return `${basePath}?page=${currentPage - 1}`;
}

export function getNextPageUrl(basePath: string, currentPage: number): string {
  return `${basePath}?page=${currentPage + 1}`;
}

export function formatDate(dateString: string | null): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export function generateSlug(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}
