declare module "simple-vdf" {
  export function parse(text: string): unknown;
  export function stringify(obj: unknown, pretty?: boolean): string;
  export function dump(obj: unknown, pretty?: boolean): string;
}
