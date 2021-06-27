export default interface LocalConfigVDF {
  UserLocalConfigStore: {
    Software: {
      // On my "localconfig.vdf", "Valve" is capitalized
      Valve: ValveLocalConfigVDF;
      // On some platforms, "valve" is lowercase for some reason
      valve: ValveLocalConfigVDF;
    };
  };
}

export interface ValveLocalConfigVDF {
  // On my "localconfig.vdf", "Steam" is capitalized
  Steam: SteamLocalConfigVDF;
  // On some platforms, "steam" is lowercase for some reason
  steam: SteamLocalConfigVDF;
}

export interface SteamLocalConfigVDF {
  // On my "localconfig.vdf", "Apps" is capitalized
  Apps?: Record<string, AppConfigVDF>;
  // On some platforms, "apps" is lowercase for some reason
  apps?: Record<string, AppConfigVDF>;
}

export interface AppConfigVDF {
  LaunchOptions?: string;
}
