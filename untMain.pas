unit untMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untVariables, untIniSettings, untGenericProcedures, ComCtrls, Clipbrd,
  untLog, StdCtrls, untFileVersion, Menus, ExtCtrls, untCURL, IdHTTP, IdIOHandlerStack,
  IdStackConsts, idWinsock2, LMDCustomComponent, LMDStarter, Buttons, Htmlview, shellAPI;

type
  TfrmMain = class(TForm)
    StatusBar: TStatusBar;
    tmrStarup: TTimer;
    LMDS: TLMDStarter;
    PageControl: TPageControl;
    tabExploitation: TTabSheet;
    grpSimple: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    Label5: TLabel;
    labResultOfTheTest: TLabel;
    edtURL: TEdit;
    radGetRequest: TRadioButton;
    radPostRequest: TRadioButton;
    memPostParameters: TMemo;
    btnTestConditionTrue: TButton;
    btnTestConditionFalse: TButton;
    btnGetXML: TButton;
    grpResults: TGroupBox;
    memResults: TMemo;
    tabOptions: TTabSheet;
    grpOptions: TGroupBox;
    Label1: TLabel;
    memCharset: TMemo;
    chkUseCURL: TCheckBox;
    pnlKeywords: TPanel;
    edtKeywordTrue: TEdit;
    radConditionTrue: TRadioButton;
    radConditionFalse: TRadioButton;
    edtKeywordFalse: TEdit;
    chkUseProxy: TCheckBox;
    Label6: TLabel;
    edtProxyServerIP: TEdit;
    Label7: TLabel;
    edtProxyServerPort: TEdit;
    grpCustomHeader: TGroupBox;
    chkUseCustomHTTPHeader: TCheckBox;
    memCustomHTTPHeader: TMemo;
    tabAbout: TTabSheet;
    btnCopyToClipboard: TSpeedButton;
    btnSaveToFile: TSpeedButton;
    tmrUpdateProxy: TTimer;
    dlgSave: TSaveDialog;
    HTMLViewer: THTMLViewer;
    Label8: TLabel;
    pnlExploitationType: TPanel;
    radStringBasedExploit: TRadioButton;
    radIntegerBasedExploit: TRadioButton;
    grpDataExtractionOptions: TGroupBox;
    chkOptExtractAttributes: TCheckBox;
    chkOptExtractComments: TCheckBox;
    chkOptExtractNodeValues: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure radConditionTrueClick(Sender: TObject);
    procedure radConditionFalseClick(Sender: TObject);
    procedure radGetRequestClick(Sender: TObject);
    procedure radPostRequestClick(Sender: TObject);
    procedure tmrStarupTimer(Sender: TObject);
    procedure btnTestConditionTrueClick(Sender: TObject);
    procedure btnTestConditionFalseClick(Sender: TObject);
    procedure Getnumberofrootnodes1Click(Sender: TObject);
    procedure btnGetXMLClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure chkUseProxyClick(Sender: TObject);
    procedure edtProxyServerIPChange(Sender: TObject);
    procedure edtProxyServerPortChange(Sender: TObject);
    procedure tmrUpdateProxyTimer(Sender: TObject);
    procedure chkUseCustomHTTPHeaderClick(Sender: TObject);
    procedure btnSaveToFileClick(Sender: TObject);
    procedure btnCopyToClipboardClick(Sender: TObject);
    procedure HTMLViewerHotSpotClick(Sender: TObject; const SRC: string;
      var Handled: Boolean);
  private
    { Private declarations }
  public
    procedure SetCondition(param: string);
    function GetCondition: string;
    procedure SetRequestType(param: string);
    function GetRequestType: string;
    procedure useProxy(param: string; param2: boolean);
    function GetProxyInUse: string;
    procedure curlInUse(param: string);
    function GetCurlInUse: string;
    procedure CustomHTTPHeaderInUse(param: string; param2: boolean);
    function GetCustomHTTPHeaderInUse: string;
    procedure SetExploitationType(param: string);
    function GetExploitationType: string;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}
{$R resources.RES}

//---------------------------------------------------------on the very beginning

procedure TfrmMain.FormCreate(Sender: TObject);
var
  mySettings: string;
  rs: TResourceStream;
begin
  Randomize;

  //-------- initialize dirs
  currentDir := ExtractFileDir(paramstr(0));
  currentIniSettingsFileName := currentDir + '\' + iniSettingsFileName;
  currentLogFileName := currentDir + '\' + logFileName;

  Application.Title := 'XPath Blind Explorer (ver.: ' + strBuildInfo + ')';
  caption := Application.Title;

  //-------- start log file
  logOptions := ''; //---can be: [empty], file, file-rewite, screen, both, both-rewrite
  LogInint;
  Log('Application started');

  //-------- enable double-buffering for win controls (remember: TRichEdit is exclusion, so dbl-buff should be switched off for it!)
  EnableDoubleBuffering(frmMain, true);

  dlgSave.InitialDir := currentDir;

  myClip := TClipboard.Create;

  pageControl.TabIndex := 0;  

  //-------- load settings form INI
  if paramstr(1) = '' then mySettings := currentIniSettingsFileName else mySettings := paramstr(1);
  if fileexists(mySettings) then LoadSettingsFromIni(mySettings) else
  begin
    application.MessageBox('Where is config file, may I ask you?...', 'Error', MB_OK);
    application.ShowMainForm := false;
    application.Terminate;
  end;

  batchFile := currentDir + '\tmp\run.cmd';
  resultFile := currentDir + '\tmp\result.htm';
  tempCurlConfig := currentDir + '\tmp\curl.tmp_config';
  sourceHTTPHeader := currentDir + '\curl.default_config';
  curlExe := currentDir + '\curl.exe';

  forceDirectories(currentDir + '\tmp');
  createBatchFile;

  global_stop := true;

  labResultOfTheTest.Caption := '';

  //--- load texts from resources
  rs := TResourceStream.Create(hInstance, PChar('license'), RT_RCDATA);
  HTMLViewer.LoadFromStream(rs, '');

  myLoader := TIdHTTP.Create(nil); //--- initialize loader
 
end;





//-----------------------------------------------------------------startup timer
procedure TfrmMain.tmrStarupTimer(Sender: TObject);
begin
  tmrStarup.Enabled := false;
  btnGetXML.SetFocus;
end;




//------------------------------------------------------------------update proxy
procedure TfrmMain.edtProxyServerIPChange(Sender: TObject);
begin
  tmrUpdateproxy.Enabled := true;
end;

procedure TfrmMain.edtProxyServerPortChange(Sender: TObject);
begin
  tmrUpdateproxy.Enabled := true;
end;

procedure TfrmMain.tmrUpdateProxyTimer(Sender: TObject);
begin
  tmrUpdateProxy.Enabled := false;
  if frmMain.chkUseProxy.Checked = true then
  begin
    myLoader.ProxyParams.ProxyServer := frmMain.edtProxyServerIP.Text;
    myLoader.ProxyParams.ProxyPort := strToInt(frmMain.edtProxyServerPort.Text);
  end else
  begin
    myLoader.ProxyParams.ProxyServer := '';
    myLoader.ProxyParams.ProxyPort := 0;
  end;
end;





//----------------------------set exploitation type (string or integer -  based)
procedure TfrmMain.SetExploitationType(param: string);
begin
  if param = 'string-based' then //--- condition "string-based" enabled
  begin
    radStringBasedExploit.Checked := true;
  end else

  if param = 'integer-based' then //--- condition "integer-based" enabled
  begin
    radIntegerBasedExploit.Checked := true;
  end;
end;





//----------------------------get exploitation type (string or integer -  based)
function TfrmMain.GetExploitationType: string;
begin
  if radStringBasedExploit.Checked = true then result := 'string-based'
  else if radIntegerBasedExploit.Checked = true then result := 'integer-based';
end;





//---------------------------------switch on/off custom HTTP header (true/false)
procedure TfrmMain.CustomHTTPHeaderInUse(param: string; param2: boolean);
begin
  if param = 'true' then //--- condition "true" enabled
  begin
    if param2 = true then chkUseCustomHTTPHeader.Checked := true;

    memCustomHTTPHeader.Enabled := true;
    memCustomHTTPHeader.Color := clWhite;
  end else

  if param = 'false' then //--- condition "false" enabled
  begin
    if param2 = true then chkUseCustomHTTPHeader.Checked := false;

    memCustomHTTPHeader.Enabled := false;
    memCustomHTTPHeader.Color := clBtnFace;
  end;
end;





//---------------------------------------get status of custom HTTP header switch
function TfrmMain.GetCustomHTTPHeaderInUse: string;
begin
  if chkUseCustomHTTPHeader.Checked = true then result := 'true'
  else if chkUseCustomHTTPHeader.Checked = false then result := 'false';
end;




procedure TfrmMain.chkUseCustomHTTPHeaderClick(Sender: TObject);
begin
  if chkUseCustomHTTPHeader.Checked = true then CustomHTTPHeaderInUse('true', false) else CustomHTTPHeaderInUse('false', false);
end;




//----------------------------------------------------set condition (true/false)
procedure TfrmMain.SetCondition(param: string);
begin
  if param = 'true' then //--- condition "true" enabled
  begin
    radConditionTrue.Checked := true;

    edtKeywordTrue.Enabled := true;
    edtKeywordTrue.Color := $00E8FEFF;

    edtKeywordFalse.Enabled := false;
    edtKeywordFalse.Color := clBtnFace;
  end else

  if param = 'false' then //--- condition "false" enabled
  begin
    radConditionFalse.Checked := true;

    edtKeywordFalse.Enabled := true;
    edtKeywordFalse.Color := $00E8FEFF;

    edtKeywordTrue.Enabled := false;
    edtKeywordTrue.Color := clBtnFace;
  end;
end;





//---------------------------------------------------------get current condition
function TfrmMain.GetCondition: string;
begin
  if radConditionTrue.Checked then result := 'true'
  else if radConditionFalse.Checked then result := 'false';
end;





//--------------------------------------------------------------use proxy or not
procedure TfrmMain.useProxy(param: string; param2: boolean);
begin
  if param = 'true' then //--- condition "true" enabled
  begin
    if param2 = true then chkUseProxy.Checked := true;

    edtProxyServerIP.Enabled := true;
    edtProxyServerIP.Color := clWhite;

    edtProxyServerPort.Enabled := true;
    edtProxyServerPort.Color := clWhite;
  end else

  if param = 'false' then //--- condition "false" enabled
  begin
    if param2 = true then chkUseProxy.Checked := false;

    edtProxyServerIP.Enabled := false;
    edtProxyServerIP.Color := clBtnFace;

    edtProxyServerPort.Enabled := false;
    edtProxyServerPort.Color := clBtnFace;
  end;
end;





//------------------------------------------------------------switch proxy usage
procedure TfrmMain.chkUseProxyClick(Sender: TObject);
begin
  if chkUseProxy.Checked = true then useProxy('true', false) else useProxy('false', false);
  tmrUpdateproxy.Enabled := true;
end;




//---------------------------------------------------check if we are using proxy
function TfrmMain.GetProxyInUse: string;
begin
  if chkUseProxy.Checked = true then result := 'true'
  else if chkUseProxy.Checked = false then result := 'false';
end;




//-----------------------------------------------set checkbox: if CURL is in use
procedure TfrmMain.curlInUse(param: string);
begin
  if param = 'true' then chkUseCURL.checked := true
  else if param = 'false' then chkUseCURL.checked := false;
end;




//----------------------------------------------------check if we are using CURL
function TfrmMain.GetCurlInUse: string;
begin
  if chkUseCURL.checked = true then result := 'true'
  else if chkUseCURL.checked = false then result := 'false';
end;




//----------------------------------------------------switch to "true" condition
procedure TfrmMain.radConditionTrueClick(Sender: TObject);
begin
  SetCondition('true');
end;




//---------------------------------------------------switch to "false" condition
procedure TfrmMain.radConditionFalseClick(Sender: TObject);
begin
  SetCondition('false');
end;




//--------------------------------------------------------------set request type
procedure TfrmMain.SetRequestType(param: string);
begin
  if param = 'get' then
  begin
    radGetRequest.Checked := true;

    memPostParameters.Enabled := false;
    memPostParameters.Color := clBtnFace;
  end else

  if param = 'post' then
  begin
    radPostRequest.Checked := true;

    memPostParameters.Enabled := true;
    memPostParameters.Color := clWhite;
  end;
end;




//---------------------------------------------------get current type of request
function TfrmMain.GetRequestType: string;
begin
  if radGetRequest.Checked then result := 'get'
  else if radPostRequest.Checked then result := 'post';
end;




procedure TfrmMain.HTMLViewerHotSpotClick(Sender: TObject; const SRC: string;
  var Handled: Boolean);
begin
  ShellExecute(self.WindowHandle, 'open', pchar(HTMLViewer.LinkAttributes.Values['href']), nil, nil, SW_SHOWNORMAL);
end;



//---------------------------------------------------------------use GET request
procedure TfrmMain.radGetRequestClick(Sender: TObject);
begin
  SetRequestType('get');
end;




//--------------------------------------------------------------use POST request
procedure TfrmMain.radPostRequestClick(Sender: TObject);
begin
  SetRequestType('post');
end;




//---------------------------------------------------------test condition "TRUE"
procedure TfrmMain.btnTestConditionTrueClick(Sender: TObject);
var r: boolean;
    myLoader: TIdHTTP;
    url: string;
begin
  btnTestConditionTrue.Enabled := false;
  labResultOfTheTest.Caption := '';
  myLoader := TIdHTTP.Create(nil);
  application.ProcessMessages;
  r := false;

  //---------------------------------GET REQUEST
  if radGetRequest.Checked then
  begin
    statusBar.Panels[1].Text := 'Testing: ' + URLEncode(TrimPayload(adv_test_payload_condition_true));
    if global_use_curl then //-- use CURL
    begin
      GenerateGETRequest(sourceHTTPHeader,
                         URLEncode(trim(edtURL.Text) + TrimPayload(adv_test_payload_condition_true)));
      r := testPayload(edtKeywordTrue.text);
    end else
    begin
      URL := URLEncode(trim(frmMain.edtURL.Text) + TrimPayload(adv_test_payload_condition_true));
      r := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, memCustomHTTPHeader.Text));
    end;
  end else

  //---------------------------------POST REQUEST
  if radPostRequest.Checked then
  begin
    if global_use_curl then //-- use CURL
    begin
      GeneratePOSTRequest(sourceHTTPHeader,
                          URLEncode(trim(edtURL.Text)),
                          URLEncode(trim(memPostParameters.Text) + TrimPayload(adv_test_payload_condition_true)));
      r := testPayload(edtKeywordTrue.text);
    end else
    begin
      URL := URLEncode(trim(frmMain.edtURL.Text));
      r := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                          memPostParameters.Text + TrimPayload(adv_test_payload_condition_true),
                                                                          memCustomHTTPHeader.Text));
    end;
  end;

  if r = true then
  begin
    labResultOfTheTest.Font.Color := clBlack;
    labResultOfTheTest.Caption := 'The test passsed! The "true" keyword IS found. :-)';
  end else
  begin
    labResultOfTheTest.Font.Color := clRed;
    labResultOfTheTest.Caption := 'The test failed. The "true" keyword IS NOT found.';
  end;

  btnTestConditionTrue.Enabled := true;
  myLoader.Free;
end;





//--------------------------------------------------------test condition "FALSE"
procedure TfrmMain.btnTestConditionFalseClick(Sender: TObject);
var r: boolean;
    myLoader: TIdHTTP;
    url: string;
begin
  btnTestConditionFalse.Enabled := false;
  labResultOfTheTest.Caption := '';
  myLoader := TIdHTTP.Create(nil);
  application.ProcessMessages;
  r := false;

  //---------------------------------GET REQUEST
  if radGetRequest.Checked then
  begin
    statusBar.Panels[1].Text := 'Testing: ' + URLEncode(TrimPayload(adv_test_payload_condition_false));
    if global_use_curl then //-- use CURL
    begin
      GenerateGETRequest(sourceHTTPHeader,
                         URLEncode(trim(edtURL.Text) + TrimPayload(adv_test_payload_condition_false)));
      r := testPayload(edtKeywordTrue.text);
    end else
    begin
      URL := URLEncode(trim(frmMain.edtURL.Text) + TrimPayload(adv_test_payload_condition_false));
      r := testPayload2(frmMain.edtKeywordTrue.text, GenerateGETRequest2(url, memCustomHTTPHeader.Text));
    end;
  end else

  //---------------------------------POST REQUEST
  if radPostRequest.Checked then
  begin
    if global_use_curl then //-- use CURL
    begin
      GeneratePOSTRequest(sourceHTTPHeader,
                          URLEncode(trim(edtURL.Text)),
                          URLEncode(trim(memPostParameters.Text) + TrimPayload(adv_test_payload_condition_false)));
      r := testPayload(edtKeywordTrue.text);
    end else
    begin
      URL := URLEncode(trim(frmMain.edtURL.Text));
      r := testPayload2(frmMain.edtKeywordTrue.text, GeneratePOSTRequest2(url,
                                                                          memPostParameters.Text + TrimPayload(adv_test_payload_condition_false),
                                                                          memCustomHTTPHeader.Text));
    end;
  end;

  if r = false then
  begin
    labResultOfTheTest.Font.Color := clBlack;
    labResultOfTheTest.Caption := 'The test passsed! The "true" keyword IS NOT found. :-)';
  end else
  begin
    labResultOfTheTest.Font.Color := clRed;
    labResultOfTheTest.Caption := 'The test failed. The "true" keyword IS found.';
  end;

  btnTestConditionFalse.Enabled := true;
  myLoader.Free;
end;





//------------------------------------------------get number of root child nodes
procedure TfrmMain.Getnumberofrootnodes1Click(Sender: TObject);
begin
  memResults.Lines.Add('Nr of root child nodes found: ' + inttostr(getNumberOfChildNodes('*')));
end;




//---------------------------------------------------------extract XML structure
procedure TfrmMain.btnGetXMLClick(Sender: TObject);
const
  btn_get_xml = '<GET XML>';
  btn_stop = 'STOP';
begin
  if btnGetXML.Caption = btn_get_xml then
  begin
    global_stop := false;
    btnGetXML.Caption := btn_stop;
    memResults.Clear;
    GetXMLForNode('', chkUseCURL.Checked);

    global_stop := true;
    btnGetXML.Caption := btn_get_xml;
    statusBar.Panels[1].Text := 'Exploitation stopped.';
  end else
  begin
    global_stop := true;
    btnGetXML.Caption := btn_get_xml;
  end;
end;





//----------------------------------------------------save extracted XML to file
procedure TfrmMain.btnSaveToFileClick(Sender: TObject);
begin
  if dlgSave.Execute = true then
  begin
    memResults.Lines.SaveToFile(dlgSave.FileName);
  end;
end;





//-------------------------------------------copy extracted XML to the clipboard
procedure TfrmMain.btnCopyToClipboardClick(Sender: TObject);
begin
  myClip.AsText := memResults.Lines.Text;
end;




//---------------------------------------------------------------on the very end
procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettingsToIni(currentIniSettingsFileName);

  myLoader.Free;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  canClose := global_stop;
end;










end.

