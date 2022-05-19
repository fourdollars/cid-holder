function doGet(e){
  var sheet = SpreadsheetApp.getActiveSheet();
  var data = sheet.getDataRange().getValues();
  var result = '';

  if ('name' in e.parameter) {
    for (var i = 0; i < data.length; i++) {
      if (data[i][1] == e.parameter.name) {
        result += data[i][0] + ' ' + data[i][1] + ' ' + data[i][2] + '\n';
      }
    }
  }
  if ('cid' in e.parameter) {
    for (var i = 0; i < data.length; i++) {
      if (data[i][0] == e.parameter.cid) {
        result += data[i][0] + ' ' + data[i][1] + ' ' + data[i][2] + '\n';
        break;
      }
    }
  }
  return ContentService.createTextOutput(result);
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
  } else {
    sheet.getRange('B'+(found+1)).setValue(name);
    sheet.getRange('C'+(found+1)).setValue(date);
  }
  return ContentService.createTextOutput(cid + ' ' + name + ' ' + date);
}

function handleResponse(e) {
  var json = JSON.stringify(e)
  var textOutput = ContentService.createTextOutput(json);
  return textOutput
}
