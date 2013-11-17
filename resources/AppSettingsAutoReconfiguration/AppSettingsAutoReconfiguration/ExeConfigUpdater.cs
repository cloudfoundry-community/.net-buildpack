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
			var exePath = configFile.CaseInsensitiveReplace(".Config", string.Empty);
			Configuration config = ConfigurationManager.OpenExeConfiguration( exePath );

			//Replace AppSettings with matching ENV variables
			foreach (var key in config.AppSettings.Settings.AllKeys) {
				if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable(key)))
					config.AppSettings.Settings[key].Value = Environment.GetEnvironmentVariable(key);
			}

			config.AppSettings.Settings.Add( "AppSettingsAutoReconfiguration_ModifiedAt", DateTime.UtcNow.ToString("o"));

			config.Save();
		}
	}
}

