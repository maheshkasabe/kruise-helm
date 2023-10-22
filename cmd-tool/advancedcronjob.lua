local acj = {}

function acj.captureCommandOutput(namespace)
    local command = "kubectl get advancedcronjob.apps.kruise.io -n " .. namespace .. " -o yaml"

    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()
    
    if not success then
        return nil, exit_reason, exit_code
    end
    
    return output
end

function acj.checkHealth(output)

    local lyaml = require("lyaml")
    local obj = lyaml.load(output)

    local hs = {
        status = "Progressing",
        message = "AdvancedCronJobs has active jobs"
    }

    local lastScheduleTime = nil

    if obj.items[1].status.lastScheduleTime ~= nil then
        local year, month, day, hour, min, sec = string.match(obj.items[1].status.lastScheduleTime, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
        lastScheduleTime = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
    end

    if lastScheduleTime == nil and obj.items[1].spec.paused == true then 
        hs.status = "Suspended"
        hs.message = "AdvancedCronJob is Paused"
        return hs
    end

    if obj.items[1].status.active ~= nil and #obj.items[1].status.active > 0 then
        hs.status = "Progressing"
        hs.message = "AdvancedCronJobs has active jobs"
        return hs
    end

    if lastScheduleTime == nil then
        hs.status = "Degraded"
        hs.message = "AdvancedCronJobs has not run successfully"
        return hs
    end

    if lastScheduleTime ~= nil then
        hs.status = "Healthy"
        hs.message = "AdvancedCronJobs has run successfully"
        return hs
    end

    return hs
    
end

return acj