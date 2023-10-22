local StatefulSet = {}

function StatefulSet.captureCommandOutput(namespace)
    
    local command = "kubectl get statefulset.apps.kruise.io -n " .. namespace .. " -o yaml"

    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()
    
    if not success then
        return nil, exit_reason, exit_code
    end
    
    return output

end

function StatefulSet.checkHealth(ouput)
    
    local lyaml = require("lyaml")
    local obj = lyaml.load(output)
    
    --    print(obj.items[1].status.replicas)
    
    local hs={ status = "Progressing", message = "Waiting for initialization" }

    if obj.items[1].status ~= nil then
    
        if obj.items[1].metadata.generation == obj.items[1].status.observedGeneration then
    
            if obj.items[1].spec.updateStrategy.rollingUpdate.paused == true then
                hs.status = "Suspended"
                hs.message = "Statefulset is paused"
                return hs
            elseif obj.items[1].spec.updateStrategy.rollingUpdate.partition ~= 0 then
                if obj.items[1].status.updatedReplicas > (obj.items[1].status.replicas - obj.items[1].spec.updateStrategy.rollingUpdate.partition) then
                    hs.status = "Suspended"
                    hs.message = "Statefulset needs manual intervention"
                    return hs
                end
    
            elseif obj.items[1].status.updatedAvailableReplicas == obj.items[1].status.replicas then
                hs.status = "Healthy"
                hs.message = "All Statefulset workloads are ready and updated"    
                return hs
            
            elseif obj.items[1].status.updatedAvailableReplicas ~= obj.items[1].status.replicas then
                hs.status = "Degraded"
                hs.message = "Some replicas are not ready or available"
                return hs
            end
    
        end
    
    end
    
    return hs

end

return statefulset