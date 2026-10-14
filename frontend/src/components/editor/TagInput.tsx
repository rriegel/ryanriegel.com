import { useState, useRef, useCallback } from 'react';

interface Tag {
  id: number;
  name: string;
  slug: string;
}

interface TagInputProps {
  /** All tags available on the site (fetched from /api/v1/tags). */
  available: Tag[];
  /** IDs currently selected on this post. */
  selected: number[];
  onChange: (ids: number[]) => void;
  /** Create a new tag via POST /api/v1/tags. Must return the created Tag. */
  onCreate: (name: string) => Promise<Tag>;
}

export default function TagInput({ available, selected, onChange, onCreate }: TagInputProps) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const blurTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const selectedTags = selected
    .map((id) => available.find((t) => t.id === id))
    .filter((t): t is Tag => !!t);

  const matches = available.filter(
    (t) =>
      !selected.includes(t.id) &&
      t.name.toLowerCase().includes(query.trim().toLowerCase())
  );
  const exactMatch = available.some(
    (t) => t.name.toLowerCase() === query.trim().toLowerCase()
  );
  const canCreate = query.trim().length > 0 && !exactMatch;

  const toggle = useCallback(
    (id: number) => {
      if (selected.includes(id)) {
        onChange(selected.filter((s) => s !== id));
      } else {
        onChange([...selected, id]);
      }
      setQuery('');
    },
    [selected, onChange]
  );

  const handleCreate = useCallback(async () => {
    const name = query.trim();
    if (!name || creating) return;
    setCreating(true);
    setError(null);
    try {
      const tag = await onCreate(name);
      onChange([...selected, tag.id]);
      setQuery('');
      setOpen(false);
    } catch (err) {
      console.error('[TAGS] create failed', err);
      setError('Failed to create tag. Please try again.');
    } finally {
      setCreating(false);
    }
  }, [query, creating, onCreate, selected, onChange]);

  return (
    <div className="tag-input">
      {selectedTags.length > 0 && (
        <div className="tag-chips">
          {selectedTags.map((tag) => (
            <span key={tag.id} className="tag-chip">
              {tag.name}
              <button
                type="button"
                className="tag-chip-remove"
                aria-label={`Remove tag ${tag.name}`}
                onClick={() => toggle(tag.id)}
              >
                ×
              </button>
            </span>
          ))}
        </div>
      )}

      <div className="tag-dropdown-wrap">
        <input
          type="text"
          className="tag-search"
          placeholder={selectedTags.length ? 'Add another tag…' : 'Search or create tags…'}
          value={query}
          aria-label="Tag search"
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => {
            if (blurTimer.current) {
              clearTimeout(blurTimer.current);
              blurTimer.current = null;
            }
            setOpen(true);
          }}
          onBlur={() => {
            // Delay so option clicks register before the dropdown closes
            blurTimer.current = setTimeout(() => setOpen(false), 150);
          }}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              if (matches.length > 0 && query.trim()) {
                toggle(matches[0].id);
              } else if (canCreate) {
                void handleCreate();
              }
            }
          }}
        />

        {open && (
          <div className="tag-dropdown" role="listbox" aria-label="Tag options">
            {matches.map((tag) => (
              <button
                key={tag.id}
                type="button"
                className="tag-option"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => toggle(tag.id)}
              >
                {tag.name}
              </button>
            ))}
            {matches.length === 0 && !canCreate && (
              <div className="tag-option-empty">No tags found</div>
            )}
            {canCreate && (
              <button
                type="button"
                className="tag-option tag-option-create"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => void handleCreate()}
                disabled={creating}
              >
                {creating ? 'Creating…' : `Create “${query.trim()}”`}
              </button>
            )}
          </div>
        )}
      </div>

      {error && (
        <div className="uploader-error" role="alert">
          {error}
        </div>
      )}
    </div>
  );
}
