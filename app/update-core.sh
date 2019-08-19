#!/usr/bin/env bash

update_core_handle()
{
	update_core_resolve_vars

	update_core_add_upstream_remote || true

	update_core_merge_from_upstream || true

	update_core_resolve_conflicts

	heading "Applying migration updates..."

	update_core_change_block_reward_from_number_to_string

	# update_core_check_bridgechain_version

	# heading "Bridgechain version: $CHAIN_VERSION"
	# read -p "Would you like to update Core to version "$UPSTREAM_VERSION"? [y/N]: " choice

	# if [[ "$choice" =~ ^(yes|y|Y) ]]; then
	#     choice=""
	#     while [[ ! "$choice" =~ ^(yes|y|Y) ]] ; do

	#     	update_core_add_upstream_remote

	#     	update_core_merge_from_upstream

	#     	update_core_resolve_conflicts

	#     	update_core_change_block_reward_from_number_to_string

	#         # read -p "Proceed? [y/N]: " choice
	#     done
	# fi

	# cd $BRIDGECHAIN_PATH
	# git checkout -b update/"$UPSTREAM_VERSION"
	# git merge upstream/master

	# update_core_resolve_conflicts
	# update_core_change_block_reward_from_number_to_string
	# update_core_update_package_json

	# git add --all
	# git commit --no-verify -m 'chore: upgrade bridgechain'
	# git push --no-verify

}

update_core_resolve_vars()
{
	UPSTREAM_VERSION=$(curl -s https://raw.githubusercontent.com/ArkEcosystem/core/master/packages/core/package.json | jq -r '.version')
	CHAIN_VERSION=$(jq -r '.version' $HOME/core-bridgechain/packages/core/package.json)
}

update_core_check_bridgechain_version()
{
	heading "Bridgechain version: $CHAIN_VERSION"
	read -p "Would you like to update Core to version "$UPSTREAM_VERSION"? [y/N]: " choice

	if [[ "$choice" =~ ^(yes|y|Y) ]]; then
	    choice=""
	    while [[ ! "$choice" =~ ^(yes|y|Y) ]] ; do
	    	#
	        read -p "Proceed? [y/N]: " choice
	    done
	fi
	info "Done"
}

update_core_add_upstream_remote()
{
	heading "Fetching from upstream..."
	cd $HOME/core-bridgechain
	git remote add upstream https://github.com/ArkEcosystem/core.git > /dev/null 2>&1
	git fetch upstream
}

update_core_merge_from_upstream()
{
	heading "Merging from upstream..."
	git checkout -b update/"$UPSTREAM_VERSION"
	git merge upstream/master
	info "Done"
}


update_core_resolve_conflicts()
{
	heading "Resolving merge conflicts..."
	git checkout --ours packages/crypto/src/networks/devnet/genesisBlock.json
	git checkout --ours packages/crypto/src/networks/devnet/milestones.json
	git checkout --ours packages/crypto/src/networks/mainnet/exceptions.json
	git checkout --ours packages/crypto/src/networks/mainnet/genesisBlock.json
	git checkout --ours packages/crypto/src/networks/mainnet/milestones.json
	git checkout --ours packages/crypto/src/networks/testnet/genesisBlock.json
	git checkout --ours packages/crypto/src/networks/testnet/milestones.json
	git checkout --theirs packages/core/bin/config/mainnet/plugins.js
	git checkout --theirs packages/core/bin/config/testnet/plugins.js
	git checkout --ours install.sh
	info "Done"
}

update_core_change_block_reward_from_number_to_string()
{
	tmp=$(mktemp)
	jq '.reward = "0"' packages/crypto/src/networks/mainnet/genesisBlock.json > "$tmp" && mv "$tmp" packages/crypto/src/networks/mainnet/genesisBlock.json
	tmp=$(mktemp)
	jq '.reward = "0"' packages/crypto/src/networks/devnet/genesisBlock.json > "$tmp" && mv "$tmp" packages/crypto/src/networks/devnet/genesisBlock.json
	tmp=$(mktemp)
	jq '.reward = "0"' packages/crypto/src/networks/testnet/genesisBlock.json > "$tmp" && mv "$tmp" packages/crypto/src/networks/testnet/genesisBlock.json
}

update_core_update_package_json()
{
	oldPackageJson=$(mktemp)
	git checkout --ours packages/core/package.json && cat packages/core/package.json > "$oldPackageJson" && git checkout --theirs packages/core/package.json

	tmp=$(mktemp)
	jq --arg var "$(jq -r '.name' "$oldPackageJson")" '.name = $var' packages/core/package.json > "$tmp" && mv "$tmp" packages/core/package.json

	tmp=$(mktemp)
	jq --argjson bin "$(jq -r '.bin' "$oldPackageJson")" '.scripts += $bin' packages/core/package.json > "$tmp" && mv "$tmp" packages/core/package.json

	tmp=$(mktemp)
	jq --arg var "$(jq -r '.description' "$oldPackageJson")" '.description = $var' packages/core/package.json > "$tmp" && mv "$tmp" packages/core/package.json

	tmp=$(mktemp)
	jq --argjson var "$(jq -r '.bin' "$oldPackageJson")" '.bin = $var' packages/core/package.json > "$tmp" && mv "$tmp" packages/core/package.json

	tmp=$(mktemp)
	jq --arg var "$(jq -r '.bin' "$oldPackageJson")" '.scripts = $var' packages/core/package.json > "$tmp" && mv "$tmp" packages/core/package.json

	tmp=$(mktemp)
	jq --arg var "$(jq -r '.oclif.bin' "$oldPackageJson")" '.oclif.bin = $var' packages/core/package.json > "$tmp" && mv "$tmp" packages/core/package.json
}
