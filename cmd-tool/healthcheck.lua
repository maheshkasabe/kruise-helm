-- -- Function to run a command and capture its output
-- local function captureCommandOutput(command)
--     local handle = io.popen(command)
--     local output = handle:read("*a")
--     local success, exit_reason, exit_code = handle:close()

--     if not success then
--         return nil, exit_reason, exit_code
--     end

--     return output

-- end

-- -- Run the kubectl command and capture the output
-- local kubectlCommand = "kubectl get cloneset -o yaml"
-- local yamlOutput, _, exitCode = captureCommandOutput(kubectlCommand)
-- --- print(yamlOutput)

-- -- Check if the command execution was successful
-- if yamlOutput then
--     -- Load the YAML output into a Lua table
--     local lyaml = require("lyaml")
--     local obj = lyaml.load(yamlOutput)

-- --    print(obj.items[1].status.replicas)

--     local hs = {
--         status = "Progressing",
--         message = "Waiting for initialization"
--     }

--     if obj.items[1].status and obj.items[1].metadata.generation == obj.items[1].status.observedGeneration then
--         if obj.items[1].status.updatedAvailableReplicas == obj.items[1].status.replicas then
--             hs.status = "Healthy"
--             hs.message = "All Cloneset workloads are ready and updated"
--         elseif obj.items[1].status.updatedAvailableReplicas ~= obj.items[1].status.replicas then
--             hs.status = "Degraded"
--             hs.message = "Some replicas are not ready or available"
--         end
--     end

--     print("Status:", hs.status)
--     print("Message:", hs.message)

--     if hs.status == "Healthy" then
--         print("Not healthy. Exiting with a non-zero exit code.")
--         os.exit(1, true) -- 1 indicates a non-zero exit code
--     end
--     -- Check if the 'status' field is present
-- else
--     print("Failed to execute kubectl command (Exit code:", exitCode, ")")
-- end

-- Read command-line arguments
-- local kind = arg[1]
-- local namespace = arg[2]

-- -- Load the corresponding module based on the workload type
-- local workloadModule

-- if kind == "cloneset" then
--     workloadModule = require("cloneset")
-- elseif kind == "daemonset" then
--     workloadModule = require("daemonset")
-- else
--     print("Invalid kind. Supported kinds are cloneset and daemonset.")
--     os.exit(1)
-- end

-- -- Capture output and check health
-- local output = workloadModule.captureCommandOutput(namespace)
-- local healthStatus = workloadModule.checkHealth(output)

-- -- Print the health status
-- print("Status:", healthStatus.status)
-- print("Message:", healthStatus.message)

-- -- Exit with the appropriate exit code
-- if healthStatus.status == "Unhealthy" then
--     print("Unhealthy. Exiting with a non-zero exit code.")
--     os.exit(1, true)
-- end


-- Read command-line arguments
-- local args = {...}

-- if #args ~= 2 then
--     print("Invalid command-line arguments. Use the format: lua healthcheck.lua statefulset,daemonset namespace")
--     os.exit(1)
-- end

-- -- Split the combined workload types into individual types
-- local workloadTypes, namespace = string.match(args[1], "([^,]+),([^,]+)")

-- -- Load the corresponding modules for each workload type
-- local workloadModules = {}

-- for kind in string.gmatch(workloadTypes, "[^,]+") do
--     local module

--     if kind == "cloneset" then
--         module = require("cloneset")
--     elseif kind == "daemonset" then
--         module = require("daemonset")
--     else
--         print("Invalid kind. Supported kinds are statefulset and daemonset.")
--         os.exit(1)
--     end

--     table.insert(workloadModules, module)
-- end

-- -- Capture output and check health for each workload type
-- for i, module in ipairs(workloadModules) do
--     local output = module.captureCommandOutput(namespace)
--     local healthStatus = module.checkHealth(output)

--     -- Print the health status for each workload
--     print("Workload Type:", string.match(workloadTypes, "([^,]+)", i))
--     print("Namespace:", namespace)
--     print("Status:", healthStatus.status)
--     print("Message:", healthStatus.message)

--     -- Exit with a non-zero exit code if any workload is unhealthy
--     if healthStatus.status == "Unhealthy" then
--         print("Unhealthy. Exiting with a non-zero exit code.")
--         os.exit(1, true)
--     end
-- end




-- main which i am going to use 
local args = {...}

if #args % 2 ~= 0 then
    print("Invalid command-line arguments. Use pairs of workload type and namespace.")
    os.exit(1)
end

-- Load the corresponding module for each workload type and namespace
for i = 1, #args, 5 do
    local kind = args[i]
    local namespace = args[i + 1]

    local workloadModule

    if kind == "cloneset" then
        workloadModule = require("cloneset")
    elseif kind == "daemonset" then
        workloadModule = require("daemonset")
    elseif kind == "statefulset" then
        workloadModule = require("statefulset")
    elseif kind == "bcj" or kind == "broadcastjob" then
        workloadModule = require("broadcastjob")
    elseif kind == "acj" or kind == "advancedcronjob" then
        workloadModule = require("advancedcronjob")
    else
        print("Invalid kind. Supported kinds are cloneset,daemonset,statefulset,advancedcronjob(acj) and broadcastjob(bcj).")
        os.exit(1)
    end

    -- Capture output and check health
    local output = workloadModule.captureCommandOutput(namespace)
    local healthStatus = workloadModule.checkHealth(output)

    -- Print the health status for each workload
    print("Workload Type:", kind)
    print("Namespace:", namespace)
    print("Status:", healthStatus.status)
    print("Message:", healthStatus.message)

    -- Exit with the appropriate exit code if any workload is unhealthy
    if healthStatus.status == "Unhealthy" then
        print("Unhealthy. Exiting with a non-zero exit code.")
        os.exit(1, true)
    end
end
