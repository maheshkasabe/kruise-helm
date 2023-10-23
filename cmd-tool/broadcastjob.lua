local bcj = {}

function bcj.captureCommandOutput(namespace)
    local command = "kubectl get broadcastjob.apps.kruise.io -n " .. namespace .. " -o yaml"

    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()
    
    if not success then
        return nil, exit_reason, exit_code
    end
    
    return output
end

function bcj.checkHealth(output)

    local lyaml = require("lyaml")
    local obj = lyaml.load(output)

    local hs = {
        status = "Progressing",
        message = "Waiting for initialization"
    }

    if obj.items[1] and obj.items[1].status ~= nil then 
        
        for _, item in ipairs(obj.items) do 

            if item.status.desired == item.status.succeeded and item.status.phase == "completed" then 
                hs.status = "Healthy"
                hs.message = "BroadcastJob is completed successfully"
                return hs
            end

            if item.status.active ~= 0 and item.status.phase == "running" then
                hs.status = "Progressing"
                hs.message = "BroadcastJob is still running"
                return hs
            end

            if item.status.failed ~= 0  and item.status.phase == "failed" then
                hs.status = "Degraded"
                hs.message = "BroadcastJob failed"
                return hs
            end
        
            if item.status.phase == "paused" and item.spec.paused == true then 
                hs.status = "Suspended"
                hs.message = "BroadcastJob is Paused"
                return hs
            end

        end
             
    end

    return hs

end

return bcj