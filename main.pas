unit main;

{$ifdef fpc}
  {$MODE Delphi}
{$endif}

interface

uses
{$ifndef fpc}
  shellapi,
  Messages,
  shlobj,
  FileCtrl,
{$endif}
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, inifiles,
{$ifdef CLR}
  Borland.Vcl.FileCtrl,
{$endif}
  Menus ;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label5: TLabel;
    btnReplace2: TButton;
    Edit4: TEdit;
    Label6: TLabel;
    Edit3: TEdit;
    Edit1: TEdit;
    Label4: TLabel;
    Edit2: TEdit;
    Label7: TLabel;
    edBlockFiles: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button2: TButton;
    TabSheet3: TTabSheet;
    edSearchFiles: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    btnSearch: TButton;
    ListBox1: TListBox;
    Memo1: TMemo;
    GroupBox1: TGroupBox;
    Button4: TButton;
    Label10: TLabel;
    lbCount: TLabel;
    Label11: TLabel;
    edReplaceFiles: TEdit;
    Edit9: TEdit;
    Label12: TLabel;
    Label13: TLabel;
    Edit10: TEdit;
    btnNormalReplace: TButton;
    lbNormalCount: TLabel;
    lbxReplaced: TListBox;
    PopupMenu1: TPopupMenu;
    Edit11: TMenuItem;
    OpenDialog1: TOpenDialog;
    TabSheet4: TTabSheet;
    edEditorPath: TEdit;
    Label14: TLabel;
    btnBrowseEditor: TButton;
    cbxCase: TCheckBox;
    edExtChange1: TEdit;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    edExtChange2: TEdit;
    Label18: TLabel;
    cbxRecurse: TCheckBox;
    cbDefPath: TComboBox;
    cbFindStr: TComboBox;
    procedure btnReplace2Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSearchClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNormalReplaceClick(Sender: TObject);
    procedure Edit11Click(Sender: TObject);
    procedure btnBrowseEditorClick(Sender: TObject);
    procedure cbxCaseClick(Sender: TObject);
  private
    { Private declarations }
    config: TIniFile;
    function process(fs: TStringList; s1, s2, r1, r2: string): integer;
    function replace(var buf: string; s1, s2, r1, r2: string): integer; overload;
    function replace(var buf: string; s1, r1: string; replaceAll: boolean): integer; overload;

    function getSearchFileList(path: string; filter: string; files: TStringList): TStringList;
    function getSearchRecursiveFileList(path: string; filter: string; files: TStringList): TStringList;
    procedure getAllFiles(mask: string; files: TStringList);
    function getSelListBoxFileName: string;

    function strSearchCS(searchText, buf: string; findAll: boolean; var count: integer): integer;
    function strSearchCI(searchText, buf : string; findAll: boolean; var count: integer): integer;
    function strFindCS(searchText, buf: string): integer;
    function strFindCI(searchText, buf: string): integer;
    procedure fillCombo(combo: TComboBox; configSection: string);
    procedure storeCombo(combo: TComboBox; configSection: string);
  public
    { Public declarations }
  end;

  TSearchThread = class (TThread)
   private
   protected
   public
      procedure Execute; override;
  end;
var
  Form1: TForm1;

implementation

{$ifdef fpc}
  {$R *.lfm}
{$else}
  {$R *.res}
{$endif}

//{$ifndef fpc}
        function FindFirstUTF8(const Path: string; Attr: Integer; var F: TSearchRec): Integer;
        begin
             result := FindFirst(Path, Attr, F);
        end;
        function FindNextUTF8(var F: TSearchRec): Integer;
        begin
             result := FindNext(F);
        end;
        procedure FindCloseUTF8(var F: TSearchRec);
        begin
             FindClose(F);
        end;

//{$endif}

{==============================================================================}
{ FormCreate                                                                   }
{                                                                              }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
procedure TForm1.FormCreate(Sender: TObject);
begin
  config := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'defaults.ini');

  //read each path in the combo
  fillCombo(cbDefPath, 'paths');

  //read in the last searched items into the the search combo
  fillCombo(cbFindStr, 'findstr');
  
  edEditorPath.Text := config.ReadString('paths', 'editor', '');
  cbxCase.Checked := config.ReadBool('defaults', 'matchcase', False);

  edSearchFiles.Text := config.ReadString('files', 'search', '*.htm');
  edReplaceFiles.Text := config.ReadString('files', 'replace', '*.htm');
  edBlockFiles.Text := config.ReadString('files', 'replaceblock', '*.htm');

end;

{==============================================================================}
{ FormDestroy                                                                  }
{                                                                              }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
procedure TForm1.FormDestroy(Sender: TObject);
begin
  //save each path in the combo
  storeCombo(cbDefPath, 'paths');

  //save each search string in the combo
  storeCombo(cbFindStr, 'findstr');

  config.Free;
end;

//==============================================================================
// fillCombo
//
//
// N.Herrmann Aug 2004
//==============================================================================
procedure TForm1.fillCombo(combo: TComboBox; configSection: string);
var
  strItem: string;
  i: integer;
  defIndex: integer;
begin
  //read the items into the the combo
  i := 0;
  strItem := config.ReadString(configSection, 'default_' + IntToStr(i), '\');
  while strItem <> '\' do
  begin
    combo.Items.Insert(combo.Items.Count, strItem);
    inc(i);
    strItem := config.ReadString(configSection, 'default_' + IntToStr(i), '\');
  end;
  defIndex := config.ReadInteger(configSection, 'default', 0);
  combo.ItemIndex := defIndex;
end;

//==============================================================================
//
//
//
// N.Herrmann Aug 2004
//==============================================================================
procedure TForm1.storeCombo(combo: TComboBox; configSection: string);
var
  i: integer;
begin
  i := 0;
  while (i <= 15) and (i <= combo.Items.Count - 1) do
  begin
    config.WriteString(configSection, 'default_' + IntToStr(i), combo.Items[i]);
    inc(i);
  end;
  config.WriteInteger(configSection, 'default',  combo.ItemIndex);

end;

{==============================================================================}
{                                                                              }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.Button2Click(Sender: TObject);
begin
  Close;
end;

{==============================================================================}
{                                                                              }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  config.WriteString('files', 'search', edSearchFiles.Text);
  config.WriteString('files', 'replace', edReplaceFiles.Text);
  config.WriteString('files', 'replaceblock', edBlockFiles.Text);

  Action := caFree;
end;

{==============================================================================}
{ process                                                                      }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
function TForm1.process(fs: TStringList; s1, s2, r1, r2: string): integer;
var
  buf: string;
  posS1: integer;
  posS2: integer;
  replaceCount: integer;
begin
  replaceCount := 0;

  buf := fs.Text;

  posS1 := pos(s1, buf);
  posS2 := pos(s2, buf);
  if (s1 <> '') and (posS1 > 0) then
  begin
    if (s2 <> '') and (posS2 > 0) then
    begin
      replaceCount := replace(buf, s1, s2, r1, r2);
    end
    else
    begin
      replaceCount := replace(buf, s1, r1, True);
    end;
  end;

  fs.Text := buf;

  result := replaceCount;
end;

{==============================================================================}
{ replace                                                                      }
{                                                                              }
{ Does the real replacement job.                                               }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
function TForm1.replace(var buf: string; s1, r1: string; replaceAll: boolean): integer;
var
  i: integer;
  x: integer;
  temp: string;
  bufLen: integer;
  replaceCount: integer;
begin
  replaceCount := 0;
  bufLen := Length(buf);
  temp := '';
  i := 1;
  while i <= bufLen do      //while more chars in input buffer
  begin
    //skip along until we match the first character
    while (s1[1] <> buf[i]) and (i <= bufLen) do
    begin
      temp := temp + buf[i];
      inc(i);
    end;
    //either a match or eof
    if i <= bufLen then
    begin
      x := 1;
      //while more characters to test
      while (s1[x] = buf[i + x - 1]) and ((i + x - 1) <= bufLen) do
        inc(x);
      if ((x - 1) = Length(s1)) and ((i + x - 2) <= bufLen) then  //if a full match found
      begin
        temp := temp + r1;          //do the replacement
        inc(replaceCount);
        i := i + Length(s1) - 1;    //skip past search string
        if replaceAll = False then  //if only one replacement
        begin
          temp := temp + copy(buf, i + 1, bufLen - i); //append the rest of the string to temp[]
          i := bufLen;              //terminate loop
        end;
      end
      else //else not full match
      begin
        temp := temp + buf[i]; //copy current char and keep looping
      end;
    end;
    inc(i);
  end;

  buf := temp;  //store the result

  result := replaceCount;
end;


{==============================================================================}
{                                                                              }
{ Replaces any text that has been described as having a start tag and end tag  }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
function TForm1.replace(var buf: string; s1, s2, r1, r2: string): integer;
var
  posS1: integer;
  posS2: integer;
  bufLen: integer;
  temp: string;
  newBuf: string;
  replaceCount: integer;
begin
  replaceCount := 0;
  bufLen := Length(buf);
  newBuf := buf;
  posS2 := 0;

  //get the remaining buffer to be checked
  posS1 := pos(s1, buf);
  if posS1 > 0 then
  begin
    temp := copy(buf, posS1, bufLen - posS1); //section to be processed
    newBuf := copy(buf, 1, posS1 - 1);        //copy the first part to the output
    posS1 := 1;
    posS2 := pos(s2, temp);
  end;

  while (posS1 > 0) and (posS2 > 0) and (posS2 > posS1) do  //while the first and second pattern exist
  begin
    replace(temp, s1, r1, False); //replace the first string(one)
    replace(temp, s2, r2, False); //replace the next one(one) after the replaced first pattern
    newBuf := newBuf + temp;      //new buffer to check
    inc(replaceCount);

    //get the remaining buffer to be checked
    posS1 := pos(s1, newBuf);
    if posS1 > 0 then //if there are more items to replace
    begin
      temp := copy(newbuf, posS1, bufLen - posS1);  //section to be processed
      newBuf := copy(newbuf, 1, posS1 - 1);         //copy the first part to the output
      posS1 := 1;
      posS2 := pos(s2, temp);
    end;
  end;

  buf := newBuf;

  result := replaceCount;
end;

{==============================================================================}
{ btnSearchClick                                                               }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.btnSearchClick(Sender: TObject);
var
  files: TStringList;
  fs: TStringList;
  i: integer;
  numFiles: integer;
  foundAt: integer;
begin

  if Length(cbDefPath.Text) > 0 then
  begin
    //add the path to the combo if it not in there
    if cbDefPath.Items.IndexOf(cbDefPath.Text) < 0 then
      cbDefPath.Items.Insert(0, cbDefPath.Text);

    //add the search string to the combo if it not in there
    if cbFindStr.Items.IndexOf(cbFindStr.Text) < 0 then
      cbFindStr.Items.Insert(0, cbFindStr.Text);

    //move the last used item to the top  
    cbFindStr.Items.Move(cbFindStr.Items.IndexOf(cbFindStr.Text), 0);
    cbFindStr.ItemIndex := 0;
    cbDefPath.Items.Move(cbDefPath.Items.IndexOf(cbDefPath.Text), 0);
    cbDefPath.ItemIndex := 0;

    files := TStringList.Create;
    fs := TStringList.Create;

    Memo1.Lines.Clear;  //clear the lines memo
    lbCount.Caption := 'Searching...';
    lbCount.Update;
    try
      Screen.Cursor := crHourGlass;
      ListBox1.Clear;
      if cbxRecurse.Checked then
        getSearchRecursiveFileList(cbDefPath.Text, edSearchFiles.Text, files)//recursive search
      else
        getSearchFileList(cbDefPath.Text, edSearchFiles.Text, files);
      numFiles := files.Count;

      //Search for a string in the file set
      for i := 0 to files.Count - 1 do
      begin
        fs.LoadFromFile(files[i]);

        if cbxCase.Checked = True then  //if case sensitive search
           foundAt := strFindCS(cbFindStr.Text, fs.Text)
        else
           foundAt := strFindCI(cbFindStr.Text, fs.Text);

        if foundAt > 0 then
        begin
          if cbxRecurse.Checked then
            ListBox1.Items.Add(files[i]) //show the full pathnames in a file list
          else
            ListBox1.Items.Add(ExtractFileName(files[i])); //show the files in a file list
        end;
        ListBox1.Update;
      end;
    finally
      fs.Free;
      files.Free;
      Screen.Cursor := crDefault;
    end;
    lbCount.Caption := IntToStr(ListBox1.Items.count) + ' of ' + IntToStr(numFiles) + ' files';
  end;

end;

{==============================================================================}
{ getSearchFileList                                                            }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
function TForm1.getSearchFileList(path: string; filter: string; files: TStringList): TStringList;
var
  filename: string;
  sr: TSearchRec;
  FileAttrs: Integer;
begin
  FileAttrs := 0;

  files.Clear;
  try
    if path[Length(path)] <> '\' then
      path := path + '\';
    if FindFirstUTF8(path + filter, FileAttrs, sr) { *Converted from FindFirst*  } = 0 then
    begin
      repeat
        fileName := path + sr.Name;
//        if uppercase(ExtractFileExt(fileName)) = uppercase(ExtractFileExt(filter)) then
//        begin
          files.Add(fileName);
 //       end;
      until FindNextUTF8(sr) { *Converted from FindNext*  } <> 0;
      FindCloseUTF8(sr); { *Converted from FindClose*  }
    end;
  finally

  end;

  result := files;
end;


{==============================================================================}
{ getSearchFileList                                                            }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
function TForm1.getSearchRecursiveFileList(path: string; filter: string; files: TStringList): TStringList;
begin

  files.Clear;
  if path[Length(path)] <> '\' then
    path := path + '\';
  GetAllFiles(path + filter, files);

  result := files;
end;

//==============================================================================
// GetAllFiles
//
// Gets files from the current directory and any sub directories
// N.Herrmann Mar 2003
//==============================================================================
procedure TForm1.GetAllFiles(mask: string; files: TStringList);
var
  search: TSearchRec;
  directory: string;
begin
  directory := ExtractFilePath(mask);

  //firstly find all files
  if FindFirstUTF8(mask, $23, search) { *Converted from FindFirst*  } = 0 then
  begin
    repeat
      files.Add(directory + search.Name); // add the files to the list
    until FindNextUTF8(search) { *Converted from FindNext*  } <> 0;
    FindCloseUTF8(search); { *Converted from FindClose*  }
  end;

  //Now search for all the subdirectories
  if FindFirstUTF8(directory + '*.*', faDirectory, search) { *Converted from FindFirst*  } = 0 then
  begin
    repeat
      if ((search.Attr and faDirectory) = faDirectory)
        and (search.Name[1] <> '.')
        and (search.Name <> '..')  then
        GetAllFiles(directory + search.Name + '\' + ExtractFileName(mask), files);
    until FindNextUTF8(search) { *Converted from FindNext*  } <> 0;
    FindCloseUTF8(search); { *Converted from FindClose*  }
  end;



end;

{==============================================================================}
{ ListBox1Click                                                                }
{ Show the lines in the file that match the search string                      }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.ListBox1Click(Sender: TObject);
var
  fileName: string;
  fs: TStringList;
  i: integer;
  position: integer;
begin
  Memo1.Lines.Clear;

  fileName := getSelListBoxFileName;

  fs := TStringList.Create;
  try
    fs.LoadFromFile(fileName);
    for i := 0 to fs.count - 1 do
    begin
        if cbxCase.Checked then //case sensitive
          position := strFindCS(cbFindStr.Text, fs[i])
        else
          position := strFindCI(cbFindStr.Text, fs[i]);

        if position > 0 then
          Memo1.Lines.Add(IntToStr(i + 1) + ':  ' + fs[i]);
    end;
  finally
    fs.Free;
  end;

  //scroll the memo to line 0
  Memo1.SelStart := 0;
  Memo1.SelLength := 0;

end;

{==============================================================================}
{                                                                              }
{                                                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.Button4Click(Sender: TObject);
var
  path: string;
begin
  //select a directory and place it in the editbox
  path := cbDefPath.Text;
  if SelectDirectory(path, [], 0) then
  begin
    if cbDefPath.Items.IndexOf(path) < 0 then
      cbDefPath.Items.Insert(0, path);

    cbDefPath.ItemIndex := cbDefPath.Items.IndexOf(path);
    config.WriteInteger('paths', 'default', cbDefPath.Items.IndexOf(path));
  end;
end;


{==============================================================================}
{ btnNormalReplaceClick                                                        }
{                                                                              }
{ Do a normal replace of one item                                              }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.btnNormalReplaceClick(Sender: TObject);
var
  s1, r1: string;
  fs: TStringList;
  filename: string;
  count: integer;
  totalFiles: integer;
  files: TStringList;
  i: integer;
  replaceCount: integer;
begin
  count := 0;
  totalFiles := 0;

  //do the replacement
  s1 := Edit9.Text;
  r1 := Edit10.Text;

  files := TStringList.Create;  //list of files in the filter
  fs := TStringList.Create;
  try
    Screen.Cursor := crHourGlass;
    lbNormalCount.Caption := 'Searching...';
    lbNormalCount.Update;
    getSearchFileList(cbDefPath.Text, edReplaceFiles.Text, files);
    lbxReplaced.Items.Clear;
    for i := 0 to files.Count - 1 do
    begin
      fileName := files[i];

      fs.LoadFromFile(fileName);
      inc(totalFiles);
      replaceCount := process(fs, s1, '', r1, '');
      if replaceCount > 0 then   //if successful
      begin
        lbxReplaced.Items.Add(IntToStr(replaceCount) + ': ' + ExtractfileName(fileName));
        if Length(edExtChange1.Text) > 0 then
            fileName := ChangeFileExt(filename, edExtChange1.Text);
        fs.SaveToFile(fileName);
        inc(count);
        lbNormalCount.Caption := IntToStr(count) + ' of ' + IntToStr(totalFiles) + ' files processed.';
        lbNormalCount.Update;
      end
      else
      begin
        lbNormalCount.Caption := IntToStr(count) + ' of ' + IntToStr(totalFiles) + ' files processed.';
        lbNormalCount.Update;
      end;
    end;
  finally
    fs.Free;
    Screen.Cursor := crDefault;
    lbNormalCount.Caption := IntToStr(count) + ' of ' + IntToStr(totalFiles) + ' files processed.';
  end;

  files.Free;

end;

{==============================================================================}
{ btnReplace2Click                                                             }
{                                                                              }
{ Replace start and end tags of a block                                        }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.btnReplace2Click(Sender: TObject);
var
  s1, s2, r1, r2: string;
  fs: TStringList;
  filename: string;
  count: integer;
  totalFiles: integer;
  files: TStringList;
  i: integer;
begin
  count := 0;
  totalFiles := 0;

  //do the replacement
  s1 := Edit1.Text;
  s2 := Edit2.Text;
  r1 := Edit3.Text;
  r2 := Edit4.Text;

  files := TStringList.Create;  //list of files in the filter

  fs := TStringList.Create;
  try
    Screen.Cursor := crHourGlass;
    Label5.Caption := 'Searching...';
    Label5.Update;
    getSearchFileList(cbDefPath.Text, edBlockFiles.Text, files);
    for i := 0 to files.Count - 1 do
    begin
      fileName := files[i];

      fs.LoadFromFile(fileName);
      inc(totalFiles);
      if process(fs, s1, s2, r1, r2) > 0 then   //if successful
      begin
        if Length(edExtChange2.Text) > 0 then
            fileName := ChangeFileExt(filename, edExtChange1.Text);

        fs.SaveToFile(fileName);
        inc(count);
        Label5.Caption := IntToStr(count) + ' of ' + IntToStr(totalFiles) + ' files processed.';
        Label5.Update;
      end
      else
      begin
        Label5.Caption := IntToStr(count) + ' of ' + IntToStr(totalFiles) + ' files processed.';
        Label5.Update;
      end;
    end;
  finally
    fs.Free;
    Screen.Cursor := crDefault;
  end;

  files.Free;
end;

{==============================================================================}
{ Edit11Click                                                                  }
{ Menu item click to edit a file in the listbox                                }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
procedure TForm1.Edit11Click(Sender: TObject);
var
  editor: string;
  path: string;
  fileName: string;
begin
  //use an editor to edit the higlighted file
  editor := config.ReadString('paths', 'editor', '');
  if editor = '' then
  begin
    //get the path of an editor
    if OpenDialog1.Execute then
    begin
      editor := OpenDialog1.FileName;
      config.WriteString('paths', 'editor', editor);
    end;
  end;
  //open the editor
  fileName := '"' + getSelListBoxFileName + '"';

  if editor <> '' then
    shellExecute(handle, PChar('open'), PChar('"' + editor + '"'), PChar(fileName), PChar(path), SW_SHOWDEFAULT);

end;

{==============================================================================}
{ btnBrowseEditorClick                                                         }
{                                                                              }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
procedure TForm1.btnBrowseEditorClick(Sender: TObject);
var
  editor: string;
begin

  //get the path of an editor
    if OpenDialog1.Execute then
    begin
      editor := OpenDialog1.FileName;
      edEditorPath.Text := editor;
      config.WriteString('paths', 'editor', editor);
    end;

end;

{==============================================================================}
{ strSearchCS                                                                  }
{ Case Sensitive                                                               }
{ N.Herrmann Aug 2002                                                          }
{==============================================================================}
function TForm1.strSearchCS(searchText, buf: string; findAll: boolean; var count: integer): integer;
var
  i: integer;
  x: integer;
  bufLen: integer;
  position: integer;
begin
  position := 0;
  count := 0;

  bufLen := Length(buf);
  i := 1;
  while i <= bufLen do      //while more chars in input buffer
  begin
    //skip along until we match the first character
    while (i <= bufLen) and (searchText[1] <> buf[i]) do
    begin
      inc(i);
    end;
    //either a match or eof
    if i <= bufLen then
    begin
      x := 1;
      //while more characters to test
      while (x <= Length(searchText)) and ((i + x - 1) <= bufLen) and (searchText[x] = buf[i + x - 1]) do
        inc(x);
      if ((x - 1) = Length(searchText)) and ((i + x - 2) <= bufLen) then  //if a full match found
      begin
        if position = 0 then
          position := i;
        inc(count);
        if not findAll then //if only find one instance
           i := bufLen + 1
        else
           i := i + Length(searchText) - 1;    //skip past search string
      end;
    end;
    inc(i);
  end;

  result := position;
end;

{==============================================================================}
{ strSearchCI                                                                  }
{ Case Insensitive                                                             }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
function TForm1.strSearchCI(searchText, buf: string; findAll: boolean; var count: integer): integer;
var
  i: integer;
  x: integer;
  bufLen: integer;
  position: integer;
begin
  position := 0;
  count := 0;

  searchText := Uppercase(searchText); //use upper case

  bufLen := Length(buf);
  i := 1;
  while i <= bufLen do      //while more chars in input buffer
  begin
    //skip along until we match the first character
    while (i <= bufLen) and (searchText[1] <> UpCase(buf[i])) do
    begin
      inc(i);
    end;
    //either a match or eof
    if i <= bufLen then
    begin
      x := 1;
      //while more characters to test
      while (x <= Length(searchText)) and ((i + x - 1) <= bufLen) and (searchText[x] = UpCase(buf[i + x - 1])) do
        inc(x);
      if ((i + x - 2) <= bufLen) and ((x - 1) = Length(searchText)) then  //if a full match found
      begin
        if position = 0 then
          position := i;
        inc(count);
        if not findAll then //if only find one instance
           i := bufLen + 1
        else
           i := i + Length(searchText) - 1;    //skip past search string
      end;
    end;
    inc(i);
  end;

  result := position;
end;

{==============================================================================}
{ strFindCI                                                                    }
{ Finds the first occurrence of the string. Case Insensitive.                  }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
function TForm1.strFindCI(searchText, buf: string): integer;
var
  i: integer;
begin
  result := strSearchCI(searchText, buf, False, i);
end;

{==============================================================================}
{ strFindCI                                                                    }
{ Finds the first occurrence of the string. Case sensitive.                    }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
function TForm1.strFindCS(searchText, buf: string): integer;
var
  i: integer;
begin
  result := strSearchCS(searchText, buf, False, i);
end;

{==============================================================================}
{                                                                              }
{                                                                              }
{ N.Herrmann Sep 2002                                                          }
{==============================================================================}
procedure TForm1.cbxCaseClick(Sender: TObject);
begin
  config.WriteBool('defaults', 'matchcase', cbxCase.Checked);
end;

//==============================================================================
// getSelListBoxFileName
//
// Returns the filename that is highlighted in the listbox on the search tab
// N.Herrmann Jan 2003
//==============================================================================
function TForm1.getSelListBoxFileName: string;
var
  fileName: string;
  path: string;
begin
  fileName := ListBox1.Items[ListBox1.ItemIndex];
  if not cbxRecurse.Checked then  //if not recursive then get the path from the editbox
  begin
    path := cbDefPath.Text;
    if path[Length(path)] <> '\' then
        path := path + '\';

    fileName := path + fileName;
  end;

  result := fileName;
end;


{ TSearchThread }

procedure TSearchThread.Execute;
begin
  inherited;

end;

end.
