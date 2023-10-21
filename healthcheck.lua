-- Function to run a command and capture its output
local function captureCommandOutput(command)
    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()

    if not success then
        return nil, exit_reason, exit_code
    end

    return output

end

-- Run the kubectl command and capture the output
local kubectlCommand = "kubectl get cloneset -o yaml"
local yamlOutput, _, exitCode = captureCommandOutput(kubectlCommand)
--- print(yamlOutput)

-- Check if the command execution was successful
if yamlOutput then
    -- Load the YAML output into a Lua table
    local lyaml = require("lyaml")
    local obj = lyaml.load(yamlOutput)

--    print(obj.items[1].status.replicas)

    local hs = {
        status = "Progressing",
        message = "Waiting for initialization"
    }

    if obj.items[1].status and obj.items[1].metadata.generation == obj.items[1].status.observedGeneration then
        if obj.items[1].status.updatedAvailableReplicas == obj.items[1].status.replicas then
            hs.status = "Healthy"
            hs.message = "All Cloneset workloads are ready and updated"
        elseif obj.items[1].status.updatedAvailableReplicas ~= obj.items[1].status.replicas then
            hs.status = "Degraded"
            hs.message = "Some replicas are not ready or available"
        end
    end

    print("Status:", hs.status)
    print("Message:", hs.message)

    if hs.status == "Healthy" then
        print("Not healthy. Exiting with a non-zero exit code.")
        os.exit(1, true) -- 1 indicates a non-zero exit code
    end
    -- Check if the 'status' field is present
else
    print("Failed to execute kubectl command (Exit code:", exitCode, ")")
end