# PS2AIFileAnalyzer

THIS SOFTWARE IS COVERED BY [THIS DISCLAIMER](https://raw.githubusercontent.com/thedges/Disclaimer/master/disclaimer.txt).

This repo provides a demo LWC component to perform AI prompt analysis on files attached to a record

# Installation
1. Install this repo to your target demo org using the below link.
2. For PS2AIFileAnalyzer component...
   * Assign the "PS2AIFileAnalyzer" perm set to the user(s) that will use this component.
   * Edit a page and find the "PS2 Record Locator" component in the custom LWC component list and drop on your page.
   * Configure the parameters for the component for your environment.

<a href="https://githubsfdeploy.herokuapp.com?owner=thedges&repo=PS2AIFileAnalyzer&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>


# Sample Screenshots

![alt text](./File-Analyzer-1.jpg "PS2AIFileAnalyzer Sample 1")
![alt text](./File-Analyzer-2.jpg "PS2AIFileAnalyzer Sample 2")
![alt text](./File-Analyzer-3.jpg "PS2AIFileAnalyzer Sample 3")
![alt text](./File-Analyzer-4.jpg "PS2AIFileAnalyzer Sample 4")
![alt text](./File-Analyzer-5.jpg "PS2AIFileAnalyzer Sample 5")
![alt text](./File-Analyzer-6.jpg "PS2AIFileAnalyzer Sample 6")

# Configuration

| Parameter | Description |
|-----------|-------------|
| <b>SObject Field For Latitude</b> | SObject field that stores the latitude value |
| <b>SObject Field For Longitude</b> | SObject field that stores the longitude value |
| <b>SObject Field For Full Address</b> | SObject field that stores full address in one value |
| <b>SObject Field For Street</b> | SObject field that stores the street |
| <b>SObject Field For City</b> | SObject field that stores the city |
| <b>SObject Field For State</b> | SObject field that stores the state |
| <b>SObject Field For Postal/Zipcode</b> | SObject field that stores postal code |
| <b>Map Center Latitude</b> | Default latitude for center of map |
| <b>Map Center Longitude</b> | Default longitude for center of map |



