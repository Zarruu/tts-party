--!strict

local projectInfo = require("../src/shared/ProjectInfo")

return {
    ["loads shared project metadata outside Studio"] = function()
        assert(projectInfo.name == "TTS Party", "unexpected project name from src/shared")
    end,
}
