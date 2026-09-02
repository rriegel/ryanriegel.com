import { useState, useRef, useCallback } from 'react';
import { uploadToActiveStorage } from '../../lib/activestorage';

interface MediaUploaderProps {
  /** Signed ID of the currently attached cover image (null = none). */
  value: string | null;
  /** Public URL of the currently attached cover image (for preview). */
  previewUrl: string | null;
  onChange: (signedId: string | null, previewUrl: string | null) => void;
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function MediaUploader({ value, previewUrl, onChange }: MediaUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [dragActive, setDragActive] = useState(false);

  const handleFile = useCallback(
    (file: File) => {
      setError(null);
      if (!file.type.startsWith('image/')) {
        setError('Cover image must be an image (jpg, png, webp).');
        return;
      }
      if (file.size > 10 * 1024 * 1024) {
        setError(`File too large (${formatBytes(file.size)}). Maximum is 10 MB.`);
        return;
      }

      setUploading(true);
      setProgress(10);
      uploadToActiveStorage(file)
        .then(({ signedId, url }) => {
          setProgress(100);
          onChange(signedId, url);
        })
        .catch((err: unknown) => {
          console.error('[UPLOADER] cover upload failed', err);
          setError(err instanceof Error ? err.message : 'Upload failed. Please try again.');
        })
        .finally(() => {
          setUploading(false);
          setProgress(0);
        });
    },
    [onChange]
  );

  return (
    <div className="media-uploader">
      {previewUrl ? (
        <div className="cover-preview">
          <img src={previewUrl} alt="Cover image preview" />
          <div className="cover-preview-actions">
            <button
              type="button"
              className="btn-secondary"
              onClick={() => inputRef.current?.click()}
              disabled={uploading}
            >
              Replace
            </button>
            <button
              type="button"
              className="btn-danger"
              onClick={() => onChange(null, null)}
              disabled={uploading}
            >
              Remove
            </button>
          </div>
        </div>
      ) : (
        <div
          className={`dropzone${dragActive ? ' dropzone-active' : ''}`}
          onDragOver={(e) => {
            e.preventDefault();
            setDragActive(true);
          }}
          onDragLeave={() => setDragActive(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragActive(false);
            const file = e.dataTransfer.files?.[0];
            if (file) handleFile(file);
          }}
        >
          <p>Drag &amp; drop a cover image here</p>
          <button
            type="button"
            className="btn-secondary"
            onClick={() => inputRef.current?.click()}
            disabled={uploading}
          >
            {uploading ? `Uploading… ${progress}%` : 'Choose file'}
          </button>
          <p className="dropzone-hint">JPG, PNG, or WebP · max 10 MB</p>
        </div>
      )}

      {error && (
        <div className="uploader-error" role="alert">
          {error}
        </div>
      )}

      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        hidden
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) handleFile(file);
          e.target.value = '';
        }}
      />

      {/* Hidden field persists the current signed_id across form submits */}
      <input type="hidden" name="cover_image_signed_id" value={value ?? ''} />
    </div>
  );
}
