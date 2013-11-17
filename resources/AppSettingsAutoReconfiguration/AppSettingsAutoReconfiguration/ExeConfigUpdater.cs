using System;
using System.Configuration;

namespace AppSettingsAutoReconfiguration
{
	public class ExeConfigUpdater
	{
		string configFile;

		public ExeConfigUpdater (string configFile)
		{
			this.configFile = configFile;
		}

		public void OverrideAppSettingsWithEnvironmentVars ()
		{
			Console.WriteLine (string.Format ("Updating AppSettings for {0} ", configFile)); 
			var exePath = configFile.CaseInsensitiveReplace(".Config", string.Empty);
			Configuration config = ConfigurationManager.OpenExeConfiguration( exePath );

			//Replace AppSettings with matching ENV variables
			foreach (var key in config.AppSettings.Settings.AllKeys) {
				var env_value = Environment.GetEnvironmentVariable (key);
				if (!string.IsNullOrEmpty (env_value)) {
					config.AppSettings.Settings [key].Value = env_value;
					Console.WriteLine (string.Format ("Updated AppSetting {0} => ENV[{1}] == {2}", key, key, env_value)); 
				}
			}

			config.AppSettings.Settings.Add( "AppSettingsAutoReconfiguration_ModifiedAt", DateTime.UtcNow.ToString("o"));

			config.Save();
		}
	}
}

