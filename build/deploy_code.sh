echo "Deploying code to org"
sf project deploy start \
  --source-dir force-app \
  --target-org DevHub \
  --test-level RunSpecifiedTests --tests "AccpunthandlerTest" \
  --wait 30