using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading;
using Nancy.Hosting.Self;
using Nancy;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Nancy.Diagnostics;

namespace NancyFXSample
{
	class MainClass
	{
		public static void Main (string[] args)
		{
			var nancyHost = CreateCFNancyHost ();

			nancyHost.Start ();
			Console.WriteLine ("Nancy is listening for requests...");

			while (1==1) {
				Thread.Sleep (300);
			}
		}

		public static NancyHost CreateCFNancyHost() {
			var port = System.Environment.GetEnvironmentVariable ("PORT");
			var cf_settings = System.Environment.GetEnvironmentVariable ("VCAP_APPLICATION");
			var uris = new List<Uri> () {
				new Uri (String.Format ("http://0.0.0.0:{0}", port))
			};

			if (!String.IsNullOrEmpty(cf_settings)) {
				var settings = JsonConvert.DeserializeObject<JObject> (cf_settings);
				foreach (var uri_string in settings["uris"]) {
					uris.Add(new Uri(String.Format ("http://{0}:{1}", uri_string, port)));
				}

			}

			return new NancyHost(uris.ToArray());
		}


		public class HelloModule : NancyModule
		{
			public HelloModule()
			{
				Get["/"] = parameters => "Hello World";
			}
		}
	}
}
