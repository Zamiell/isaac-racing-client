export default interface LocalConfigVDF {
  UserLocalConfigStore: {
    Software: {
      Valve: {
        Steam: {
          Apps: Record<string, AppConfigVDF>;
        };
      };
    };
  };
}

interface AppConfigVDF {
  LaunchOptions: string;
}
