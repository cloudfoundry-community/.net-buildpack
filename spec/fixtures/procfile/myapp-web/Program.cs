using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading;
using Nancy.Hosting.Self;
using Nancy;

namespace NancyFXSample
{
	class MainClass
	{
		public static void Main (string[] args)
		{
			var baseUri = new Uri (String.Format("http://0.0.0.0:{0}", System.Environment.GetEnvironmentVariable("PORT")));
			var nancyHost = new NancyHost (baseUri);

			nancyHost.Start ();
			Console.WriteLine ("Nancy Listening on {0}", baseUri.AbsoluteUri);

			while (1==1) {
				Thread.Sleep (10);
			}
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
