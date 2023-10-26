local StatefulSet = {}

function StatefulSet.captureCommandOutput(namespace)
    
    local command = "kubectl get cloneset.apps.kruise.io -n " .. namespace .. " -o yaml"

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
    
---    print(obj.items[1].status.replicas)
    
    local hs={ status = "Progressing", message = "Waiting for initialization" }

    if obj.items[1] and obj.items[1].status ~= nil then

        for _, item in ipairs(obj.items) do 
            
            if item.metadata.generation == item.status.observedGeneration then
    
                if item.spec.updateStrategy.rollingUpdate.paused == true then
                    hs.status = "Suspended"
                    hs.message = "Statefulset is paused"
                    return hs

                -- elseif item.spec.updateStrategy.rollingUpdate.partition ~= 0 and item.metadata.generation > 1 then
                --     if item.status.updatedAvailableReplicas == (item.status.replicas-item.spec.updateStrategy.rollingUpdate.partition) then
                --         hs.status = "Healthy"
                --         hs.message = "All Statefulset workloads are ready and updated"
                --         return hs
                --     else
                --         hs.status = "Suspended"
                --         hs.message = "Statefulset needs manual intervention"
                --         return hs
                --     end
        
                elseif item.status.updatedAvailableReplicas == item.status.replicas then
                    hs.status = "Healthy"
                    hs.message = "All Statefulset workloads are ready and updated"    
                    return hs
                
                elseif item.status.updatedAvailableReplicas ~= item.status.replicas then
                    hs.status = "Degraded"
                    hs.message = "Some replicas are not ready or available"
                    return hs
                end
            end
        end
    end
    
return hs

end

return StatefulSet