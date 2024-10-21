#!/bin/bash

# Set your repository name (e.g., owner/repo)
REPO="M4nihere/groovio-admin"

# Load the JSON file
json_file="secrets.json"

# Check if the JSON file exists
if [[ ! -f "$json_file" ]]; then
    echo "JSON file not found: $json_file"
    exit 1
fi

# Function to set secret with retry logic
set_secret_with_retry() {
    local key="$1"
    local value="$2"
    local attempts=5  # Number of retry attempts
    local delay=2     # Delay between attempts in seconds

    for ((i=1; i<=attempts; i++)); do
        echo "Attempt $i to update secret: $key"
        gh secret set "$key" --repo "$REPO" --body "$value"

        if [[ $? -eq 0 ]]; then
            echo "Successfully updated secret: $key"
            return 0  # Exit function on success
        fi

        echo "Failed to set secret: $key. Retrying in $delay seconds..."
        sleep $delay  # Wait before retrying
    done

    echo "Error: Failed to set secret '$key' after $attempts attempts."
    return 1  # Exit function on failure after retries
}

# Iterate through each key-value pair in the JSON file
for key in $(jq -r 'keys[]' "$json_file"); do
    # Extract value and handle special characters
    value=$(jq -r --arg k "$key" '.[$k] | @sh' "$json_file")

    # Debugging output
    echo "Key: '$key'"
    echo "Extracted Value: $value"  # Show the extracted value

    # Check if value is empty
    if [[ "$value" == "''" ]]; then  # Check for empty string from jq
        echo "Warning: The value for '$key' is empty."
        continue  # Skip to the next iteration if the value is empty
    fi

    # Update the secret in GitHub
    echo "Updating secret: $key"

    # Remove surrounding single quotes from value for setting the secret
    clean_value=$(echo $value | sed "s/^'//;s/'$//")

    echo "Value being set: $clean_value"  # Show actual value being set

    # Set the secret using retry logic
    set_secret_with_retry "$key" "$clean_value"

    # Pause for 2 seconds between each secret update (can be adjusted)
    sleep 2
done

echo "All secrets updated successfully."
