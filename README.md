### narouweb-downloader
na6dlwebは小説家になろうおよび姉妹サイトで公開されている小説をHTML形式のままでダウンロードするためのツールです。URLが//ncode.syosetu.com/および//novel18.syosetu.com/で始まる作品をダウンロードしてHTMLファイルとして保存します。

### 動作環境
Windows10/11上のコマンドプロンプト上で動作します。

### 実行に必要なファイル
~~na6dlweb.exeの実行にはopenssl-1.0.2が必要です。ssleay32.dllとlibeay32.dllがna6dl.exeと同じディレクトリー内もしくはPATHの通った場所にある必要があります。尚、リリースアーカイブに必要なライブラリが同梱されています。
https://github.com/IndySockets/OpenSSL-Binaries~~<br>
**HTML取得をIndyからWinInetに変更したためIndyライブラリは不要となりました。**

### 実行ファイルの作り方
* Delphi (XE2以降)：na6dlweb.dprojを開いてビルドしてください。尚、ビルドするためにはIndy10ライブラリとTregExprライブラリが必要です。
* TregExprライブラリ：https://github.com/andgineer/TRegExpr

### 使い方
コマンドプロンプト上で、<br>
na6dlweb ダウンロードしたいなろう系小説トップページのURLと入力して実行キーを押します。正常に実行されればna6dlweb.exeがあるフォルダに作品タイトル名のフォルダが作成され、その中にトップページにアクセスするための「タイトル名.html」が、サブフォルダ「html」内に目次HTMLと各話HTMLファイルが格納されます。


### 禁止事項
1. na6dlを用いてWeb小 説サイトからダウンロードしたHTMLァイルの第三者への販売や不特定多数への配信。 
2. ダウンロードしたオリジナル作品を著作者の了解なく加工（文章の流用や作品の翻訳等）しての再公開。 
3. その他、著作者の権利を踏みにじるような行為。 


### ライセンス
MIT
