# Design
The buildpack is designed as a collection of components.  These components are divided into three types; 
_CLR Runtimes_, _Containers_, and _Frameworks_.

## CLR Runtimes
Runtimes represent the CLR implementation (MS.NET or Mono) that will be used when running an application.  This type of component is responsible for determining which CLR should be used, downloading and unpacking that CLR runtime (in the case of Mono on Linux) or ensuring the relevant MS.NET CLR version / profile is installed (in the case of .NET on Windows), and resolving any CLR-specific options that should be used at runtime.

Only a single CLR runtime can be used to run an application.

## Containers
Containers represent the way that an application will be run.  Types range from ASP.NET applications that must be hosted in a webserver to simple `.exe` console apps or background workers.  This type of component is responsible for determining which type should be used and producing the command that will be executed by Cloud Foundry at runtime.

Only a single project type can run an application.

## Frameworks
Framework components represent additional behavior or transformations used when an application is run.  Framework types include the automatic reconfiguration of `DataSource`s in App.Config or Web.Config to match bound services.  This type of component is responsible for determining which frameworks are required, transforming the application, and contributing any additional options that should be used at runtime.

Any number of framework components can be used when running an application.