#!/usr/bin/env bash

set -e

echo "POST BUILD SCRIPT START"

cd "$APPCENTER_SOURCE_DIRECTORY"

# Read settings from taito-config.sh
set -a
taito_target_env=${APPCENTER_BRANCH/master/prod}
. taito-config.sh
set +a

[[ $APPCENTER_XCODE_PROJECT == *"$appcenter_app"* ]] && TYPE=iOS || TYPE=Android

ORG=$appcenter_org
APP=$appcenter_app
SLACK_WEBHOOK=$taito_messaging_webhook
ICON=$taito_project_icon

build_url=https://appcenter.ms/orgs/$ORG/apps/$APP-$TYPE/build/branches/$APPCENTER_BRANCH/builds/$APPCENTER_BUILD_ID
build_link="<$build_url|$APP $APPCENTER_BRANCH #$APPCENTER_BUILD_ID>"

slack_notify() {
  curl -X POST --data-urlencode \
    "payload={
      \"channel\": \"$1\",
      \"username\": \"App Center\",
      \"text\": \"$2\",
      \"icon_url\": \"$ICON\" \
    }" \
    $SLACK_WEBHOOK
}

slack_notify_prod_build_passed() {
  slack_notify "#$taito_messaging_channel" "✓ $build_link built. App is ready for store distribution :shipit_parrot:"
}

slack_notify_build_failed() {
  slack_notify "#$taito_messaging_channel" "💥 $build_link build failed."
  slack_notify "#$taito_messaging_builds_channel" "💥 $build_link build failed."
}

if [ "$AGENT_JOBSTATUS" != "Succeeded" ]; then
  slack_notify_build_failed
  exit 0
else
  if [ "$APPCENTER_BRANCH" == "master" ]; then
    slack_notify_prod_build_passed
  fi
fi

echo "POST BUILD SCRIPT END"
