local DaemonSet = {}

function DaemonSet.captureCommandOutput(namespace)

    local command = "kubectl get daemonset.apps.kruise.io -n " .. namespace .. " -o yaml"

    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()
    
    if not success then
        return nil, exit_reason, exit_code
    end
    
    return output

end

function DaemonSet.checkHealth(output)

    local lyaml = require("lyaml")
    local obj = lyaml.load(output)
    
    --    print(obj.items[1].status.replicas)
    
   local hs={ status = "Progressing", message = "Waiting for initialization" }

    if obj.items[1].status ~= nil then
    
        if obj.items[1].metadata.generation == obj.items[1].status.observedGeneration then
    
            if obj.items[1].spec.updateStrategy.rollingUpdate.paused == true then
                hs.status = "Suspended"
                hs.message = "Daemonset is paused"
                return hs
            elseif obj.items[1].spec.updateStrategy.rollingUpdate.partition and obj.items[1].spec.updateStrategy.rollingUpdate.partition ~= 0 then
                if obj.items[1].status.updatedNumberScheduled > (obj.items[1].status.desiredNumberScheduled - obj.items[1].spec.updateStrategy.rollingUpdate.partition) then
                    hs.status = "Suspended"
                    hs.message = "Daemonset needs manual intervention"
                    return hs
                end
    
            elseif (obj.items[1].status.updatedNumberScheduled == obj.items[1].status.desiredNumberScheduled) and (obj.items[1].status.numberAvailable == obj.items[1].status.desiredNumberScheduled) then
                hs.status = "Healthy"
                hs.message = "All Daemonset workloads are ready and updated"    
            return hs
            
            elseif (obj.items[1].status.updatedNumberScheduled == obj.items[1].status.desiredNumberScheduled) and (obj.items[1].status.numberUnavailable == obj.items[1].status.desiredNumberScheduled) then
                hs.status = "Degraded"
                hs.message = "Some pods are not ready or available"
                return hs
            end
    
        end
    end
    
    return hs

end

return DaemonSet