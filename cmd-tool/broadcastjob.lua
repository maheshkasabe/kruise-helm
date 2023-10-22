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

    if obj.items[1].status ~= nil then 

        if obj.items[1].status.desired == obj.items[1].status.succeeded and obj.items[1].status.phase == "completed" then 
            hs.status = "Healthy"
            hs.message = "BroadcastJob is completed successfully"
                return hs
        end

        if obj.items[1].status.active ~= 0 and obj.items[1].status.phase == "running" then
            hs.status = "Progressing"
            hs.message = "BroadcastJob is still running"
            return hs
        end

        if obj.items[1].status.failed ~= 0  and obj.items[1].status.phase == "failed" then
                hs.status = "Degraded"
                hs.message = "BroadcastJob failed"
                return hs
        end
        
        if obj.items[1].status.phase == "paused" and obj.items[1].spec.paused == true then 
            hs.status = "Suspended"
            hs.message = "BroadcastJob is Paused"
            return hs
        end
             
    end

    return hs

end

return bcj