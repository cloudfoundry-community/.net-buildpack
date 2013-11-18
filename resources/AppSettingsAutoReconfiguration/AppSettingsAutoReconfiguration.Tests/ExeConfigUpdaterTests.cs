using NUnit.Framework;
using System;
using System.Configuration;

namespace AppSettingsAutoReconfiguration.Tests
{
	[TestFixture ()]
	public class ExeConfigUpdaterTests
	{
		[Test ()]
		public void ShouldAddModifiedAt ()
		{
			CreateSampleConfigFile ();

			new ExeConfigUpdater("SampleCommandlineApp.exe.Config")
				.OverrideAppSettingsWithEnvironmentVars ();

			var config = ConfigurationManager.OpenExeConfiguration( "SampleCommandlineApp.exe" );

			CollectionAssert.Contains (config.AppSettings.Settings.AllKeys, "AppSettingsAutoReconfiguration_ModifiedAt");
			Console.WriteLine (config.AppSettings.Settings ["AppSettingsAutoReconfiguration_ModifiedAt"].Value);
		}

		static void CreateSampleConfigFile ()
		{
			System.IO.File.WriteAllText ("SampleCommandlineApp.exe", "");
			System.IO.File.WriteAllText ("SampleCommandlineApp.exe.Config", @"<?xml version=""1.0"" encoding=""utf-8""?>
<configuration>
	<appSettings>
		<add key=""Key1"" value=""Value1"" />
		<add key=""PORT"" value=""1234"" />
	</appSettings>
</configuration>
");
		}

		[Test ()]
		public void ShouldOverridePortAppSettingWithEnvironmentValue ()
		{
			CreateSampleConfigFile ();

			System.Environment.SetEnvironmentVariable ("PORT", "67564");

			new ExeConfigUpdater("SampleCommandlineApp.exe.Config")
				.OverrideAppSettingsWithEnvironmentVars ();

			var config = ConfigurationManager.OpenExeConfiguration( "SampleCommandlineApp.exe" );

			Assert.AreEqual(config.AppSettings.Settings["Key1"].Value, "Value1");
			Assert.AreEqual(config.AppSettings.Settings["PORT"].Value, "67564");
		}
	}
}

