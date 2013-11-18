using System;
using System.Configuration;
using System.IO;
using System.Web.Configuration;

namespace AppSettingsAutoReconfiguration
{
	public class WebConfigUpdater
	{
		string configFile;

		public WebConfigUpdater (string configFile)
		{
			this.configFile = configFile;
		}

		public void OverrideAppSettingsWithEnvironmentVars ()
		{
			throw new NotImplementedException ("Not implemented as WebConfigurationManager seems buggy in Mono 3.2.4");

			string directory = Path.GetDirectoryName(Path.GetFullPath(configFile));
			WebConfigurationFileMap wcfm = new WebConfigurationFileMap();
			VirtualDirectoryMapping vdm = new VirtualDirectoryMapping(directory, true, "Web.config");
			wcfm.VirtualDirectories.Add("/", vdm);

			//WebConfigurationManager seems bugging in Mono 3.2.4
			Configuration webConfig = WebConfigurationManager.OpenMappedWebConfiguration(wcfm, "/");

		}
	}
}

