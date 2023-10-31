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

function bcj.checkHealthWithTimeout(namespace,timeout)
    local lyaml = require("lyaml")

    local function checkStatus()
        local output = bcj.captureCommandOutput(namespace)
        local obj = lyaml.load(output)
    
        local hs = { status = "Progressing",message = "Waiting for initialization" }
    
        if obj.items[1] ~= nil and obj.items[1].status ~= nil then 
            
            for _, item in ipairs(obj.items) do 
    
                if item.status.desired == item.status.succeeded and item.status.phase == "completed" then 
                    hs.status = "Healthy"
                    hs.message = "BroadcastJob is completed successfully"
                end
    
                if item.status.active ~= 0 and item.status.phase == "running" then
                    hs.status = "Progressing"
                    hs.message = "BroadcastJob is still running"
                end
    
                if item.status.failed ~= 0  and item.status.phase == "failed" then
                    hs.status = "Degraded"
                    hs.message = "BroadcastJob failed"
                end
            
                if item.status.phase == "paused" and item.spec.paused == true then 
                    hs.status = "Suspended"
                    hs.message = "BroadcastJob is Paused"
                end
    
            end
                 
        end
    
        return hs
    end

    local initialStatus = checkStatus()

    if initialStatus.status == "Suspended" or initialStatus.status == "Degraded" or initialStatus.status == "Progressing" then
        for _ = 1, timeout do
            os.execute("sleep 1")
            local recheckStatus = checkStatus()
            if recheckStatus.status ~= initialStatus.status then
                return recheckStatus
            end
        end
    end

    return initialStatus

end

return bcj