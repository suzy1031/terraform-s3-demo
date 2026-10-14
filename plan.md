# Terraform で S3 バケットを作成する

東京リージョン（`ap-northeast-1`）に、公開アクセスを防ぎ、サーバーサイド暗号化を有効にし、許可した CIDR 以外からのアクセスを拒否する S3 バケットを定義する。

## 作るもの

| ファイル | 役割 |
|---|---|
| `versions.tf` | Terraform 本体と AWS provider のバージョン |
| `main.tf` | リージョン、バケット、公開アクセスブロック、暗号化、IP 制限ポリシー |
| `variables.tf` | `bucket_name` と `allowed_cidrs`（デフォルトなし） |
| `outputs.tf` | 作成後に表示するバケット名と ARN |
| `terraform.tfvars.example` | 値の書き方サンプル（ダミー CIDR のみ） |
| `.gitignore` | state と実 `*.tfvars` を git に載せない |

実バケット名と実 IP はローカルの `terraform.tfvars` にだけ書く。

## リソース

- `aws_s3_bucket` … バケット本体
- `aws_s3_bucket_public_access_block` … パブリックアクセスをすべてブロック
- `aws_s3_bucket_server_side_encryption_configuration` … SSE-S3（AES-256）
- `aws_s3_bucket_policy` … 許可 CIDR 以外を `Deny`（`NotIpAddress` + `aws:SourceIp`）

Deny は「許可しない」だけで「誰でも読める」Allow ではないため、Block Public Access と両立する。許可 CIDR からでも IAM（ユーザー / ロール）は必要。

バージョン管理や静的ホスティングは含めない。VPC エンドポイント経由は今回の対象外（`aws:SourceIp` のみ）。

## 変数

- `bucket_name` … 世界で一意のバケット名
- `allowed_cidrs` … 許可する CIDR のリスト。1 アドレスなら `/32`

`terraform apply` するマシンの公開 IP も `allowed_cidrs` に含める。入っていないと、適用後に自分も弾かれる。

## 送信元 IP の確認

S3 が見るのは LAN の `192.168.x.x` ではなく、NAT 後の公開 IP。ホストは `checkip.amazonaws.com`（`amazon.com` ではない）。

```bash
curl -4 https://checkip.amazonaws.com
curl -4 https://api.ipify.org
curl -4 https://ifconfig.me
curl -4 https://icanhazip.com
```

ブラウザなら <https://checkip.amazonaws.com> でも同じ。出た IP を `terraform.tfvars` に `["<IP>/32"]` で書く。VPN 中なら VPN 出口の IP。IPv6 なら `curl -6` の結果を `/128` で追加する。

## git に実 IP を置かない

公開 IP は AWS キーほど致命的ではない（IAM なしでは入れない）が、所在や許可範囲の手がかりになる。

- 実値は gitignore した `terraform.tfvars` のみ
- リポジトリには `terraform.tfvars.example` のダミーだけ（`203.0.113.10/32`）
- 適用後のバケットポリシーは AWS 上に残るため、同じアカウントを触れる人には IP は見える

## 料金の目安

バケット作成そのものに毎月の固定費はほぼない。課金は保存量・リクエスト・データ転送。

- 空バケット: `apply` の API 数回ぶん（ごくわずか）
- 公開ブロック・暗号化・バケットポリシー: 追加料金なし
- オブジェクトを置いた場合（東京の S3 Standard 目安）: 保存 約 $0.025/GB/月、PUT 約 $0.0047/1000 回、インターネットへのダウンロードは別途
- 新規アカウントの無料利用枠（期間内）: S3 Standard 5 GB など（最新は AWS の案内を確認）

使わなくなったら `terraform destroy`。中にオブジェクトがあると失敗するので先に空にする。

## 適用手順

AWS 認証（環境変数または `~/.aws/credentials`）がある前提。

```bash
cp terraform.tfvars.example terraform.tfvars
# bucket_name と allowed_cidrs を自分の値に変更
terraform init
terraform plan
terraform apply
```

`terraform apply` は明示したときだけ実行する。

## AWS コンソールでの確認

ブラウザの送信元も `allowed_cidrs` と一致していること。別回線・VPN だとバケット内操作が Deny される。

1. [AWS Management Console](https://console.aws.amazon.com/) に、Terraform と同じアカウントでサインインする
2. リージョンを **アジアパシフィック（東京） `ap-northeast-1`** にする
3. 検索バーで **S3** を開き、[S3 コンソール](https://s3.console.aws.amazon.com/s3/buckets?region=ap-northeast-1) へ行く
4. バケット一覧から `bucket_name` と同じ名前をクリックする
5. **プロパティ** → 「デフォルトの暗号化」が **SSE-S3 (AES-256)**
6. **アクセス許可** → 「パブリックアクセスをすべてブロック」が **オン**
7. 同じタブのバケットポリシーに `DenyAccessNotFromAllowedIPs` と自分の CIDR（`aws:SourceIp`）があること
8. **オブジェクト** タブは空でよい

コンソールのメニューはアカウント権限で見える。バケット内のオブジェクト操作などは、許可 IP 以外だと `AccessDenied` になる。
