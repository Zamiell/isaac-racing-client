import log from "electron-log";
import { settings } from "../common/settings";
import { languagePackES } from "./languages/es";
import { languagePackFR } from "./languages/fr";

const VALID_LANGUAGES = [
  ["en", "english", "English"],
  ["fr", "french", "Français"],
  ["es", "spanish", "Español"],
] as const;

let lang: Lang | null = null;

export function init(): void {
  // Create a language switcher instance.
  lang = new Lang();

  Lang.prototype.pack["es"] = languagePackES;
  Lang.prototype.pack["fr"] = languagePackFR;

  lang.init({
    defaultLang: "en",
  });

  // If the user is using a non-default language, change all the text on the page. (The above
  // initialization is asynchronous, and we don't know when it will finish, so just wait a while
  // before switching the language.)
  setTimeout(() => {
    // We still call this if the language is English so that the links get initialized correctly.
    const language = settings.get("language") as string;
    localize(language);
  }, 500);
}

// Define the function for the language changing links.
function setLocalize(this: HTMLElement) {
  // Find the language code that goes with this link.
  let matchingLanguageArray: [string, string, string] | undefined;
  for (const languageArray of VALID_LANGUAGES) {
    const match = /\w+-\w+-(\w+)/.exec(this.id);
    if (match !== null) {
      const thisLanguage = match[1];
      if (thisLanguage === languageArray[1]) {
        matchingLanguageArray = [...languageArray];
        break;
      }
    }
  }

  if (matchingLanguageArray !== undefined) {
    localize(matchingLanguageArray[0]);
  }
}

export function localize(newLanguage: string): void {
  if (lang === null) {
    return;
  }

  // Validate function arguments
  const validLanguageCodes: string[] = [];
  for (const languageArray of VALID_LANGUAGES) {
    validLanguageCodes.push(languageArray[0]);
  }
  if (!validLanguageCodes.includes(newLanguage)) {
    log.error(`Unsupported language: ${newLanguage}`);
    return;
  }

  // Update the language setting on disk.
  settings.set("language", newLanguage);

  // Set the new language on the page.
  lang.change(newLanguage);
  for (const languageArray of VALID_LANGUAGES) {
    if (languageArray[0] === newLanguage) {
      $(`#register-language-${languageArray[1]}`).html(languageArray[2]);
      $(`#register-language-${languageArray[1]}`).removeClass(
        "unselected-language",
      );
      $(`#register-language-${languageArray[1]}`).addClass("selected-language");
      $(`#register-language-${languageArray[1]}`).unbind();
    } else {
      $(`#register-language-${languageArray[1]}`).html(
        `<a>${languageArray[2]}</a>`,
      );
      $(`#register-language-${languageArray[1]}`).removeClass(
        "selected-language",
      );
      $(`#register-language-${languageArray[1]}`).addClass(
        "unselected-language",
      );
      $(`#register-language-${languageArray[1]}`).click(setLocalize);
    }
  }
}
