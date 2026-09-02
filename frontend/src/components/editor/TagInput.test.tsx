import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, cleanup } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createElement } from 'react';
import TagInput from './TagInput';

// jsdom lacks scrollTo and other layout APIs TipTap doesn't need here;
// TagInput is plain React so no special setup required.

const TAGS = [
  { id: 1, name: 'ruby', slug: 'ruby' },
  { id: 2, name: 'rails', slug: 'rails' },
  { id: 3, name: 'running', slug: 'running' },
];

function renderInput(overrides: Partial<Parameters<typeof TagInput>[0]> = {}) {
  const props = {
    available: TAGS,
    selected: [] as number[],
    onChange: vi.fn(),
    onCreate: vi.fn(),
    ...overrides,
  };
  const utils = render(createElement(TagInput, props));
  return { ...utils, props };
}

describe('TagInput', () => {
  beforeEach(() => {
    cleanup();
  });

  it('renders the search box', () => {
    renderInput();
    expect(screen.getByLabelText('Tag search')).toBeInTheDocument();
  });

  it('shows existing selected tags as chips with remove buttons', () => {
    renderInput({ selected: [1, 3] });
    expect(screen.getByText('ruby')).toBeInTheDocument();
    expect(screen.getByText('running')).toBeInTheDocument();
    expect(screen.getByLabelText('Remove tag ruby')).toBeInTheDocument();
  });

  it('filters options as the user types', async () => {
    const user = userEvent.setup();
    renderInput();
    const input = screen.getByLabelText('Tag search');
    await user.type(input, 'ru');
    const dropdown = await screen.findByRole('listbox');
    expect(dropdown.textContent).toContain('ruby');
    expect(dropdown.textContent).toContain('running');
    expect(dropdown.textContent).not.toContain('rails');
  });

  it('clicking an option calls onChange with the id appended', async () => {
    const user = userEvent.setup();
    const { props } = renderInput();
    const input = screen.getByLabelText('Tag search');
    await user.type(input, 'rails');
    await user.click(await screen.findByRole('button', { name: 'rails' }));
    expect(props.onChange).toHaveBeenCalledWith([2]);
  });

  it('offers to create a tag when no exact match exists', async () => {
    const user = userEvent.setup();
    const onCreate = vi.fn().mockResolvedValue({ id: 9, name: 'astro', slug: 'astro' });
    const { props } = renderInput({ onCreate });
    const input = screen.getByLabelText('Tag search');
    await user.type(input, 'astro');
    const createBtn = await screen.findByRole('button', { name: /Create “astro”/ });
    expect(createBtn).toBeInTheDocument();

    await user.click(createBtn);
    await waitFor(() => expect(props.onCreate).toHaveBeenCalledWith('astro'));
    await waitFor(() => expect(props.onChange).toHaveBeenCalledWith([9]));
  });

  it('does not offer creation when the query exactly matches an existing tag', async () => {
    const user = userEvent.setup();
    renderInput();
    const input = screen.getByLabelText('Tag search');
    await user.type(input, 'ruby');
    const dropdown = await screen.findByRole('listbox');
    expect(dropdown.textContent).not.toContain('Create');
  });

  it('removes a selected tag via its chip button', async () => {
    const user = userEvent.setup();
    const { props } = renderInput({ selected: [1, 2] });
    await user.click(screen.getByLabelText('Remove tag ruby'));
    expect(props.onChange).toHaveBeenCalledWith([2]);
  });

  it('shows an error if tag creation fails', async () => {
    const user = userEvent.setup();
    const onCreate = vi.fn().mockRejectedValue(new Error('boom'));
    renderInput({ onCreate });
    const input = screen.getByLabelText('Tag search');
    await user.type(input, 'newtag');
    await user.click(await screen.findByRole('button', { name: /Create “newtag”/ }));
    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Failed to create tag'
    );
  });
});
