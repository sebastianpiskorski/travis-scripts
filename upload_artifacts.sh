#!/bin/bash

sudo apt-get -y install sshpass
sudo apt-get -y install rsync

function upload_screenshots_group {
    CURRENT_SCREENSHOT_DIR_NAME=$1
    if [ -d ./"$CURRENT_SCREENSHOT_DIR_NAME" ]; then
        echo ""
        echo "[NOTE] Processing Screenshots from $CURRENT_SCREENSHOT_DIR_NAME:"
        ls $CURRENT_SCREENSHOT_DIR_NAME
        ARCHIVE_NAME="$TRAVIS_BUILD_NUMBER".tar.bz2

        echo "$RELATIVE_REPO_PATH/$CURRENT_SCREENSHOT_DIR_NAME"
        cp -r $CURRENT_SCREENSHOT_DIR_NAME $RELATIVE_REPO_PATH
    fi
}

function copy_diffviewer {
    cp -r $PIWIK_ROOT_DIR/tests/UI/screenshot-diffs/* $PIWIK_ROOT_DIR/$UI_TESTS_PATH/screenshot-diffs
}

function archive_and_upload_artifacts {
    ARCHIVE_NAME=${TRAVIS_REPO_SLUG/PiwikPRO\//}_${TRAVIS_BUILD_NUMBER}.tar.bz2
    CURRENT_DIR=`pwd`

    cd $RELATIVE_REPO_PATH
    tar -cjf $ARCHIVE_NAME * --exclude='.gitkeep'
    cd $CURRENT_DIR

    echo "Uploading Screenshots..."
    sshpass -e rsync -arROe "ssh -o StrictHostKeyChecking=no" "$RELATIVE_REPO_PATH" artifacts@builds-artifacts.piwik.pro:/var/www/artifacts/
}

if [ ! $ARTIFACTS_PASS ]; then
    echo "[WARNING] ARTIFACTS_PASS not set! Set proper variable at https://travis-ci.com/$TRAVIS_REPO_SLUG/settings/"
    exit
fi
export SSHPASS=$ARTIFACTS_PASS

if [ "$TEST_SUITE" = "SystemTests" ];
then
    echo "Uploading artifacts for $TEST_SUITE..."

    cd ./tests/PHPUnit/System
    export RELATIVE_REPO_PATH="$TRAVIS_REPO_SLUG"/"$TRAVIS_BRANCH"/"$TRAVIS_BUILD_NUMBER"/"SystemTests"

    upload_screenshots_group "expected"
    upload_screenshots_group "processed"
else
    if [ "$TEST_SUITE" = "UITests" ];
    then
        echo "Uploading artifacts for $TEST_SUITE..."

        if [ -n "$PLUGIN_NAME" ];
        then
            if [ -d "./plugins/$PLUGIN_NAME/Test/UI" ]; then
                export UI_TESTS_PATH="plugins/$PLUGIN_NAME/Test/UI"
            else
                export UI_TESTS_PATH="plugins/$PLUGIN_NAME/tests/UI"
            fi
        else
            export UI_TESTS_PATH='tests/UI'
        fi

        cd ./$UI_TESTS_PATH

        echo "[NOTE] Current path:"
        echo `pwd`

        export RELATIVE_REPO_PATH="$TRAVIS_REPO_SLUG"/"$TRAVIS_BRANCH"/"$TRAVIS_BUILD_NUMBER"/"UiTests"
        mkdir -p $RELATIVE_REPO_PATH

        upload_screenshots_group "expected-ui-screenshots"
        upload_screenshots_group "processed-ui-screenshots"
        copy_diffviewer
        upload_screenshots_group "screenshot-diffs"

        archive_and_upload_artifacts
    else
        echo "No artifacts for $TEST_SUITE tests."
        exit
    fi
fi
