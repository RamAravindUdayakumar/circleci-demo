echo "Installing JDK"
sudo apt-get update --allow-releaseinfo-change || sudo apt-get update
sudo apt-get install -y --fix-missing openjdk-11-jdk

echo "Install SFDX Scanner"
echo 'y' | sfdx plugins:install @salesforce/sfdx-scanner

echo "Running SFDX Scanner"
sfdx scanner:run --target "**/default/**" --format "csv" --outfile "sfdxScannerAnalysis.csv" --severity-threshold 3