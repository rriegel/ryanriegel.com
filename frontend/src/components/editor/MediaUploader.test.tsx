import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, cleanup } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createElement } from 'react';
import MediaUploader from './MediaUploader';

function renderUploader(overrides: Partial<Parameters<typeof MediaUploader>[0]> = {}) {
  const props = {
    value: null as string | null,
    previewUrl: null as string | null,
    onChange: vi.fn(),
    ...overrides,
  };
  const utils = render(createElement(MediaUploader, props));
  return { ...utils, props };
}

describe('MediaUploader', () => {
  beforeEach(() => {
    cleanup();
  });

  it('shows the dropzone when there is no cover image', () => {
    renderUploader();
    expect(screen.getByText(/Drag & drop a cover image/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Choose file' })).toBeInTheDocument();
  });

  it('shows the preview with Replace and Remove when a cover exists', () => {
    renderUploader({
      previewUrl: 'http://localhost:3000/rails/active_storage/blobs/x/cover.jpg',
      value: 'signed123',
    });
    expect(screen.getByAltText('Cover image preview')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Replace' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Remove' })).toBeInTheDocument();
  });

  it('Remove clears the cover', async () => {
    const user = userEvent.setup();
    const { props } = renderUploader({
      previewUrl: 'http://x/cover.jpg',
      value: 'signed123',
    });
    await user.click(screen.getByRole('button', { name: 'Remove' }));
    expect(props.onChange).toHaveBeenCalledWith(null, null);
  });

  it('rejects non-image files with a visible error', async () => {
    const user = userEvent.setup();
    const { props } = renderUploader();
    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    const file = new File(['pdf'], 'doc.pdf', { type: 'application/pdf' });

    Object.defineProperty(input, 'files', { value: [file] });
    input.dispatchEvent(new Event('change', { bubbles: true }));

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Cover image must be an image'
    );
    expect(props.onChange).not.toHaveBeenCalled();
  });

  it('rejects files over 10 MB', async () => {
    renderUploader();
    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    const big = new File(['x'], 'huge.png', { type: 'image/png' });
    Object.defineProperty(big, 'size', { value: 11 * 1024 * 1024 });

    Object.defineProperty(input, 'files', { value: [big] });
    input.dispatchEvent(new Event('change', { bubbles: true }));

    expect(await screen.findByRole('alert')).toHaveTextContent('File too large');
  });
});
