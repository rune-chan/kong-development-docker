local BasePlugin = require "kong.plugins.base_plugin"
local CustomHandler = BasePlugin:extend()

function CustomHandler:new()
    CustomHandler.super.new(self, "demo-plugin")
end

return CustomHandler