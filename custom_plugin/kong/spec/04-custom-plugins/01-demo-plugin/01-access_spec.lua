local cjson   = require "cjson"
local helpers = require "spec.helpers"
local Errors  = require "kong.db.errors"


for _, strategy in helpers.each_strategy() do
    describe("Plugin: demo-plugin (API) [#" .. strategy .. "]", function()
        local admin_client
        local bp

        lazy_setup(function()
            bp = helpers.get_db_utils(strategy, {
                "routes",
                "services",
                "plugins",
            })
        end)

        lazy_teardown(function()
            if admin_client then
                admin_client:close()
            end

            helpers.stop_kong(nil, true)
        end)

        describe("POST", function()
            local route

            lazy_setup(function()
                local service = bp.services:insert()

                route = bp.routes:insert {
                    hosts      = { "test1.com" },
                    protocols  = { "http", "https" },
                    service    = service
                }

                assert(helpers.start_kong({
                    database   = strategy,
                    nginx_conf = "spec/fixtures/custom_nginx.template",
                    plugins = "bundled,demo-plugin"
                }))

                admin_client = helpers.admin_client()
            end)

            it("should save with empty config", function()
                local res = assert(admin_client:send {
                    method  = "POST",
                    path    = "/plugins",
                    body    = {
                        name  = "demo-plugin",
                        route = { id = route.id },
                    },
                    headers = {
                        ["Content-Type"] = "application/json"
                    }
                })
                local body = assert.res_status(201, res)
            end)
        end)
    end)
end