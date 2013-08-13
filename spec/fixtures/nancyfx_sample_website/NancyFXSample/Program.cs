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
			var app = CloudFoundry.Mono.Environment.Application ();
			var uris = app.getFullUris ();
			var nancyHost = new NancyHost(uris);

			nancyHost.Start ();
			Console.WriteLine ("Nancy Listening to " + String.Join(",", uris.Select (e => e.AbsoluteUri)));

			while (1==1) {
				Thread.Sleep (10);
			}
		}

		public class HelloModule : NancyModule
		{
			public HelloModule()
			{
				Get["/"] = parameters => "Hello World";
				Get["/mu-25b8a55c-a9fee579-723dcc44-9750de2e"] = parameters => "42";
				Get["/lipsum"] = parameters => {
					var lipsum = @"<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam pretium nisl et molestie ultrices. Pellentesque sed mattis nunc. Pellentesque vitae tortor faucibus erat sollicitudin scelerisque a eu dui. Morbi egestas in eros in condimentum. Donec nulla tellus, imperdiet quis tincidunt ut, sagittis et leo. Ut blandit tortor at lacus ullamcorper tempus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Interdum et malesuada fames ac ante ipsum primis in faucibus."
					+ "<p>Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Pellentesque in dui blandit massa venenatis luctus. Sed pharetra neque nulla, quis consequat velit malesuada quis. Donec consectetur sit amet lorem ut viverra. Nam varius eu erat vehicula sollicitudin. Nulla vulputate est a ipsum pretium, at blandit dui dignissim. Praesent sollicitudin dapibus nisi eu lacinia. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris euismod posuere faucibus."
					+ "<p>Nunc nulla eros, dignissim quis feugiat vitae, dignissim nec urna. Curabitur at enim cursus, mattis nunc quis, cursus dui. Nulla molestie nunc eu odio congue, ac adipiscing nunc iaculis. Nulla in nunc massa. Aenean pellentesque faucibus lobortis. Donec vitae quam tempor, consequat dolor lacinia, adipiscing nibh. Donec ut felis id dolor pellentesque sodales. Proin accumsan pellentesque arcu. Donec a fermentum enim. Nunc sed imperdiet nulla."
					+ "<p>Pellentesque semper sapien quis nunc fringilla mollis. Mauris eget laoreet risus. Ut euismod nec magna nec eleifend. Donec et enim sed libero ultricies ultricies. Duis gravida quam commodo scelerisque dictum. Phasellus ac tristique lacus. Donec ullamcorper ligula non dui fermentum gravida. Aenean gravida, turpis imperdiet fermentum pretium, nunc orci vestibulum dui, vitae congue magna est mollis sem. Phasellus quis euismod elit. Proin non leo a nisl pellentesque sodales vel eget lectus. In sit amet est at elit interdum dictum. Nullam tempor odio vel diam laoreet ultrices. Mauris nunc lorem, mollis sit amet tempus eget, convallis id lectus. Ut aliquam dolor ut sodales cursus. Nullam blandit lacinia augue, sed congue ligula scelerisque quis."
					+ "<p>Nunc at feugiat mi. Interdum et malesuada fames ac ante ipsum primis in faucibus. Nulla facilisi. Aliquam venenatis dui sed pharetra mattis. Pellentesque varius tristique feugiat. Integer hendrerit vel odio vitae pretium. Ut eleifend mi est, vitae convallis risus commodo sed. Sed odio augue, auctor non leo in, rutrum pulvinar purus. Mauris scelerisque metus nibh, at dignissim augue faucibus a. Vestibulum cursus risus a rutrum elementum. Quisque venenatis eu lectus a adipiscing. Nunc sit amet quam sapien. Curabitur odio nisl, consequat eu dui hendrerit, imperdiet lacinia odio. In viverra ligula in ipsum hendrerit, quis commodo diam iaculis. Mauris in nibh id lorem commodo venenatis.";
					var ret = "";
					for (int i = 0; i < 10; i++) {
						ret += lipsum;
					}
					return ret;
				};
			}
		}
	}
}
