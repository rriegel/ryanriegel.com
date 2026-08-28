# Test Media Files

Drop test media files here for seed data.

## Directory Structure

```
media/
├── cover_images/     # Cover images for post cards
│   ├── cover-01.jpg
│   ├── cover-02.jpg
│   └── ...
├── inline/           # Inline media for post bodies
│   ├── image-01.jpg
│   ├── video-01.mp4
│   ├── audio-01.mp3
│   └── ...
└── README.md
```

## Recommended Files

### Cover Images (cover_images/)
- 5-6 images, 1200x630px recommended (16:9 aspect ratio)
- Formats: JPG, PNG, WebP
- Used for post card thumbnails and hero sections

### Inline Media (inline/)
- 2-3 images (JPG/PNG/WebP)
- 1-2 videos (MP4, WebM)
- 1 audio file (MP3, OGG)

## Usage

The seed script will automatically attach these files to posts:
- Cover images: attached to 5-6 posts
- Inline media: embedded in post body HTML

Files are optional — if they don't exist, the seed script skips them gracefully.
