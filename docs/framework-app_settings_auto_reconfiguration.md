# AppSettings Auto Reconfiguration Framework

If your application has an `.config` that contains an `<AppSettings>` section, keys that match environment variables are rewritten during app startup.

_NB This feature has not been implemented for `Web.config` (yet)_

## How this feature works

Your `.config` should contain your development settings, eg

```xml
<configuration>
    <appSettings>
      <add key="PORT" value="1234" />
    </appSettings>
</configuration>
```

Your code should use the standard `ConfigurationManager.AppSettings["PORT"]` technique of loading configuration values.

At development time, you use the (test) config values committed to your repo in the `App.config` file.

When deploying to Cloud Foundry, your `.config` file is rewritten such that any key in any config file's AppSettings section is replaced with the value of the matching CF runtime ENV variable.

Thus, at run time you would effectively have a `.config` that had been rewritten to the following:

```xml
<configuration>
    <appSettings>
      <add key="PORT" value="61245" />
    </appSettings>
</configuration>
```

Since `ENV['PORT']` == `61245`

## Further details

See the [resources/AppSettingsAutoReconfiguration](https://github.com/cloudfoundry-community/.net-buildpack/tree/master/resources/AppSettingsAutoReconfiguration) .NET application, which is run at app startup to rewrite your `.config`