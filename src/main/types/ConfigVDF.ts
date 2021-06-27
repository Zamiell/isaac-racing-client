export default interface ConfigVDF {
  InstallConfigStore: {
    Software: {
      // On my "config.vdf", "Valve" is capitalized
      Valve: ValveConfigVDF;
      // On some platforms, "valve" is lowercase for some reason
      valve: ValveConfigVDF;
    };
  };
}

export interface ValveConfigVDF {
  // On my "config.vdf", "Steam" is capitalized
  Steam: SteamConfigVDF;
  // On some platforms, "steam" is lowercase for some reason
  steam: SteamConfigVDF;
}

export interface SteamConfigVDF {
  BaseInstallFolder_1: string;
}
