#!/bin/bash

# Variables
organization=$1
pat=$2
startdate=$3
enddate=$4
verbose=$5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if all parameters are provided
if [ $# -ne 5 ]; then
    echo -e "${RED}Usage: $0 <organization> <personal_access_token> <startdate> <enddate> <verbose>${NC}"
    echo -e "Example: $0 myorg mypat 2025-01-01 2025-1-31 DEBUG"
    exit 1
fi

# Fetch all projects
projects=$(curl -s -u :$pat -X GET "https://dev.azure.com/$organization/_apis/projects?api-version=7.1" | jq -r '.value[].name')

echo -e "${GREEN}Projects: ${NC}"
echo -e "${GREEN} ----------------------------------- ${NC}"
echo -e "${GREEN} $projects${NC}"
echo -e "${GREEN} ----------------------------------- ${NC}"
# Initialize total duration
total_duration=0

# Loop through each project and fetch the total duration
for project in $projects; do
    echo -e "${YELLOW}Fetching total duration for project $project${NC}"
    projectDuration=0
    # get pipelines
    pipelinesIds=$(curl -s -u :$pat -X GET "https://dev.azure.com/$organization/$project/_apis/pipelines?api-version=7.1" | jq -r '.value[].id')
    # get runs duration for each pipeline
    for pipelineId in $pipelinesIds; do
        # calculate duration for each run and sum them
        runs=$(curl -s -u :$pat -X GET "https://dev.azure.com/$organization/$project/_apis/pipelines/$pipelineId/runs?api-version=7.1" | jq -r '.value[] | {createdDate: .createdDate, finishedDate: .finishedDate}')
        for run in $(echo "${runs}" | jq -c '.'); do
            createdDate=$(echo $run | jq -r '.createdDate')
            finishedDate=$(echo $run | jq -r '.finishedDate')
            
            # Skip run if createdDate is not within start and end date
            if [[ "$createdDate" < "$startdate" || "$createdDate" > "$enddate" ]]; then
            continue
            fi
            duration=$(( $(date -d $finishedDate +%s) - $(date -d $createdDate +%s) ))
            if [ "$verbose" == "DEBUG" ]; then
                echo "Pipeline: $pipelineId, Run: $run, Duration: $duration"
            fi
            projectDuration=$(( $projectDuration + $duration ))
            total_duration=$(( $total_duration + $duration ))
        done
    done
    echo -e "${GREEN}Total duration in seconds for project $project: $projectDuration${NC}"
done

# Print the total duration for all projects
echo -e "${BLUE}Total duration in seconds for all projects: $total_duration${NC}"
