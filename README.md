# PC TuneUp インストーラー

Windows 11 向けメンテナンスツール **[PC TuneUp](https://github.com/hidetako/pc-tuneup)** を、
インストールして使えるアプリ（`PCTuneUp.exe`）として配布するためのリポジトリです。

アプリ本体のソースはここにはありません。`app/` が本体リポジトリへの submodule になっています。

## 入手してインストールする

[Releases](../../releases) から次のどちらかを選んでください。

| 配布形式 | ファイル | 向いている用途 |
| --- | --- | --- |
| インストーラー | `PCTuneUp-<version>-setup.exe` | 普通に使う場合。スタートメニューに登録され、アンインストールもできます |
| インストール不要版 | `PCTuneUp-<version>-portable.zip` | 展開してすぐ使いたい、USB メモリで持ち運びたい場合 |

`SHA256SUMS.txt` も一緒に添付しています。ダウンロードしたファイルの確認に使えます
(アプリの更新機能も、これと同じファイルで整合性を確かめています)。

```powershell
Get-FileHash .\PCTuneUp-1.1.0-setup.exe -Algorithm SHA256
```

どちらも起動すると管理者権限を求めるダイアログが出ます。点検・修復のほとんどが
管理者権限を必要とするためです。

初回起動時に「WindowsによってPCが保護されました」と出た場合は、
「詳細情報」→「実行」で続行できます。コード署名証明書を付けていないためで、
中身はすべてテキストの PowerShell スクリプトなので内容を確認できます。

### 更新

起動するとバックグラウンドで [Releases](../../releases) を確認し、新しい版があれば
ウィンドウ上部に「更新する」のバーが出ます。押すまでは何もダウンロードしません。

- インストーラー版は、インストーラーを落として実行し、アプリを終了します。
  ウィザードの最後にある「PC TuneUp を実行する」でそのまま起動できます。
- インストール不要版は、動作中のフォルダーを自分で置き換えるのが危ういため、
  リリースページを開くだけにしています。展開して手動で入れ替えてください。
- ダウンロードしたファイルは、サイズと `SHA256SUMS.txt` の SHA256 を照合します。
  リリースと同じ経路で配っているチェックサムなので、転送中の破損や取り違えは防げますが、
  GitHub アカウントの乗っ取りまでは防げません。
- 確認を止めたいときは `-NoUpdateCheck` を付けて起動してください。

更新の確認先は、ビルド時に `update-channel.json` として配布物へ埋め込まれます
(`Build.ps1 -Repo <owner/repo>`)。本体リポジトリをそのままクローンした場合は
このファイルが無いので、更新の確認は行いません。

### コマンドラインから使う

点検だけを自動化したい場合など、GUI を出さずに使うときは、インストール先の
`PCTuneUp.cmd` を使ってください（`PCTuneUp.exe` でも引数は渡せますが、
コンソールが別ウィンドウで開いて閉じてしまいます）。

```powershell
& "$env:ProgramFiles\PC TuneUp\PCTuneUp.cmd" -Scan
```

使える引数は[本体の README](https://github.com/hidetako/pc-tuneup#コマンドライン)にあります。

### アンインストール

Windows の「インストールされているアプリ」から削除できます。
ログとレジストリのバックアップ（`%LOCALAPPDATA%\PCTuneUp`）は残るので、
不要であれば手動で削除してください。

## 中身

```text
pc-tuneup-desktop/
├── app/                        本体 (hidetako/pc-tuneup への submodule)
├── src/
│   ├── Launcher.cs             PCTuneUp.exe の中身。管理者権限で本体を起動するだけ
│   └── app.manifest            UAC で昇格を求めるためのマニフェスト
├── packaging/
│   └── PCTuneUp.iss            Inno Setup のインストーラー定義
├── build/
│   └── Build.ps1               exe → zip → setup.exe → SHA256SUMS.txt を作る
└── .github/workflows/release.yml   タグを押すとビルドして Release に添付
```

`PCTuneUp.exe` は本体を起動するためだけの小さなランチャーです。exe にしているのは、
UAC のダイアログにアプリ名とアイコンが出ること、スタートメニューやタスクバーに
普通のアプリとして並ぶこと、コンソールウィンドウが一瞬も出ないことの 3 点が目的です。
点検と修復のロジックはすべて本体の PowerShell スクリプト側にあります。

## 自分でビルドする

```powershell
git clone --recursive https://github.com/hidetako/pc-tuneup-desktop.git
```

```powershell
cd pc-tuneup-desktop
```

```powershell
.\build\Build.ps1
```

`dist\` に zip と setup.exe、`SHA256SUMS.txt` ができます。

- `--recursive` を付け忘れた場合は `git submodule update --init --recursive` を実行してください。
- exe のコンパイルには Windows 同梱の `csc.exe`（.NET Framework 4.x）を使うため、
  開発ツールの追加インストールは不要です。
- インストーラーの作成には [Inno Setup 6](https://jrsoftware.org/isdl.php) が必要です。
  入っていなければ `winget` での導入を試み、それも失敗した場合は zip だけ作って終わります。
  最初から zip だけでよければ `.\build\Build.ps1 -SkipInstaller` を使ってください。

## リリースする手順

ブラウザーだけで公開できます。手元に clone は要りません。

1. GitHub の **Actions** タブ → 左の **build** → 右上の **Run workflow** を開く。
2. **version** に公開するバージョン（例 `1.2.0`）を入れて **Run workflow** を押す。

1 分ほどで、本体のテスト → exe のコンパイル → zip とインストーラーの作成 → タグ `v1.2.0` の作成 →
Release の公開まで進みます。利用者のアプリは次に起動したとき、この Release を見つけて更新を案内します。

- **version を空のまま実行すると、ビルドの確認だけ行い、公開しません。** 公開前の試運転に使えます。
- バージョンは `1.2.0` のように 3 つの数字で指定します。アプリが名乗るバージョンもこの値になるので、
  本体の `lib\Core.ps1` を書き換える必要はありません。
- 既に公開済みのバージョンを指定すると、何も変更せずに失敗します。公開したファイルを差し替えることはありません。
- 公開されるのは、実行時点の `main` の内容です。

### 本体の変更を取り込むとき

本体（`hidetako/pc-tuneup`）に入れた変更は、ここの submodule を進めるまで配布物に入りません。
これだけは手元での操作が必要です。

```powershell
git -C C:\dev\pc-tuneup-desktop pull
```

```powershell
git -C C:\dev\pc-tuneup-desktop submodule update --remote app
```

```powershell
git -C C:\dev\pc-tuneup-desktop commit -am "Update app to latest"
```

```powershell
git -C C:\dev\pc-tuneup-desktop push
```

### ほかの出し方

- **Releases 画面から**: 「Draft a new release」で新しいタグ（`v1.2.0`）を付けて公開すると、
  同じビルドが走り、その Release にファイルが添付されます。リリースノートを自分で書きたいとき向け。
  添付が終わるまでの 1 分ほどは、ファイルの無い Release が見えます。
- **手元からタグを push**: `git tag -a v1.2.0 -m "PC TuneUp 1.2.0"` → `git push origin v1.2.0`。

## ライセンス

MIT License（[LICENSE](LICENSE)）。本体も同じ条件です。
