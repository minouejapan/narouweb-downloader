(*
  小説家になろう小説HTMLダウンローダー

  1.1 2025/03/27  ページ送りリンクの書き換えがおかしかった不具合を修正した
  1.0 2025/01/18  Na6dlを元にHTMLを保存する仕様に変更した

  Current Directory
    タイトル名フォルダ
      ├タイトル名.html(ダミーでcontents1.htmlにジャンプする
      └html
        ├contentsX.html (目次に2ページ目以降がある場合. Xは番号)
        ├0001.html
        ├0002.html
  のように保存する
*)
program na6dlweb;

{$APPTYPE CONSOLE}

{$IFDEF FPC}
  {$MODE Delphi}
  {$codepage utf8}
{$ENDIF}

{$R *.res}
{$R na6dlwebver.res}

uses
  LazUTF8wrap,
  System.SysUtils,
  System.Classes,
  Windows,
  regexpr,
  IdHTTP,
  IdCookieManager,
  IdSSLOpenSSL,
  IdGlobal,
  IdURI;

const
  DUMMY = '<!DOCTYPE html>'#13#10
        + '<html>'#13#10
        + '  <head>'#13#10
        + '    <meta content="ja" http-equiv="Content-Language" /> '#13#10
        + '    <meta http-equiv="refresh" content="0;URL=.\html\contents1.html" />'#13#10
        + '    <title>DUMMY</title>'#13#10
        + '  </head>'#13#10
        + '  <body>'#13#10
        + '    <p>ジャンプしない場合は<a href=".\html\contents1.html">ここをクリックしてください.</a></p>'#13#10
        + '  </body>'#13#10
        + '</html>'#13#10;

var
  IdHTTP: TIdHTTP;
  IdSSL: TIdSSLIOHandlerSocketOpenSSL;
  Cookies: TIdCookieManager;
  URI: TIdURI;
  URL, BaseURL, BaseDir, FileName, TextLine: string;
  isOver18: boolean;
  RegEx: TRegExpr;
  DelJS: boolean;

// Indyを用いたHTMLファイルのダウンロード
function LoadHTMLbyIndy(URLadr: string): string;
var
  IdURL: string;
  rbuff: TMemoryStream;
  tbuff: TStringList;
  ret: Boolean;
label
  Terminate;
begin
	Result := '';
  ret := False;

  rbuff := TMemoryStream.Create;
  tbuff := TStringList.Create;
  try
    try
      IdHTTP.Head(URLadr);
    except
      //取得に失敗した場合、再度取得を試みる
      try
        IdHTTP.Head(URLadr);
      except
        ret := True;
      end;
    end;
    if IdHTTP.ResponseCode = 302 then
    begin
      //リダイレクト後のURLで再度Headメソッドを実行して情報取得
      IdHTTP.Head(IdHTTP.Response.Location);
    end;
    if not ret then
    begin
      IdURL := IdHTTP.URL.URI;
      try
        IdHTTP.Get(IdURL, rbuff);
      except
        //取得に失敗した場合、再度取得を試みる
        try
          IdHTTP.Get(IdURL, rbuff);
        except
          Result := '';
        end;
      end;
    end;
    IdHTTP.Disconnect;
    rbuff.Position := 0;
    tbuff.LoadFromStream(rbuff, TEncoding.UTF8);
    Result := tbuff.Text;
  finally
    tbuff.Free;
    rbuff.Free;
  end;
end;

// タイトル名にファイル名として使用出来ない文字を'-'に置換する
// Lazarus(FPC)とDelphiで文字コード変換方法が異なるためコンパイル環境で
// 変換処理を切り替える
function PathFilter(PassName: string): string;
var
  path: string;
  tmp: AnsiString;
begin
  // ファイル名を一旦ShiftJISに変換して再度Unicode化することでShiftJISで使用
  // 出来ない文字を除去する
{$IFDEF FPC}
  tmp  := UTF8ToWinCP(PassName);
  path := WinCPToUTF8(tmp);      // これでUTF-8依存文字は??に置き換わる
{$ELSE}
  tmp  := AnsiString(PassName);
	path := string(tmp);
{$ENDIF}
  // ファイル名として使用できない文字を'-'に置換する
  path := ReplaceRegExpr('[\\/:;\*\?\+,.|\.\t ]', path, '-');

  Result := path;
end;

//  各話を取得する
procedure LoadEachPage(PageN: integer);
var
  i, n: integer;
  line, org, rpl: string;
  html: TStringList;
label
  Cont;
begin
  n := 1;
  Write('各話を取得中 [  0/' + Format('%3d', [PageN]) + ']' + #13);
  html := TStringList.Create;
  try
    for i := 1 to PageN do
    begin
      Write(#13'各話を取得中 [' + Format('%3d', [i]) + '/' + Format('%3d', [PageN]) +']');

      line := LoadHTMLbyIndy(URL + IntToStr(i) + '/');
      if line <> '' then
      begin
        html.Text := Line;
        RegEx.InputString := line;
        rpl := '';
        // 前へ　目次　次へ
        RegEx.Expression  := '<div class="c-pager c-pager--center">.*?<a href=".*?" class="c-pager__item c-pager__item--before">前へ</a><a href=".*?" class="c-pager__item">目次</a>.*?<a href=".*?" class="c-pager__item c-pager__item--next">次へ</a></div>';
        if RegEx.Exec then
        begin
          org  := RegEx.Match[0];
          rpl  := '<div class="c-pager c-pager--center">'#13#10'<a href=".\'
                + IntToStr(i - 1)
                + '.html" class="c-pager__item c-pager__item--before">前へ</a><a href=".\contents1.html" class="c-pager__item">目次</a>'#13#10'<a href="'
                + IntToStr(i + 1)
                + '.html" class="c-pager__item c-pager__item--next">次へ</a></div>';
          line := StringReplace(line, org, rpl, [rfReplaceAll]);
          Goto Cont;
        end;
        // 目次　次へ
        RegEx.Expression  := '<div class="c-pager c-pager--center">.*?<a href=".*?" class="c-pager__item">目次</a>.*?<a href=".*?" class="c-pager__item c-pager__item--next">次へ</a></div>';
        if RegEx.Exec then
        begin
          org  := RegEx.Match[0];
          rpl  := '<div class="c-pager c-pager--center">'#13#10'<a href=".\contents1.html" class="c-pager__item">目次</a>'#13#10'<a href=".\2.html" class="c-pager__item c-pager__item--next">次へ</a></div>';
          line := StringReplace(line, org, rpl, [rfReplaceAll]);
          Goto Cont;
        end;
        // 前へ　目次
        RegEx.Expression  := '<div class="c-pager c-pager--center">.*?<a href=".*?" class="c-pager__item c-pager__item--before">前へ</a><a href=".*?" class="c-pager__item">目次</a>';
        if RegEx.Exec then
        begin
          org  := RegEx.Match[0];
          rpl  := '<div class="c-pager c-pager--center">'#13#10'<a href="'
                + IntToStr(i - 1)
                + '.html" class="c-pager__item c-pager__item--before">前へ</a><a href=".\contents1.html" class="c-pager__item">目次</a>';
          line := StringReplace(line, org, rpl, [rfReplaceAll]);
        end;
Cont:
        Inc(n);
        if DelJS then
          line := ReplaceRegExpr('<script.*?</script>', line, '');
        html.Text := line;
        html.SaveToFile(BaseDir + IntToStr(i) + '.html', TEncoding.UTF8);
      end;
      // サーバー側に負担をかけないため0.4秒のインターバルを入れる
      Sleep(400);
    end;
  finally
    html.Free;
  end;
  if n < PageN then
    Writeln(' ... ' + IntToStr(n - 1) + ' 個のエピソードを保存しましたが、' + IntToStr(PageN - n - 1) + '個のエピソードの取得に失敗しました.')
  else
    Writeln(' ... ' + IntToStr(n - 1) + ' 個のエピソードを保存しました.');
end;

// 小説情報にアクセスして小説が短編かどうかを取得する
function IsShortNovel(NiURL: string): boolean;
var
  str: string;
begin
  Result := False;
  str := LoadHTMLbyIndy(NiURL);
  if UTF8Length(str) = 0 then
    Exit;
  // 小説が短編かどうかチェックする
  if UTF8Pos('<span id="noveltype">短編</span>', str) > 0 then
    Result := True;     // 短編のシンボルテキストを返す
end;

// トップページの解析
function ParseTopPage(Line: string): integer;
var
	pn, n: integer;
  surl, org, rpl, top, cnt, tmp, cont: string;
  title: string;
  sn: boolean;
  html: TStringList;
  MyClass: TObject;
  i: Integer;
begin
  Result := -1;

  Write('トップページを解析中 ' + URL + ' ... ');
	// タイトル
  RegEx.InputString := Line;
  RegEx.Expression  := '<title>.*?</title>';
  if RegEx.Exec then
  begin
    title := RegEx.Match[0];
    title := ReplaceRegExpr('</title>', ReplaceRegExpr('<title>', title, ''), '');
  end else
    Exit;
  // 小説情報URL
  sn := False;
  RegEx.Expression := '<a class="c-menu__item" href=".*?">作品情報</a>';
  if RegEx.Exec then
  begin
    surl := RegEx.Match[0];
    surl := ReplaceRegExpr('<a class="c-menu__item" href="', ReplaceRegExpr('">作品情報</a>', surl, ''), '');
    sn   := IsShortNovel(surl);
  end;
  FileName := PathFilter(title);
  FileName := UTF8Copy(FileName, 1, 32);
  top      := ExtractFilePath(ParamStr(0)) + FileName + '\';
  BaseDir  := top + 'html\';
  // カレントフォルダにタイトル名のフォルダをつくる
  if not DirectoryExists(top) then
    ForceDirectories(top);
  html := TStringList.Create;

  if DelJS then
    Line := ReplaceRegExpr('<script.*?</script>', Line, '');  // JavaScriptを除去
  try
    if sn then  // 短編
    begin
      html.Text := Line;
      html.SaveToFile(top + FileName + '.html', TEncoding.UTF8);
      Result := 0;
    // 連載：目次リンクあり
    end else begin
      html.Text := DUMMY;
      html.SaveToFile(top + FileName + '.html', TEncoding.UTF8);
      // カレントフォルダ\タイトル名のフォルダにサブフォルダhtmlをつくる
      if not DirectoryExists(BaseDir) then
        ForceDirectories(BaseDir);
      // 目次はトップページのみ(100話以下)
      if UTF8Pos('次へ</a>', Line) = 0 then
      begin
        // 目次各話へのリンクURLを書き換える
        n := 0;
        RegEx.InputString := Line;
        RegEx.Expression := '<div class="p-eplist__sublist">'#13#10'<a href="/.*?/"';
        while RegEx.Exec do
        begin
          Inc(n);
          tmp := RegEx.Match[0];
          rpl := '<div class="p-eplist__sublist">'#13#10'<a href=".\' + IntToStr(n) + '.html"';
          Line := StringReplace(Line, tmp, rpl, []);
          RegEx.InputString := Line;
        end;
        html.Text := Line;
        html.SaveToFile(BaseDir + 'contents1.html', TEncoding.UTF8); // 目次を保存する
        Writeln('目次と' + IntToStr(n) + '話の情報を取得しました.');
        Result := n;
     // 目次が複数ページにまたがっている(100話以上)
      end else begin
        // 目次ページ数を取得する
        pn := 0;
        RegEx.InputString := Line;
        RegEx.Expression  := '次へ</a>'#13#10'<a href="/n.*?/\?p=\d.*?" class="c-pager__item c-pager__item--last">最後へ</a>';
        if RegEx.Exec then
        begin
          tmp := RegEx.Match[0];
          // /id/?p=xから目次ページ数xを取得する
          tmp := StringReplace(
                StringReplace(tmp, '" class="c-pager__item c-pager__item--last">最後へ</a>', '', []),
                '次へ</a>'#13#10'<a href="', '', []);
          tmp := ReplaceRegExpr('/.*?/\?p=', tmp, '');
          try
            pn := StrToInt(tmp);
          except
            Exit;
          end;
        end;
        // 複数ページにまたがる目次を取得する
        // Write('目次を取得中...');
        n := 1;
        for i := 1 to pn do
        begin
          if i > 1 then
          begin
            cont := LoadHTMLbyIndy(URL + '?p=' + IntToStr(i));
            if cont = '' then
              Exit
            else if DelJS then
              cont := ReplaceRegExpr('<script.*?</script>', cont, '');  // JavaScriptを除去
          end else
            cont := Line;
          // 現在のページの処理
          // 最初へのリンクURLを置換する
          RegEx.InputString := cont;
          RegEx.Expression  := '<div class="c-pager__pager">'#13#10'<a href="/n.*?/" class="c-pager__item c-pager__item--first">最初へ</a>';
          if RegEx.Exec then
          begin
            org := RegEx.Match[0];
            rpl := '<div class="c-pager__pager">'#13#10'<a href=".\contents1.html" class="c-pager__item c-pager__item--first">最初へ</a>';
            cont := StringReplace(cont, org, rpl, [rfReplaceAll]);
          end;
          // 前へのリンクURLを置換する
          RegEx.InputString := cont;
          RegEx.Expression  := '最初へ</a>'#13#10'<a href="/n.*?/\?p=\d.*?" class="c-pager__item c-pager__item--before">前へ</a>';
          if RegEx.Exec then
          begin
            org := RegEx.Match[0];
            rpl := '最初へ</a>'#13#10'<a href=".\contents' + IntToStr(i - 1) + '.html" class="c-pager__item c-pager__item--before">前へ</a>';
            cont := StringReplace(cont, org, rpl, [rfReplaceAll]);
          end;
          // 次へのリンクURLを置換する
          RegEx.InputString := cont;
          RegEx.Expression  := '<a href="/n.*?/\?p=\d.*?" class="c-pager__item c-pager__item--next">次へ</a>';
          if RegEx.Exec then
          begin
            org := RegEx.Match[0];
            rpl := '<a href=".\contents' + IntToStr(i + 1) + '.html" class="c-pager__item c-pager__item--next">次へ</a>';
            cont := StringReplace(cont, org, rpl, [rfReplaceAll]);
          end;
          // 最後へのリンクURLを置換する
          RegEx.InputString := cont;
          RegEx.Expression  := '次へ</a>'#13#10'<a href="/n.*?/\?p=\d.*?" class="c-pager__item c-pager__item--last">最後へ</a>';
          if RegEx.Exec then
          begin
            org := RegEx.Match[0];
            rpl := '次へ</a>'#13#10'<a href=".\contents' + IntToStr(pn) + '.html" class="c-pager__item c-pager__item--last">最後へ</a>';
            cont := StringReplace(cont, org, rpl, [rfReplaceAll]);
          end;
          // 目次各話へのリンクURLを書き換える
          //  html.Text := cont;
          //  html.SaveToFile(BaseDir + 'debug.txt', TEncoding.UTF8);
          RegEx.InputString := cont;
          RegEx.Expression := '<a href="/n.*?/\d.*?/"';
          while RegEx.Exec do
          begin
            tmp := RegEx.Match[0];
            rpl := '<a href=".\' + IntToStr(n) + '.html"';
            cont := StringReplace(cont, tmp, rpl, []);
            Inc(n);
            RegEx.InputString := cont;
          end;
          // 目次を保存する
          html.Text := cont;
          html.SaveToFile(BaseDir + 'contents' + IntToStr(i) + '.html', TEncoding.UTF8);
        end;
        Writeln(IntToStr(pn) + '枚の目次と' + IntToStr(n - 1) + '話の情報を取得しました.');
        Result := n - 1;
      end;
    end;
  finally
    html.Free;
  end;
end;

function GetVersionInfo(const AFileName:string): string;
var
  InfoSize:DWORD;
  SFI:string;
  Buf,Trans,Value:Pointer;
begin
  Result := '';
  if AFileName = '' then Exit;
  InfoSize := GetFileVersionInfoSize(PChar(AFileName),InfoSize);
  if InfoSize <> 0 then
  begin
    GetMem(Buf,InfoSize);
    try
      if GetFileVersionInfo(PChar(AFileName),0,InfoSize,Buf) then
      begin
        if VerQueryValue(Buf,'\VarFileInfo\Translation',Trans,InfoSize) then
        begin
          SFI := Format('\StringFileInfo\%4.4x%4.4x\FileVersion',
                 [LOWORD(DWORD(Trans^)),HIWORD(DWORD(Trans^))]);
          if VerQueryValue(Buf,PChar(SFI),Value,InfoSize) then
            Result := PChar(Value)
          else Result := 'UnKnown';
        end;
      end;
    finally
      FreeMem(Buf);
    end;
  end;
end;

// OpenSSLが使用出来るかどうかチェックする
function CheckOpenSSL: Boolean;
var
  hnd: THandle;
begin
  Result := True;
  hnd := LoadLibrary('libeay32.dll');
  if hnd = 0 then
    Result := False
  else
    FreeLibrary(hnd);
  hnd := LoadLibrary('ssleay32.dll');
  if hnd = 0 then
    Result := False
  else
    FreeLibrary(hnd);
end;

var
  i, n: integer;
  op, df, dy: string;
  asource: TStringStream;

begin
  // OpenSSLライブラリをチェック
  if not CheckOpenSSL then
  begin
    Writeln('');
    Writeln('na6dlを使用するためのOpenSSLライブラリが見つかりません.');
    Writeln('以下のサイトからopenssl-1.0.2q-i386-win32.zipをダウンロードしてlibeay32.dllとssleay32.dllをna6dl.exeがあるフォルダにコピーして下さい.');
    Writeln('https://github.com/IndySockets/OpenSSL-Binaries');
    ExitCode := 2;
    Exit;
  end;
  // OpenSSLのバージョンをチェック
  if (UTF8Pos('1.0.2', GetVersionInfo('libeay32.dll')) = 0)
    or (UTF8Pos('1.0.2', GetVersionInfo('ssleay32.dll')) = 0) then
  begin
    Writeln('');
    Writeln('OpenSSLライブラリのバージョンが違います.');
    Writeln('以下のサイトからopenssl-1.0.2q-i386-win32.zipをダウンロードしてlibeay32.dllとssleay32.dllをna6dl.exeがあるフォルダにコピーして下さい.');
    Writeln('https://github.com/IndySockets/OpenSSL-Binaries');
    ExitCode := 2;
    Exit;
  end;

  if ParamCount = 0 then
  begin
    Writeln('');
    Writeln('na6dlweb ver1.0 2025/1/18 (c) INOUE, masahiro.');
    Writeln('  使用方法');
    Writeln('  na6dlweb 小説トップページのURL');
    Exit;
  end;

  ExitCode  := 0;
  FileName  := '';

  // オプション引数取得
  DelJS := False;
  for i := 0 to ParamCount - 1 do
  begin
    op := ParamStr(i + 1);
    // Naro2mobiのWindowsハンドル
    if op = '-d' then
      DelJS := True
    else
      URL := op;
  end;
  if (UTF8Pos('https://ncode.syosetu.com/n', URL) = 0) and (UTF8Pos('https://novel18.syosetu.com/n', URL) = 0) then
  begin
    Writeln('小説のURLが違います.');
    ExitCode := -1;
    Exit;
  end;
  // ベースとなる/n????????/を保存する
  if Pos('https://ncode', URL) = 1 then
  begin
    BaseURL := ReplaceRegExpr('https://ncode.syosetu.com', URL, '');
    isOver18 := False;
  end else begin
    BaseURL := ReplaceRegExpr('https://novel18.syosetu.com', URL, '');
    isOver18 := True;
  end;

  IdHTTP := TIdHTTP.Create(nil);
  IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create;
  Cookies := TIdCookieManager.Create(nil);
  RegEx := TRegExpr.Create;
  try
    IdSSL.IPVersion := Id_IPv4;
    IdSSL.MaxLineLength := 32768;
    IdSSL.SSLOptions.Method := sslvSSLv23;
    IdSSL.SSLOptions.SSLVersions := [sslvSSLv2,sslvTLSv1];
    IdHTTP.HandleRedirects := True;
    IdHTTP.AllowCookies := True;
    IdHTTP.IOHandler := IdSSL;
    // IdHTTPインスタンスにover18=yesのキャッシュを設定する
    if isOver18 then
    begin
      IdHTTP.CookieManager := TIdCookieManager.Create(IdHTTP);
      URI := TIdURI.Create('https://novel18.syosetu.com/');
      try
        IdHTTP.CookieManager.AddServerCookie('over18=yes', URI);
      finally
        URI.Free;
      end;
      asource := TStringStream.Create;
      try
        IdHTTP.Post('https://novel18.syosetu.com/', asource);
      finally
        asource.Free;
      end;
    end;

    TextLine := LoadHTMLbyIndy(URL);
    if TextLine <> '' then
    begin
      n := ParseTopPage(TextLine);
      if n  > -1 then          // 小説の目次情報を取得
      begin
        if DelJS then
          Writeln('※ -dオプションが指定されましたのでJavaScriptを削除して保存します.');
        // 短編でなければ各話を取得する
        if n > 0 then
        begin
          LoadEachPage(n);        // 小説各話情報を取得
          Writeln('目次と各エピソードを[' + FileName + ']に保存しました');
        end else if n = 0 then   // 短編
        begin
          Writeln(#13#10'短編を[' + FileName + ']に保存しました');
        end else begin
          Writeln(URL + '作品情報を取得できませんでした.');
          ExitCode := -1;
        end;
      end;
    end else begin
      Writeln(URL + 'HTMLソースを取得できませんでした.');
      ExitCode := -1;
    end;
  finally
    RegEx.Free;
    IdSSL.Free;
    IdHTTP.Free;
    Cookies.Free;
  end;
end.

