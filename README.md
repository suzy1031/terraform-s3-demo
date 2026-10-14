# terraform-s3-demo

Terraform で、東京リージョン（`ap-northeast-1`）に S3 バケットを作る最小構成です。

- パブリックアクセスをすべてブロック
- 保存時暗号化 SSE-S3（AES-256）
- 許可した CIDR 以外からのアクセスを Deny（IAM 認証は別途必要）

設計の詳細は [plan.md](plan.md)、ファイルの関係と動き方の図解は [terraform-overview.md](terraform-overview.md) を見てください。

## 準備

1. AWS 認証（環境変数または `~/.aws/credentials`）
2. Terraform CLI（1.5 以上）

公開 IP の確認（S3 が見るのは LAN の `192.168.x.x` ではなく NAT 後のアドレス）:

```bash
curl -4 https://checkip.amazonaws.com
```

解決できないときは `https://api.ipify.org` や `https://ifconfig.me`、ブラウザで <https://checkip.amazonaws.com> でも同じです。ホストは `amazonaws.com` です（`amazon.com` ではない）。

## 適用

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集します。

- `bucket_name` … 世界で一意な名前
- `allowed_cidrs` … 自分の公開 IP。1 アドレスなら `/32`。`apply` するマシンの IP も含める

実 IP と実バケット名は **git に載せない** でください。`terraform.tfvars` は `.gitignore` 済みです。リポジトリに置くのはダミーの `terraform.tfvars.example` だけです。

```bash
terraform init
terraform plan
terraform apply
```

## AWS コンソールでの確認

ブラウザの送信元も `terraform.tfvars` の許可 CIDR と一致していること。別回線・VPN だとバケット内の操作が Deny されます。

1. [AWS Management Console](https://console.aws.amazon.com/) に、Terraform と同じアカウントでサインインする
2. 画面右上のリージョンを **アジアパシフィック（東京） `ap-northeast-1`** にする（S3 バケットはグローバル一覧にも出るが、暗号化などの詳細はリージョンを合わせる）
3. 検索バーで **S3** を開き、[S3 コンソール](https://s3.console.aws.amazon.com/s3/buckets?region=ap-northeast-1) へ行く
4. バケット一覧から `bucket_name` と同じ名前をクリックする
5. **プロパティ** タブ → 「デフォルトの暗号化」が **SSE-S3 (AES-256)** になっていることを確認する
6. **アクセス許可** タブ → 「パブリックアクセスをすべてブロック」が **オン** になっていることを確認する
7. 同じ **アクセス許可** タブ → 「バケットポリシー」に `DenyAccessNotFromAllowedIPs` と、自分が入れた CIDR（`aws:SourceIp`）があることを確認する
8. **オブジェクト** タブは空でよい（今回はファイルを置かない）

コンソールのメニュー自体はアカウント権限で見えます。バケット内のオブジェクト操作や一部の設定変更は、許可 IP 以外だと `AccessDenied` になります。

## 削除

オブジェクトが入っていると失敗するので、先に中身を空にします。

```bash
terraform destroy
```

## 料金

空のバケットを置いただけなら、ほぼ料金はかかりません。保存・リクエスト・転送が発生すると課金されます。目安は [plan.md](plan.md) を参照してください。
