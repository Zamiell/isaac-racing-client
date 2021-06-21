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
  Steam: {
    BaseInstallFolder_1: string;
  };
}
