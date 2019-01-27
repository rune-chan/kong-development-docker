# Docker Image For Kong Plugin Development and Testing (Kong version > 1.0)
An unofficial docker image of Kong development installation. This image is prepared for Kong plugin development and testing.
See more about kong: https://github.com/Kong/kong

This project only works with Kong version > 1.0. If you are developing legacy Kong (e.g. 0.13.x, 0.10.x), please consider to use 
[MrSaints's Docker](https://github.com/MrSaints/docker-kong-dev) instead.
## Quick Start
If you don't want any customization, simply start kong with docker-compose.
```shell
$ docker-compose up
```

If you are using the `docker-compose.yaml` for the first time, you may need to wait for kong database migration. If you receive database connection error logs in `kong-dev` container, please consider running `docker-compose up` again.

After running the command, Kong will be listening to 
- [localhost:8000](http://localhost:8000) (Proxy)
- [localhost:8443](https://localhost:8443) (Proxy SSL)
- [localhost:8001](http://localhost:8001) (Admin API)
- [localhost:8444](https://localhost:8444) (Admin API SSL)

The default log level is `debug`. You can find logs in directory `./log`.
## Custom Plugin Development
###1. Update kong-plugin path
Update the line in docker-composes.yaml from
```
- ./custom_plugin:/kong-plugin
```
to 
```
- <path-to-plugin-location>:/kong-plugin
```
###2. Config Kong to start with your plugin
Update `KONG_CUSTOM_PLUGINS` in docker-composes.yaml to your list of custom plugins. The name of your custom plugins should be the same as the directory name of your plugin.

###3. Reload Custom Plugin
Run `docker exec kong-dev kong reload` again to reload kong

## Run Test
Execute `/kong/bin/busted` to run all test cases.
```
$ docker exec kong-dev /kong/bin/busted
```
If you want to run only the test cases for your custom plugins, edit `kong_tests.conf` to config kong to load your custom plugins.
```
plugins=bundled,dummy,rewriter,demo-plugin,<your-custom-plugin>
```

Then, run `/kong/bin/busted` with argument `spec/04-custom-plugins`
```
$ docker exec kong-dev /kong/bin/busted spec/04-custom-plugins
```

In case of test cases failures due to Cassandra migration, please try dropping the testing keyspace in Cassandra.
```
$ docker exec kong-cassandra cqlsh kong-cassandra drop keyspace kong-test
```

## Access Kong Database
```
$ docker exec -it kong-cassandra cqlsh kong-cassandra
```

## Reload Configuration
If you have modify anything in `docker-compose.yaml`, execute `docker-compoes up` again to reflect the latest changes in docker-compose.yaml.
```
$ docker-compose up
```