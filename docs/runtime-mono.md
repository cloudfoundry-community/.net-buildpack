# Mono Runtime

When deploying to a Linux stack, the mono runtime is bundled with your app (in `app/vendor/mono`) and used to run your application (via the detected container)

We try to always bundle the most recent Mono runtime (currently 3.2.5)

##Memory

The total available memory is specified when an application is pushed. The .net-buildpack uses this value to control the maximum amout of memory that Mono can use for the heap via the [`MONO_GC_PARAMS` environment variable](http://www.mono-project.com/Release_Notes_Mono_2.8#Configuration)

`MONO_GC_PARAMS="major=marksweep-par,max-heap-size=$(ENV['MEMORY_LIMIT']-48M)"`

Note: if the total available memory is scaled up or down, the .net-buildpack does not re-calculate the  memory settings until the next time the application is pushed (ie, staged).

----
> Yes, 48M is completely arbitrary.  Mono needs some memory for non-heap stuff, and this seems to be enough.