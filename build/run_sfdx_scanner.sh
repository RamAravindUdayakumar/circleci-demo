echo "Installing JDK"
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk

echo "Install SFDX Scanner"
echo 'y' | sfdx plugins:install @salesforce/sfdx-scanner

echo "Running SFDX Scanner"
npx sfdx scanner:run --target "**/default/**" --format "csv" --outfile "sfdxScannerAnalysis.csv" --violations-cause-error