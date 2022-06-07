# CID Holder

A Flutter webapp project that scans the QR codes of `https://ubuntu.com/certified/<CID>` or `https://certification.canonical.com/hardware/<CID>/` and then updates the data in Google Spreadsheet via Google Apps Script (checking Code.js in this repo) after the authorization via [Launchpad API](https://api.launchpad.net/).

Ex. https://ubuntu.com/certified/202112-29761 (public) or https://certification.canonical.com/hardware/202112-29761/ (private)
