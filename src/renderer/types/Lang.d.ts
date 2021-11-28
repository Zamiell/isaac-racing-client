export {};

declare global {
  class Lang {
    change(newLanguage: string): void;
    init(options: { defaultLang: string }): void;

    pack: Record<string, unknown>;
  }
}
