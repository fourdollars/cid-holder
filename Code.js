function doGet(e){
  var sheet = SpreadsheetApp.getActiveSheet();
  var data = sheet.getDataRange().getValues();
  var result = [];

  if ('name' in e.parameter) {
    for (var i = 0; i < data.length; i++) {
      if (data[i][1] == e.parameter.name) {
        result.push({
          'cid': data[i][0],
          'name': data[i][1],
          'date': data[i][2]
        });
      }
    }
  }
  if ('cid' in e.parameter) {
    if (e.parameter.cid != 'all') {
      for (var i = 0; i < data.length; i++) {
        if (data[i][0] == e.parameter.cid) {
          result.push({
            'cid': data[i][0],
            'name': data[i][1],
            'date': data[i][2]
          });
          break;
        }
      }
    } else {
      for (var i = 1; i < data.length; i++) {
          result.push({
            'cid': data[i][0],
            'name': data[i][1],
            'date': data[i][2]
          });
      }
    }
  }
  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e){
  var name = null;
  var cid = null;
  if (e.postData.type == 'application/x-www-form-urlencoded') {
    cid = e.parameter.cid;
    oauth_consumer_key = e.parameter.oauth_consumer_key;
    oauth_token = e.parameter.oauth_token;
    oauth_token_secret = e.parameter.oauth_token_secret;
  } else if (e.postData.type == 'application/json') {
    var payload = JSON.parse(e.postData.contents);
    cid = payload.cid;
    oauth_consumer_key = payload.oauth_consumer_key;
    oauth_token = payload.oauth_token;
    oauth_token_secret = payload.oauth_token_secret;
  } else {
    return handleResponse(e);
  }

  var person = get_person(oauth_consumer_key, oauth_token, oauth_token_secret);
  if (validate_membership(person)) {
    name = person.display_name + ' (' + person.name + ')';
  }

  if (!cid || !name) {
    Logger.log('Failed with cid: %s, name: %s', cid, name);
    throw Error("No valid CID or no valid token.");
  }

  var sheet = SpreadsheetApp.getActiveSheet();
  var data = sheet.getDataRange().getValues();
  var found = 0;
  var date = new Date();

  for (var i = 0; i < data.length; i++) {
    if (data[i][0] == cid) {
      found = i;
      break;
    }
  }

  if (found == 0) {
    sheet.appendRow([cid, name, date]);
    sheet.sort(1, false);
  } else {
    sheet.getRange('B'+(found+1)).setValue(name);
    sheet.getRange('C'+(found+1)).setValue(date);
  }

  var result = {
    'cid': cid,
    'name': name,
    'date': date
  }

  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

function handleResponse(e) {
  var json = JSON.stringify(e)
  var textOutput = ContentService.createTextOutput(json).setMimeType(ContentService.MimeType.JSON);
  return textOutput
}

function lp_get_api(url, oauth_consumer_key, oauth_token, oauth_token_secret) {
  var options = {
    'headers': {
      'Authorization': 'OAuth realm="https://api.launchpad.net/",' +
      'oauth_consumer_key="' + oauth_consumer_key + '",' +
      'oauth_signature="&' + oauth_token_secret + '",' +
      'oauth_signature_method="PLAINTEXT",' +
      'oauth_nonce="' + Math.floor(Math.random() * new Date()) +'",' +
      'oauth_timestamp="' + Math.floor(new Date() / 1000) + '",' +
      'oauth_token="' + oauth_token + '",' +
      'oauth_version="1.0"'
    },
  }
  var response = UrlFetchApp.fetch(url, options);
  var result = response.getContentText();
  return JSON.parse(result);
}

function get_person(oauth_consumer_key, oauth_token, oauth_token_secret) {
  return lp_get_api('https://api.launchpad.net/devel/people/+me', oauth_consumer_key, oauth_token, oauth_token_secret);
}

function validate_membership(person) {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    var oauth_consumer_key = scriptProperties.getProperty('oauth_consumer_key');
    var oauth_token = scriptProperties.getProperty('oauth_token');
    var oauth_token_secret = scriptProperties.getProperty('oauth_token_secret');
  } catch (err) {
    Logger.log('Failed with error %s', err.message);
    throw err;
  }
  var payload = lp_get_api(person.memberships_details_collection_link, oauth_consumer_key, oauth_token, oauth_token_secret);
  for (entry of payload.entries) {
    if (entry.team_link == 'https://api.launchpad.net/devel/~canonical') {
      return true;
    }
  }
  return false;
}
