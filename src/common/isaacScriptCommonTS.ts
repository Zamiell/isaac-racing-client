// The functions here are copied from `isaacscript-common-ts` because this package uses CommonJS
// instead of ESM.

/* eslint-disable @typescript-eslint/no-explicit-any */

interface ReadonlyMapConstructor {
  new (): ReadonlyMap<any, any>;
  new <K, V>(
    entries?: ReadonlyArray<readonly [K, V]> | Iterable<readonly [K, V]> | null,
  ): ReadonlyMap<K, V>;
  readonly prototype: ReadonlyMap<any, any>;
}

/** An alias for the `Map` constructor that returns a read-only map. */
export const ReadonlyMap = Map as ReadonlyMapConstructor;

interface ReadonlySetConstructor {
  new <T = any>(values?: readonly T[] | Iterable<T> | null): ReadonlySet<T>;
  readonly prototype: ReadonlySet<any>;
}

/** An alias for the `Set` constructor that returns a read-only set. */
export const ReadonlySet = Set as ReadonlySetConstructor;

const INTEGER_REGEX = /^-?\d+$/;

/**
 * Shallow copies and removes the specified element(s) from the array. Returns the copied array. If
 * the specified element(s) are not found in the array, it will simply return a shallow copy of the
 * array.
 *
 * This function is variadic, meaning that you can specify N arguments to remove N elements.
 */
function arrayRemove<T>(
  originalArray: T[] | readonly T[],
  ...elementsToRemove: T[]
): T[] {
  const elementsToRemoveSet = new ReadonlySet(elementsToRemove);

  const array: T[] = [];
  for (const element of originalArray) {
    if (!elementsToRemoveSet.has(element)) {
      array.push(element);
    }
  }

  return array;
}

/**
 * Helper function to get a random element from the provided array.
 *
 * @param array The array to get an element from.
 * @param exceptions Optional. An array of elements to skip over if selected.
 */
export function getRandomArrayElement<T>(
  array: T[] | readonly T[],
  exceptions: T[] | readonly T[] = [],
): T {
  if (array.length === 0) {
    throw new Error(
      "Failed to get a random array element since the provided array is empty.",
    );
  }

  const arrayWithoutExceptions = arrayRemove(array, ...exceptions);
  const randomIndex = getRandomArrayIndex(arrayWithoutExceptions);
  const randomElement = arrayWithoutExceptions[randomIndex];
  if (randomElement === undefined) {
    throw new Error(
      `Failed to get a random array element since the random index of ${randomIndex} was not valid.`,
    );
  }

  return randomElement;
}

/**
 * Helper function to get a random index from the provided array.
 *
 * @param array The array to get the index from.
 * @param exceptions Optional. An array of indexes that will be skipped over when getting the random
 *                   index. Default is an empty array.
 */
export function getRandomArrayIndex<T>(
  array: T[] | readonly T[],
  exceptions: number[] | readonly number[] = [],
): number {
  if (array.length === 0) {
    throw new Error(
      "Failed to get a random array index since the provided array is empty.",
    );
  }

  return getRandomInt(0, array.length - 1, exceptions);
}

/**
 * This returns a random integer between min and max. It is inclusive on both ends.
 *
 * For example:
 *
 * ```ts
 * const oneTwoOrThree = getRandomInt(1, 3);
 * ```
 *
 * @param min The lower bound for the random number (inclusive).
 * @param max The upper bound for the random number (inclusive).
 * @param exceptions Optional. An array of elements that will be skipped over when getting the
 *                   random integer. For example, a min of 1, a max of 4, and an exceptions array of
 *                   `[2]` would cause the function to return either 1, 3, or 4. Default is an empty
 *                   array.
 */
function getRandomInt(
  min: number,
  max: number,
  exceptions: number[] | readonly number[] = [],
): number {
  min = Math.ceil(min); // eslint-disable-line no-param-reassign
  max = Math.floor(max); // eslint-disable-line no-param-reassign

  if (min > max) {
    const oldMin = min;
    const oldMax = max;

    min = oldMax; // eslint-disable-line no-param-reassign
    max = oldMin; // eslint-disable-line no-param-reassign
  }

  const exceptionsSet = new ReadonlySet(exceptions);

  let randomInt: number;
  do {
    randomInt = Math.floor(Math.random() * (max - min + 1)) + min;
  } while (exceptionsSet.has(randomInt));

  return randomInt;
}

/**
 * This is a more reliable version of `Number.parseInt`:
 *
 * - `undefined` is returned instead of `Number.NaN`, which is helpful in conjunction with
 *   TypeScript type narrowing patterns.
 * - Strings that are a mixture of numbers and letters will result in undefined instead of the part
 *   of the string that is the number. (e.g. "1a" --> undefined instead of "1a" --> 1)
 * - Non-strings will result in undefined instead of being coerced to a number.
 *
 * @param string A string to convert to an integer.
 * @param radix Optional. A value between 2 and 36 that specifies the base of the number in
 *              `string`. Default is 10 (which corresponds to a normal decimal number).
 */
export function parseIntSafe(string: string, radix = 10): number | undefined {
  if (typeof string !== "string") {
    return undefined;
  }

  const trimmedString = string.trim();

  // If the string does not entirely consist of numbers, return undefined.
  if (INTEGER_REGEX.exec(trimmedString) === null) {
    return undefined;
  }

  const number = Number.parseInt(trimmedString, radix);
  return Number.isNaN(number) ? undefined : number;
}
