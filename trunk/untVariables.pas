unit untVariables;

interface
uses SysUtils, Clipbrd;


const
  iniSettingsFileName = 'XPathBlindExplorer_settings.ini';
  logFileName = 'XPathBlindExplorer_log.txt';

var
    currentDir,
    tempDir,
    currentIniSettingsFileName,
    currentLogFileName,
    logOptions: string;

    batchFile,
    resultFile,
    curlExe,
    tempCurlConfig,
    sourceHTTPHeader: string;

    rf: TReplaceFlags;

    global_stop,
    global_use_curl: boolean;

    //--- advance options
    adv_max_child_nodes_to_search,
    adv_max_nodename_length,
    adv_max_nodevalue_length: integer;

    adv_test_payload_condition_true,
    adv_test_payload_condition_false,
    adv_payload_nr_of_child_nodes,
    adv_payload_get_nodename_length,
    adv_payload_get_nodename,
    adv_payload_get_nodevalue_length,
    adv_payload_get_nodevalue: string;

    myClip: TClipboard;

implementation

end.

