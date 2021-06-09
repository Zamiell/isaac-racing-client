export {};

declare global {
  class Lang {
    change(newLanguage: string): void;
    init(options: { defaultLang: string }): void;

    pack: Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any
  }
}
