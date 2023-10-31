local args = {...}

-- Function to parse command-line arguments and return the value of a specified option
local function parseArgument(option)
    for i, arg in ipairs(args) do
        if arg == option and i < #args then
            return args[i + 1]
        end
    end
    return nil
end

-- Check for the -h option for help
if table.concat(args, " "):find("%-h") then
    print("Usage: lua healthcheck.lua [workload types] [namespace] [-t timeout]")
    print("Options:")
    print("-h          Show usage instructions.")
    print("-t timeout  Set the timeout in seconds.")
    print("Workload types: cloneset, daemonset, statefulset, advancedcronjob (acj), broadcastjob (bcj)")
    os.exit(0)
end

-- Ensure that there's at least two arguments (workload types and namespace)
if #args < 2 then
    print("Invalid command-line arguments. Use the format 'workloadType1,workloadType2,... namespace'")
    print("Usage: lua healthcheck.lua [workload types] [namespace] [-t timeout]")
    print("Options:")
    print("-h          Show usage instructions.")
    print("-t timeout  Set the timeout in seconds.")
    print("Workload types: cloneset, daemonset, statefulset, advancedcronjob (acj), broadcastjob (bcj)")
    os.exit(1)
end

-- Extract the workload types and namespace from the arguments
local workloadTypes = table.remove(args, 1)
local namespace = table.remove(args, 1)

-- Parse the -t (timeout) option
local timeout = tonumber(parseArgument("-t")) or 10  -- Default timeout is 10 seconds

local workloadName = parseArgument("-w")

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
    elseif kind == "rollout" then
        workloadModule = require("rollout")
    else
        print("Invalid kind. Supported kinds are cloneset, daemonset, statefulset, advancedcronjob (acj), and broadcastjob (bcj).")
        os.exit(1)
    end

    -- Capture output and check health with the specified timeout
    local healthStatus
    if workloadName then
        healthStatus = workloadModule.checkHealthWithTimeout(namespace,workloadName,timeout)
    else
        healthStatus = workloadModule.checkHealthWithTimeout(namespace,nil,timeout)
    end

    -- Print the health status for each workload
    print("Workload Type:", kind)
    print("Namespace:", namespace)
    print("Status:", healthStatus.status)
    print("Message:", healthStatus.message)
    print("\n")

    -- Exit with the appropriate exit code if any workload is unhealthy
    if healthStatus.status == "Degraded" then
        print("Unhealthy. Exiting with a non-zero exit code.")
        os.exit(1, true)
    end
end
