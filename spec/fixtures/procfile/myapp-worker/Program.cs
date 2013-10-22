using System;
using System.Threading;

namespace myappworker
{
	class MainClass
	{
		public static void Main (string[] args)
		{
			var wait = Convert.ToInt32(TimeSpan.FromSeconds(30).TotalMilliseconds);

			while (1==1) {
				Console.WriteLine ("Doing work! ...");
				Thread.Sleep (wait);
			}
		}
	}
}
