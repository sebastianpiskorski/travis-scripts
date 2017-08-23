#!/bin/bash
# NOTE: this script is executed with Piwik master checked out. After it is run, Piwik master may not be checked out.

SCRIPT_DIR=`dirname $0`

if [ "$TEST_AGAINST_PIWIK_BRANCH" == "" ]; then
    if [ "$TEST_AGAINST_CORE" == "latest_stable" ]; then # test against the latest stable release of piwik core (including betas & release candidates)
        # keeping latest_stable enabled until all plugins successfully migrated
        export TEST_AGAINST_PIWIK_BRANCH=$(git describe --tags `git rev-list --tags --max-count=1`)
        export TEST_AGAINST_PIWIK_BRANCH=`echo $TEST_AGAINST_PIWIK_BRANCH | tr -d ' ' | tr -d '\n'`

        #echo "Testing against 'latest_stable' is no longer supported, please test against 'minimum_required_piwik'."
        #exit 1
    elif [[ "$TEST_AGAINST_CORE" == "minimum_required_piwik" && "$PLUGIN_NAME" != "" ]]; then # test against the minimum required Piwik in the plugin.json file
        export TEST_AGAINST_PIWIK_BRANCH=$(php "$SCRIPT_DIR/get_required_piwik_version.php" $PLUGIN_NAME)

        if ! git rev-parse "$TEST_AGAINST_PIWIK_BRANCH" >/dev/null 2>&1
        then
            echo "Could not find tag '$TEST_AGAINST_PIWIK_BRANCH' specified in plugin.json, testing against master."

            export TEST_AGAINST_PIWIK_BRANCH=master
        fi
    fi
elif [[ "$TEST_AGAINST_PIWIK_BRANCH" == "maximum_supported_piwik" && "$PLUGIN_NAME" != "" ]]; then # test against the maximum supported Piwik in the plugin.json file
    export TEST_AGAINST_PIWIK_BRANCH=$(php "$SCRIPT_DIR/get_required_piwik_version.php" $PLUGIN_NAME "max")

    if ! git rev-parse "$TEST_AGAINST_PIWIK_BRANCH" >/dev/null 2>&1
    then
        echo "Could not find tag '$TEST_AGAINST_PIWIK_BRANCH' specified in plugin.json, testing against master."

        export TEST_AGAINST_PIWIK_BRANCH=master
    fi
fi

echo "Saving travis-scripts from being overwritten by branch checkout"
mv ./tests/travis ../travis-scripts.save

echo "Testing against '$TEST_AGAINST_PIWIK_BRANCH'"

if ! git checkout "$TEST_AGAINST_PIWIK_BRANCH" --force; then
    echo ""
    echo "Failed to checkout $TEST_AGAINST_PIWIK_BRANCH"
    echo "git status:"
    echo ""

    git status

    exit 1
fi
echo "Git status after checkout:"
git status

echo "Initializing submodules"
git submodule init
git submodule update || true

echo "Restoring travis-scripts"
rm -rf ./tests/travis
mv ../travis-scripts.save ./tests/travis
