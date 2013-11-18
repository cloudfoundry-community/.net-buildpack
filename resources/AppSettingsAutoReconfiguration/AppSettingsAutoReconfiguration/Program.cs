using System;

namespace AppSettingsAutoReconfiguration
{
	class MainClass
	{
		public static void Main (string[] args)
		{
			if (args [0].ToLower ().Contains (".exe")) {
				new ExeConfigUpdater(args [0]).OverrideAppSettingsWithEnvironmentVars ();
			} else if (args [0].ToLower ().Contains ("web.config")) {
				new WebConfigUpdater(args [0]).OverrideAppSettingsWithEnvironmentVars ();
			}  
		}

	}


}
