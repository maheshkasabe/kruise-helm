local DaemonSet = {}

function DaemonSet.captureCommandOutput(namespace,workloadName)

    local command = "kubectl get daemonset.apps.kruise.io -n " .. namespace .. " -o yaml"
    if workloadName then
        command = command .. " " .. workloadName
    end

    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()
    
    if not success then
        return nil, exit_reason, exit_code
    end

    return output
end

function DaemonSet.checkHealthWithTimeout(namespace, timeout, workloadName)
    local lyaml = require("lyaml")

    local function checkStatus()
        local output = DaemonSet.captureCommandOutput(namespace, workloadName)
        local obj = lyaml.load(output)
        
        local hs={ status = "Progressing", message = "Waiting for initialization" }

        if obj.items[1] ~= nil and obj.items[1].status ~= nil then
            
            for _, item in ipairs(obj.items) do
                
                if item.metadata.generation == item.status.observedGeneration then
        
                    if item.spec.updateStrategy.rollingUpdate.paused == true or not item.status.updatedNumberScheduled then
                        hs.status = "Suspended"
                        hs.message = "Daemonset is paused"
                    
                    elseif item.spec.updateStrategy.rollingUpdate.partition > 0 and item.metadata.generation > 1 then
                        if item.status.updatedNumberScheduled == (item.status.desiredNumberScheduled - item.spec.updateStrategy.rollingUpdate.partition) then
                            hs.status = "Healthy"
                            hs.message = "All Daemonset workloads are ready and updated"
                        else
                            hs.status = "Suspended"
                            hs.message = "Daemonset needs manual intervention"
                        end
            
                    elseif (item.status.updatedNumberScheduled == item.status.desiredNumberScheduled) and (item.status.numberAvailable == item.status.desiredNumberScheduled) then
                        hs.status = "Healthy"
                        hs.message = "All Daemonset workloads are ready and updated"
                    
                    elseif (item.status.updatedNumberScheduled == item.status.desiredNumberScheduled) and (item.status.numberUnavailable == item.status.desiredNumberScheduled) then
                        hs.status = "Degraded"
                        hs.message = "Some pods are not ready or available"
                    end
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

return DaemonSet