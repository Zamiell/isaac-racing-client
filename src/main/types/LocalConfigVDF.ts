export default interface LocalConfigVDF {
  UserLocalConfigStore: {
    Software: {
      Valve: {
        Steam: {
          // On my "localconfig.vdf", "Apps" is capitalized
          Apps?: Record<string, AppConfigVDF>;
          // On some platforms, "apps" is lowercase for some reason
          apps?: Record<string, AppConfigVDF>;
        };
      };
    };
  };
}

export interface AppConfigVDF {
  LaunchOptions: string;
}
