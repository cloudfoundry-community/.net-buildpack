.net-buildpack
==============
[![Build Status](https://travis-ci.org/cloudfoundry-community/.net-buildpack.png?branch=master)](https://travis-ci.org/cloudfoundry-community/.net-buildpack)

Cloud Foundry buildpack for running .NET applications 

* Aiming for feature parity with https://github.com/cloudfoundry/java-buildpack
* Initially focussed on running .NET apps compiled on Windows** under Mono on lucid64 stack

### Status
[![Stories in Ready](https://badge.waffle.io/cloudfoundry-community/.net-buildpack.png)](http://waffle.io/cloudfoundry-community/.net-buildpack)

This buildpack is in "alpha" stage - that is to say that not all the features are there yet.

##### What already works?

* Console apps running under Mono 3.2.4 on Cloud Foundry ( lucid64 stack )
* NancyFX web apps running under Mono 3.2.4 on Cloud Foundry ( lucid64 stack )

##### What is next?

*  ASP.NET MVC support - see [#17](https://github.com/cloudfoundry-community/.net-buildpack/issues/17)
*  Console apps running under .NET 4.5 / IronFoundry.NET  ( Windows 2012 stack )

## Documentation
* [Design](docs/design.md)
* Runtimes
	* [Mono](docs/runtime-mono.md) (functional)
	* CLR (coming soon)
* Containers
	* [Console](docs/container-console.md)
	* [Procfile](docs/container-procfile.md)
* Frameworks
	* [AppSettingsAutoReconfiguration](docs/framework-app_settings_auto_reconfiguration.md) 

### Getting involved

We're actively looking for volunteers.  Join us commenting on an existing issue or opening a new one!

We also hang out on the [Cloud Foundry Dev Mailing list](https://groups.google.com/a/cloudfoundry.org/forum/#!forum/vcap-dev); 
just mention .net-buildpack.

---

> ** Apps written and compiled with Mono (eg, via  Xamarin Studio, MonoDevelop or xbuild) work too.
