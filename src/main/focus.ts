import path from "path";

export function isaacFocus(): void {
  if (process.platform !== "win32") {
    return;
  }

  const pathToFocusIsaac = path.join(
    __dirname,
    "programs",
    "focusIsaac",
    "focusIsaac.exe",
  );
  console.log(pathToFocusIsaac);
  /*
  execFile(pathToFocusIsaac, (error, stdout, stderr) => {
    // We have to attach an empty callback to this or it does not work for some reason
  });
  */
}
