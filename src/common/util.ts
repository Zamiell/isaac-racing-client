import { SocketCommandOut } from "../renderer/types/SocketCommand";

/**
 * parseIntSafe is a more reliable version of parseInt.
 * By default, "parseInt('1a')" will return "1", which is unexpected.
 * This returns either an integer or NaN.
 */
export function parseIntSafe(input: string): number {
  if (typeof input !== "string") {
    return NaN;
  }

  // Remove all leading and trailing whitespace
  let trimmedInput = input.trim();

  const isNegativeNumber = trimmedInput.startsWith("-");
  if (isNegativeNumber) {
    // Remove the leading minus sign before we match the regular expression
    trimmedInput = trimmedInput.substring(1);
  }

  if (/^\d+$/.exec(trimmedInput) === null) {
    // "\d" matches any digit (same as "[0-9]")
    return NaN;
  }

  if (isNegativeNumber) {
    // Add the leading minus sign back
    trimmedInput = `-${trimmedInput}`;
  }

  return Number.parseInt(trimmedInput, 10);
}

// e.g. "floor 1" or "finish"
export function unpackSocketMsg(rawData: string): [SocketCommandOut, string] {
  const separator = " ";
  const [command, ...dataArray] = rawData.trim().split(separator);
  const data = dataArray.join(separator);

  return [command as SocketCommandOut, data];
}
