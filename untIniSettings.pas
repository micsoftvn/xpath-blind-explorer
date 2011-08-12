unit untIniSettings;

interface
uses IniFiles32, SysUtils, untVariables;
procedure LoadSettingsFromIni(fname: string);
procedure SaveSettingsToIni(fname: string);
function ReplaceGlobalKeywords(dataIn:string): string;
function ReplaceCRLF(dataIn:string): string;
function ReplaceCRLFBack(dataIn:string): string;
function Bul2Str(dataIn: boolean): string;
function Str2Bul(dataIn: string): boolean;

implementation
uses untMain;




function ReplaceGlobalKeywords(dataIn:string): string;
var
  l: string;
begin
  rf := [rfReplaceAll];
  l := StringReplace(dataIn, '<temp_dir>', tempDir, rf);
  l := StringReplace(l, '<app_dir>', currentDir + '\', rf);
  result := l;
end;




function ReplaceCRLF(dataIn:string): string;
begin
  rf := [rfReplaceAll];
  result := StringReplace(dataIn, #13#10, '<CR_LF>', rf);
end;



function ReplaceCRLFBack(dataIn:string): string;
begin
  rf := [rfReplaceAll];
  result := StringReplace(dataIn, '<CR_LF>', #13#10, rf);
end;



function Bul2Str(dataIn: boolean): string;
begin
  if dataIn = true then result := 'true' else result := 'false';
end;


function Str2Bul(dataIn: string): boolean;
begin
  if dataIn = 'true' then result := true else result := false;
end;



//--------------------------------------------------------load settings from INI

procedure LoadSettingsFromIni(fname: string);
var myIni: TIniFile32;
  sectionName: string;
begin
  myIni := TIniFile32.Create(fname);
  with myIni do
  begin
    sectionName := 'settings';
    with frmMain do
    begin
      memCharset.Text := ReplaceCRLFBack(readString(sectionName, 'charset', ''));
      SetCondition(readString(sectionName, 'condition', 'true'));
      edtKeywordTrue.Text := readString(sectionName, 'keyword_true', '');
      edtKeywordFalse.Text := readString(sectionName, 'keyword_false', '');

      edtURL.Text := readString(sectionName, 'url', '');

      SetRequestType(readString(sectionName, 'request_type', 'get'));

      memPostParameters.Text := ReplaceCRLFBack(readString(sectionName, 'post_parameters', ''));

      edtProxyServerIP.Text := readString(sectionName, 'proxy_server_ip', '127.0.0.1');
      edtProxyServerPort.Text := readString(sectionName, 'proxy_server_port', '8080');
      useProxy(readString(sectionName, 'proxy_in_use', 'false'), true);

      curlInUse(readString(sectionName, 'curl_in_use', 'false'));

      memCustomHTTPHeader.Text := ReplaceCRLFBack(readString(sectionName, 'custom_http_header', ''));
      CustomHTTPHeaderInUse(readString(sectionName, 'custom_http_header_in_use', ''), true);

      SetExploitationType(readString(sectionName, 'exploitation_type', 'string-based'));

      chkOptExtractNodeValues.Checked := Str2Bul(readString(sectionName, 'extract_node_value', 'true'));
      chkOptExtractAttributes.Checked := Str2Bul(readString(sectionName, 'extract_attributes', 'true'));
      chkOptExtractComments.Checked := Str2Bul(readString(sectionName, 'extract_comments', 'true'));
    end;

    //--- advanced params (read only)
    sectionName := 'advanced_settings';
    adv_test_payload_condition_true := readString(sectionName, 'test_payload_condition_true', '');
    adv_test_payload_condition_false := readString(sectionName, 'test_payload_condition_false', '');

    adv_max_child_nodes_to_search := readInteger(sectionName, 'max_child_nodes_to_search', 20);

    adv_payload_nr_of_child_nodes := readString(sectionName, 'payload_nr_of_child_nodes', '');

    adv_max_nodename_length := readInteger(sectionName, 'max_nodename_length', 20);

    adv_payload_get_nodename_length := readString(sectionName, 'payload_get_nodename_length', '');
    adv_payload_get_nodename := readString(sectionName, 'payload_get_nodename', '');

    adv_max_nodevalue_length := readInteger(sectionName, 'max_nodevalue_length', 20);

    adv_payload_get_nodevalue_length := readString(sectionName, 'payload_get_nodevalue_length', '');
    adv_payload_get_nodevalue := readString(sectionName, 'payload_get_nodevalue', '');

    Free;
  end;
end;




//--------------------------------------------------------save settings from INI

procedure SaveSettingsToIni(fname: string);
var myIni: TIniFile32;
  sectionName: string;
begin
  myIni := TIniFile32.Create(fname);
  with myIni do
  begin
    sectionName := 'settings';
    with frmMain do
    begin
       writeString(sectionName, 'charset', ReplaceCRLF(memCharset.Text));
       writeString(sectionName, 'condition', GetCondition);
       writeString(sectionName, 'keyword_true', edtKeywordTrue.Text);
       writeString(sectionName, 'keyword_false', edtKeywordFalse.Text);

       writeString(sectionName, 'url', edtURL.Text);

       writeString(sectionName, 'request_type', GetRequestType);

       writeString(sectionName, 'post_parameters', ReplaceCRLF(memPostParameters.Text));

       writeString(sectionName, 'proxy_server_ip', edtProxyServerIP.Text);
       writeString(sectionName, 'proxy_server_port', edtProxyServerPort.Text);
       writeString(sectionName, 'proxy_in_use', GetProxyInUse);

       writeString(sectionName, 'curl_in_use', GetCurlInUse);

       writeString(sectionName, 'custom_http_header', ReplaceCRLF(memCustomHTTPHeader.Text));
       writeString(sectionName, 'custom_http_header_in_use', GetCustomHTTPHeaderInUse);

       writeString(sectionName, 'exploitation_type', GetExploitationType);

       writeString(sectionName, 'extract_node_value', Bul2Str(chkOptExtractNodeValues.Checked));
       writeString(sectionName, 'extract_attributes', Bul2Str(chkOptExtractAttributes.Checked));
       writeString(sectionName, 'extract_comments', Bul2Str(chkOptExtractComments.Checked));
    end;
    Free;
  end;
end;





end.

