import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';
import Link from '@tiptap/extension-link';
import Placeholder from '@tiptap/extension-placeholder';
import { useCallback, useEffect, useRef, useState } from 'react';
import { uploadToActiveStorage } from '../../lib/activestorage';

const API_BASE = import.meta.env.API_URL || 'http://localhost:3000';

interface PostEditorProps {
  initialContent?: string;
  onChange?: (html: string) => void;
}

interface ToolbarProps {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor: any;
  onInsertUpload: (file: File) => void;
  uploading: boolean;
}

function Toolbar({ editor, onInsertUpload, uploading }: ToolbarProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  if (!editor) return null;

  const btn = (active: boolean) =>
    `toolbar-btn${active ? ' toolbar-btn-active' : ''}`;

  return (
    <div className="editor-toolbar" role="toolbar" aria-label="Formatting">
      <button
        type="button"
        className={btn(editor.isActive('bold'))}
        onClick={() => editor.chain().focus().toggleBold().run()}
        disabled={!editor.can().toggleBold()}
        aria-label="Bold"
        title="Bold"
      >
        B
      </button>
      <button
        type="button"
        className={btn(editor.isActive('italic'))}
        onClick={() => editor.chain().focus().toggleItalic().run()}
        disabled={!editor.can().toggleItalic()}
        aria-label="Italic"
        title="Italic"
      >
        I
      </button>
      <button
        type="button"
        className={btn(editor.isActive('strike'))}
        onClick={() => editor.chain().focus().toggleStrike().run()}
        disabled={!editor.can().toggleStrike()}
        aria-label="Strikethrough"
        title="Strikethrough"
      >
        S
      </button>
      <span className="toolbar-sep" />
      <button
        type="button"
        className={btn(editor.isActive('heading', { level: 2 }))}
        onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        aria-label="Heading 2"
        title="Heading 2"
      >
        H2
      </button>
      <button
        type="button"
        className={btn(editor.isActive('heading', { level: 3 }))}
        onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
        aria-label="Heading 3"
        title="Heading 3"
      >
        H3
      </button>
      <span className="toolbar-sep" />
      <button
        type="button"
        className={btn(editor.isActive('bulletList'))}
        onClick={() => editor.chain().focus().toggleBulletList().run()}
        aria-label="Bullet list"
        title="Bullet list"
      >
        • List
      </button>
      <button
        type="button"
        className={btn(editor.isActive('orderedList'))}
        onClick={() => editor.chain().focus().toggleOrderedList().run()}
        aria-label="Numbered list"
        title="Numbered list"
      >
        1. List
      </button>
      <span className="toolbar-sep" />
      <button
        type="button"
        className={btn(editor.isActive('blockquote'))}
        onClick={() => editor.chain().focus().toggleBlockquote().run()}
        aria-label="Blockquote"
        title="Blockquote"
      >
        &ldquo;&rdquo;
      </button>
      <button
        type="button"
        className={btn(editor.isActive('codeBlock'))}
        onClick={() => editor.chain().focus().toggleCodeBlock().run()}
        aria-label="Code block"
        title="Code block"
      >
        {'</>'}
      </button>
      <span className="toolbar-sep" />
      <button
        type="button"
        className={btn(editor.isActive('link'))}
        onClick={() => {
          const previous = editor.getAttributes('link').href as string | undefined;
          const url = window.prompt('URL', previous ?? 'https://');
          if (url === null) return;
          if (url === '') {
            editor.chain().focus().extendMarkRange('link').unsetLink().run();
            return;
          }
          editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
        }}
        aria-label="Insert link"
        title="Insert link"
      >
        Link
      </button>
      <button
        type="button"
        className={btn(editor.isActive('link'))}
        onClick={() => editor.chain().focus().unsetLink().run()}
        disabled={!editor.isActive('link')}
        aria-label="Remove link"
        title="Remove link"
      >
        Unlink
      </button>
      <span className="toolbar-sep" />
      <button
        type="button"
        className={btn(false)}
        onClick={() => editor.chain().focus().setHorizontalRule().run()}
        aria-label="Horizontal rule"
        title="Horizontal rule"
      >
        ―
      </button>
      <button
        type="button"
        className={btn(uploading)}
        onClick={() => fileInputRef.current?.click()}
        disabled={uploading}
        aria-label="Insert image"
        title="Insert image (upload)"
      >
        {uploading ? 'Uploading…' : 'Image'}
      </button>
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        hidden
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) onInsertUpload(file);
          e.target.value = '';
        }}
      />
    </div>
  );
}

export default function PostEditor({ initialContent = '', onChange }: PostEditorProps) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        // The backend sanitizer whitelist has no h1/h2→h6 distinction beyond
        // headings as tags; keep levels modest to match blog typography.
        heading: { levels: [2, 3, 4] },
      }),
      Image.configure({ inline: false, allowBase64: false }),
      Link.configure({
        openOnClick: false,
        autolink: true,
        HTMLAttributes: { rel: 'noopener noreferrer', target: '_blank' },
      }),
      Placeholder.configure({ placeholder: 'Write your post…' }),
    ],
    content: initialContent,
    editorProps: {
      attributes: {
        class: 'tiptap-content',
        'aria-label': 'Post body',
      },
    },
    onUpdate: ({ editor: ed }) => {
      onChange?.(ed.getHTML());
    },
  });

  useEffect(() => {
    if (editor && initialContent && editor.isEmpty && editor.getHTML() !== initialContent) {
      editor.commands.setContent(initialContent);
    }
    // Only resync when the external content actually changes identity
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialContent]);

  const insertUploaded = useCallback(
    (url: string, alt: string) => {
      editor?.chain().focus().setImage({ src: url, alt }).run();
    },
    [editor]
  );

  const handleInlineUpload = useCallback(
    (file: File) => {
      setError(null);
      setUploading(true);
      uploadToActiveStorage(file)
        .then(({ url }) => insertUploaded(url, file.name))
        .catch((err) => {
          console.error('[EDITOR] inline upload failed', err);
          setError(err?.message || 'Upload failed. Please try again.');
        })
        .finally(() => setUploading(false));
    },
    [insertUploaded]
  );

  const handleDrop = useCallback(
    (event: React.DragEvent) => {
      const files = Array.from(event.dataTransfer.files || []);
      const media = files.filter((f) => f.type.startsWith('image/'));
      if (media.length === 0) return;
      event.preventDefault();
      media.forEach((file) => {
        setUploading(true);
        uploadToActiveStorage(file)
          .then(({ url }) => insertUploaded(url, file.name))
          .catch((err) => {
            console.error('[EDITOR] drop upload failed', err);
            setError(err?.message || 'Upload failed. Please try again.');
          })
          .finally(() => setUploading(false));
      });
    },
    [insertUploaded]
  );

  return (
    <div
      className="post-editor"
      onDrop={handleDrop}
      onDragOver={(e) => {
        if (Array.from(e.dataTransfer.types).includes('Files')) e.preventDefault();
      }}
    >
      <Toolbar editor={editor} onInsertUpload={handleInlineUpload} uploading={uploading} />
      {error && (
        <div className="editor-error" role="alert">
          {error}
        </div>
      )}
      <EditorContent editor={editor} />
    </div>
  );
}

export { API_BASE };
