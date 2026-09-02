// Minimal type declarations for @rails/activestorage (ships untyped JS).
declare module '@rails/activestorage' {
  export interface DirectUploadBlob {
    id?: number;
    signed_id?: string;
    filename?: string;
    content_type?: string;
    byte_size?: number;
  }

  export interface DirectUploadDelegate {
    directUploadWillStoreFileWithXHR?(xhr: XMLHttpRequest): void;
  }

  export class DirectUpload {
    constructor(
      file: File,
      url: string,
      delegate?: DirectUploadDelegate
    );
    create(
      callback: (error: Error | null, blob: DirectUploadBlob | undefined) => void
    ): void;
  }
}
