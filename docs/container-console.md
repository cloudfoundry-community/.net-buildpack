# NET Console Container

The NET Console Container runs a .NET console app; as identified by the presence of an `{app_name}.exe.config` file somewhere in your uploaded app folder structure.

<table>
  <tr>
    <td><strong>Detection Criteria</strong></td><td><tt>.exe.config</tt> in app folder tree  (`*.vshost.* are ignored`)</td>
  </tr>
  <tr>
    <td><strong>Tags</strong></td><td><tt>console container</tt></td>
  </tr>
</table>

Note that having more than one `.exe.config` in your folder structure will cause an exception.  

Use the [Procfile container](https://github.com/cloudfoundry-community/.net-buildpack/blob/master/docs/container-procfile.md) if you need to run more than one process.  (Or want to explicitly choose which .exe is run)

When the Console container detects $HOME/app/path/to/your-console-app.exe.config it will 
generate the following start command:

```
mono --server $HOME/app/path/to/your-console-app.exe
```

See [spec/fixtures/sample_commandline_app](https://github.com/cloudfoundry-community/.net-buildpack/tree/master/spec/fixtures/sample_commandline_app]) for a full example app.

If your console app doesn't listen for HTTP requests, be sure deploy it with now HTTP route, eg:

```
gcf push app-name -p bin -b https://github.com/cloudfoundry-community/.net-buildpack -m 256 --no-route --no-hostname
```

