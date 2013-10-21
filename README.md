.net-buildpack
==============
[![Build Status](https://travis-ci.org/cloudfoundry-community/.net-buildpack.png?branch=master)](https://travis-ci.org/cloudfoundry-community/.net-buildpack)

Cloud Foundry buildpack for running .NET applications 

* Aiming for feature parity with https://github.com/cloudfoundry/java-buildpack
* Initially focussed on running .NET apps compiled on windows under Mono on lucid64 stack

### Status
[![Stories in Ready](https://badge.waffle.io/cloudfoundry-community/.net-buildpack.png)](http://waffle.io/cloudfoundry-community/.net-buildpack)

This buildpack is in "alpha" stage - that is to say that not all the features are there yet.

##### What already works?

* Console apps running under Mono 3.2.3 on Cloud Foundry ( lucid64 stack )
* NancyFX web apps running under Mono 3.2.3 on Cloud Foundry ( lucid64 stack )

##### What is next?

*  ASP.NET MVC support - see [#17](https://github.com/cloudfoundry-community/.net-buildpack/issues/17)
*  Console apps running under .NET 4.5 / IronFoundry.NET  ( Windows 2012 stack )

### Getting involved

We're actively looking for volunteers.  Join us by adding a comment to 
[#1 - Recruit a team](https://github.com/cloudfoundry-community/.net-buildpack/issues/1)
