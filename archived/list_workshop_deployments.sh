#!/bin/bash

ecctl deployment list --output json | jq '.deployments[] | { id: .id, name: .name, region: .resources[0].region }'
