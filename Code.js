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
  }
  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e){
  var name = null;
  var cid = null;

  if (e.postData.type == 'application/x-www-form-urlencoded') {
    name = e.parameter.name;
    cid = e.parameter.cid;
  } else if (e.postData.type == 'application/json') {
    var json = JSON.parse(e.postData.contents);
    name = json.name;
    cid = json.cid;
  } else {
    return handleResponse(e);
  }

  if (!cid || !name) {
    return ContentService.createTextOutput('{}').setMimeType(ContentService.MimeType.JSON);
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
