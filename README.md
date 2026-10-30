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

どちらも起動すると管理者権限を求めるダイアログが出ます。点検・修復のほとんどが
管理者権限を必要とするためです。

初回起動時に「WindowsによってPCが保護されました」と出た場合は、
「詳細情報」→「実行」で続行できます。コード署名証明書を付けていないためで、
中身はすべてテキストの PowerShell スクリプトなので内容を確認できます。

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
│   └── Build.ps1               exe → zip → setup.exe を作る
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

`dist\` に zip と setup.exe ができます。

- `--recursive` を付け忘れた場合は `git submodule update --init --recursive` を実行してください。
- exe のコンパイルには Windows 同梱の `csc.exe`（.NET Framework 4.x）を使うため、
  開発ツールの追加インストールは不要です。
- インストーラーの作成には [Inno Setup 6](https://jrsoftware.org/isdl.php) が必要です。
  入っていなければ `winget` での導入を試み、それも失敗した場合は zip だけ作って終わります。
  最初から zip だけでよければ `.\build\Build.ps1 -SkipInstaller` を使ってください。

## リリースする手順

1. 本体に変更を入れたら、ここの submodule を進める。

```powershell
git -C app pull origin main
```

```powershell
git add app
```

```powershell
git commit -m "Update app to latest"
```

2. 先に GitHub Actions の「build」を手動実行して、ビルドが通ることを確認する。
3. 通ったらタグを押す。バージョンは本体の `lib\Core.ps1` に合わせる。

```powershell
git tag v1.0.0
```

```powershell
git push origin main --tags
```

タグを押すと Windows ランナーで本体のテスト → exe のコンパイル → zip と
インストーラーの作成まで走り、Release に添付されます。

## ライセンス

MIT License（[LICENSE](LICENSE)）。本体も同じ条件です。
