import * as remote from "@electron/remote";

// true for connecting to a test server on localhost, false for connecting to the specified domain
const LOCALHOST = false;
const SECURE = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const DOMAIN = "isaacracing.net";
const PROTOCOL_SUFFIX = SECURE && !LOCALHOST ? "s" : "";

export const FADE_TIME = 300; // In milliseconds
export const IS_DEV = !remote.app.isPackaged;
export const PBKDF2_DIGEST = "sha512"; // Digest used for password hashing
export const PBKDF2_ITERATIONS = 1000; // Number of iterations for password hashing
export const PBKDF2_KEYLEN = 150; // Length of resulting password hash in bits
export const WEBSITE_URL = `http${PROTOCOL_SUFFIX}://${
  LOCALHOST ? "localhost" : DOMAIN
}`;
export const WEBSOCKET_URL = `ws${PROTOCOL_SUFFIX}://${
  LOCALHOST ? "localhost" : DOMAIN
}/ws`;
