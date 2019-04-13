# Docker for Kong Local Development
An unofficial Kong local development with Docker. This image can be used for Kong core or Kong plugin development.
See more about kong: https://github.com/Kong/kong

This project only works with Kong version > 1.1. If you are developing legacy Kong (e.g. 0.13.x, 0.10.x), please consider to use 
[MrSaints's Docker](https://github.com/MrSaints/docker-kong-dev).

## Quick Start
This repository does not contain Kong source code. You will need to clone the source code of Kong. Follow the following steps to prepare the development environment.
 ```shell
$ cd kong-deveopment-docker 
 
# get Kong source code
$ git clone https://github.com/Kong/kong

$ docker-compose up -d kong-postgres
# wait for 3 minutes
$ docker-compose up -d kong-postgres-migration
# wait for 1 minute
$ docker-compose up -d kong
# wait for 1 minute
$ docker exec kong-dev make dev
 ```

Wait util kong-dev is running. You can do a `docker ps` to check the status of containers
```shell
$ docker ps
CONTAINER ID        IMAGE                               COMMAND                  CREATED             STATUS                   PORTS                                                                NAMES
470a3ed3c2ab        kong-development-docker_kong        "/docker-entrypoint.…"   33 seconds ago      Up 32 seconds            0.0.0.0:8000-8001->8000-8001/tcp, 0.0.0.0:8443-8444->8443-8444/tcp   kong-dev
b96486f9db40        postgres:11.2                       "docker-entrypoint.s…"   4 minutes ago       Up 4 minutes (healthy)   5432/tcp
```

After running the command, Kong will be listening to 
- [localhost:8000](http://localhost:8000) (Proxy)
- [localhost:8443](https://localhost:8443) (Proxy SSL)
- [localhost:8001](http://localhost:8001) (Admin API)
- [localhost:8444](https://localhost:8444) (Admin API SSL)

The default log level is `debug`. Logs can be found by running `docker logs -f kong-dev`.

Every time after modifying Kong source code, you will need to run `make dev` in Kong container so the updates will be reflected.
```shell
$ docker exec kong-dev make dev
$ docker exec kong-dev kong reload
```
## Custom plugin development
The source of cusotom plugins is in directory `/custom_plugin`. You will need to update the envrionment variable `KONG_PLPUGINS` in docker-composes.yaml
```shell
# service kong-dev
- KONG_PLUGINS=bundled,demo-plugin,<your-custom-plugin>

# service kong-test
- KONG_TEST_PLUGINS=bundled,demo-plugin,<your-custom-pugin>
```

Update `kong` service
```shell
$ docker-compose up -d kong
```

To prepare the testing environment, 'kong-test' should be created before executing any Kong test case.
```shelll
$ docker exec -it kong-postgres psql -U kong -c 'CREATE DATABASE "kong_tests" OWNER kong;'
CREATE DATABASE
```

Modify the `kong-postgres-migration` service in docker-compose.yaml file to bootstrap the testing database.
```shell
### Update docker-compose.yaml
#      - KONG_PG_DATABASE=kong      <- comment this
      - KONG_PG_DATABASE=kong_tests  <- uncomment this
########################## 
```
```shell
$ docker-compose up kong-postgres-migration
```

Finally, bring up `kong-test` service, a docker service with Kong testing environment configurations.
```shell
$ docker-compose up -d kong-test
```
## Testing
Execute /kong/bin/busted to run all test cases.
```shell
$ docker exec kong-test bin/busted
# or docker exec kong-test bin/busted -o gtest
```

Test only the custom plugins
```shell
$ docker exec kong-test bin/busted spec/04-custom-plugins
# or docker exec kong-test bin/busted spec/04-custom-plugins -o gtest
```

## Connect to Kong database
```shell
$ docker exec -it kong-postgres cqlsh kong-postgres
```