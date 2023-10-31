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

function StatefulSet.checkHealthWithTimeout(namespace,timeout)
    local lyaml = require("lyaml")

    local function checkStatus()
        local output = StatefulSet.captureCommandOutput(namespace)
        local obj, err = lyaml.load(output)

        local hs = { status = "Progressing", message = "Waiting for initialization" }

        if obj.items[1] ~= nil and obj.items[1].status then
            for _, item in ipairs(obj.items) do
                if item.metadata.generation == item.status.observedGeneration then
                    if item.spec.updateStrategy.rollingUpdate.paused == true or not item.status.updatedAvailableReplicas then
                        hs.status = "Suspended"
                        hs.message = "Statefulset is paused"
                    elseif item.spec.updateStrategy.rollingUpdate.partition ~= 0 and item.metadata.generation > 1 then
                        if item.status.updatedAvailableReplicas == (item.status.replicas - item.spec.updateStrategy.rollingUpdate.partition) then
                            hs.status = "Healthy"
                            hs.message = "All Statefulset workloads are ready and updated"
                        else
                            hs.status = "Suspended"
                            hs.message = "Statefulset needs manual intervention"
                        end
                    elseif item.status.updatedAvailableReplicas == item.status.replicas then
                        hs.status = "Healthy"
                        hs.message = "All Statefulset workloads are ready and updated"
                    elseif item.status.updatedAvailableReplicas ~= item.status.replicas then
                        hs.status = "Degraded"
                        hs.message = "Some replicas are not ready or available"
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

return StatefulSet
