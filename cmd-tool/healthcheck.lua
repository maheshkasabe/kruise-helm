local args = {...}

if table.concat(args, " "):find("%-h") then
    print("Usage: lua healthcheck.lua [workload types] [namespace]")
    print("Options:")
    print("-h          Show usage instructions.")
    print("Workload types: cloneset, daemonset, statefulset, advancedcronjob (acj), broadcastjob (bcj)")
    os.exit(0)
end
-- Ensure that there's at least one argument
if #args < 2 then
    print("Invalid command-line arguments. Use the format 'workloadType1,workloadType2,... namespace'")
    print("Usage: lua healthcheck.lua [workload types] [namespace]")
    print("Options:")
    print("-h          Show usage instructions.")
    print("Workload types: cloneset, daemonset, statefulset, advancedcronjob (acj), broadcastjob (bcj)")
    os.exit(1)
end

-- Extract the workload types and namespace from the arguments
local workloadTypes = table.remove(args, 1)
local namespace = table.remove(args, 1)

-- Split the workload types using a comma and iterate over them
for kind in string.gmatch(workloadTypes, "[^,]+") do
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
        print("Invalid kind. Supported kinds are cloneset, daemonset, statefulset, advancedcronjob (acj), and broadcastjob (bcj).")
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
    if healthStatus.status == "Degraded" then
        print("Unhealthy. Exiting with a non-zero exit code.")
        os.exit(1, true)
    end
end
