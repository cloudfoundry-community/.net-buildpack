# NET Procfile Container
The NET Procfile Container runs multiple processes as defined in a `Procfile` using [forego (Foreman in Go)](https://github.com/ddollar/forego).

This is useful when your app needs to run more than a single process, eg you need a `web:` process and a `worker:` process 

<table>
  <tr>
    <td><strong>Detection Criteria</strong></td><td><tt>Procfile</tt> in app root folder</td>
  </tr>
  <tr>
    <td><strong>Tags</strong></td><td><tt>net-procfile</tt></td>
  </tr>
</table>

The Procfile container generates a start command similar to:

```
/app/vendor/forego start -p $PORT
```

An example `Procfile` would be (see [spec/fixtures/procfile](https://github.com/cloudfoundry-community/.net-buildpack/tree/master/spec/fixtures/procfile]) for a full example app):

```
web: mono --server bin/myapp-web.exe -port $PORT
worker: mono bin/myapp-worker.exe
```
