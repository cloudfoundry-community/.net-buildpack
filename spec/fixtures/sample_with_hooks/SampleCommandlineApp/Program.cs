using System;

namespace SampleCommandlineApp
{
    class Program
    {
        static void Main(string[] args)
        {
            while (true)
            {
                Console.WriteLine("{0}\tDoing mock work", DateTime.UtcNow.ToString("u"));
                System.Threading.Thread.Sleep(TimeSpan.FromSeconds(1));
            }
        }
    }
}
