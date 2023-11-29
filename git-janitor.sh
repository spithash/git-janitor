#!/bin/bash

# Execute git with sudo if needed
sudo_git_command() {
    local command="$1"
    local directory="$2"
    local use_sudo="$3"

    if [ "$use_sudo" = true ]; then
        read -rsp "Enter sudo password for $directory: " password
        echo
        cmd=("cd" "$directory" "&&" "$command")
        sudo -S bash -c "${cmd[*]}" <<< "$password"
    else
        $command
    fi
}

# Check if a Git repository is up to date
is_repo_up_to_date() {
    local directory="$1"

    # Check if there are changes without actually updating the local branches
    fetch_dry_run_output=$(sudo_git_command "git -C $directory fetch --dry-run" "$directory" false)

    # Add debugging output
    echo "Debug - Fetch dry-run output for $directory: $fetch_dry_run_output"

    # Check if the fetch dry-run output indicates that there are no changes
    if [[ "$fetch_dry_run_output" == *"Already up to date."* ]]; then
        return 0
    else
        return 1
    fi
}

# Local Git repositories (you SHOULD change these)
# Add true if it requires sudo and false if otherwise
update_git_repos() {
    local repo_directories=(
        "/usr/share/coreruleset true"
        "/home/spithash/.bash-git-prompt/ false"
        "/home/spithash/Documents/scripts/blacklist-scripts/ false"
        "/home/spithash/.tmux/plugins/tpm false"
        "/home/spithash/MySQLTuner-perl false"
        "/home/spithash/.nvm/ false"
        "/home/spithash/Documents/deleteme/custom-conf-files false"
    )

    updated_repos=()
    already_up_to_date=()
    failed_repos=()

    for repo in "${repo_directories[@]}"; do
        directory="${repo% *}"
        use_sudo="${repo#* }"

        if is_repo_up_to_date "$directory"; then
            already_up_to_date+=("$directory")
        else
            # There are changes, proceed with the actual update
            pull_result=$(sudo_git_command "git -C $directory pull" "$directory" "$use_sudo")
            return_code=$?

            # Add debugging output
            echo "Debug - Show branch output for $directory: $pull_result"

            if [[ "$pull_result" == *"Already up to date."* ]]; then
                already_up_to_date+=("$directory")
            elif [ $return_code -eq 0 ]; then
                updated_repos+=("$directory")
            else
                failed_repos+=("$directory")
            fi
        fi
    done

    echo "Summary:"
    echo -e "\033[0;32mUpdated Repositories:\033[0m (${#updated_repos[@]})"
    for repo in "${updated_repos[@]}"; do
        echo "- $repo"
    done

    echo -e "\n\033[0;33mAlready Up to Date Repositories:\033[0m (${#already_up_to_date[@]})"
    for repo in "${already_up_to_date[@]}"; do
        echo "- $repo"
    done

    echo -e "\n\033[0;31mFailed Repositories:\033[0m (${#failed_repos[@]})"
    for repo in "${failed_repos[@]}"; do
        echo "- $repo"
    done
}

update_git_repos

