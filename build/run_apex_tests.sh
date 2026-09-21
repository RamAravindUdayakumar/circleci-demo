# Authenticate to salesforce
#echo "Authenticating..."
#sfdx force:auth:jwt:grant --clientid $APP_KEY --jwtkeyfile keys/server.key --username $SF_USERNAME --setdefaultdevhubusername -a DevHub

#Create a scratch org
#echo "Creating the Scratch Org..."
#sfdx force:org:create -f config/project-scratch-def.json -a ${CIRCLE_BRANCH} -s

#sfdx force:source:push -u ${CIRCLE_BRANCH}

#echo "Coverting source to metadata format"
#sfdx force:source:convert -d test_code -r force-app

#echo "Deploying code to org"
#sfdx force:mdapi:deploy --checkonly -u DevHub -d test_code/ -w -1 -l RunLocalTests

#echo "Deploying source to org"
#sf project deploy start --source-dir force-app --target-org DevHub

#echo "Testing code in org"
#sf apex run test --test-level RunLocalTests --output-dir test-results --result-format tap --target-org DevHub

set -eo pipefail

echo "Validating code and executing local tests against DevHub..."
sf project deploy validate \
  --source-dir force-app \
  --target-org DevHub \
  --test-level RunLocalTests \
  --wait 30