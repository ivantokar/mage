# Mage Docs CDK Infrastructure

AWS CDK infrastructure for hosting the Mage CLI documentation on `mage.ivantokar.com`.

## Architecture

- **S3 Bucket** - Stores static VitePress site
- **CloudFront Distribution** - CDN with HTTPS
- **ACM Certificate** - SSL/TLS certificate for `mage.ivantokar.com`
- **Route53** - DNS records under the `ivantokar.com` hosted zone
- **IAM Role** - GitHub Actions OIDC authentication (keyless deployment)

## Prerequisites

- AWS CLI configured with credentials
- AWS CDK CLI installed: `npm install -g aws-cdk`
- VitePress docs built: `npm run docs:build` (in parent directory)

## One-Time Setup

### 1. Create GitHub OIDC Provider (first time only, per AWS account)

Skip this if the provider already exists in the account (e.g. it was already created for another repo's docs deploy):

```bash
aws iam list-open-id-connect-providers
```

If it's missing:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Bootstrap CDK (first time only, per account/region)

```bash
aws sts get-caller-identity --query Account --output text
cdk bootstrap aws://ACCOUNT-ID/us-east-1
```

## Deployment

### 1. Install dependencies

```bash
npm install
npm install --prefix cdk
```

### 2. Build documentation

```bash
npm run docs:build
```

This creates `docs/.vitepress/dist/` with the static site.

### 3. Synthesize / Deploy

```bash
cd cdk
MAGE_DOCS_DOMAIN_NAME=ivantokar.com \
MAGE_DOCS_HOSTED_ZONE_ID=Z09725413QNQ5IE4K1JNK \
MAGE_DOCS_SUBDOMAIN=mage \
MAGE_DOCS_GITHUB_REPO=ivantokar/mage \
npm run synth   # or: npm run deploy
```

This will:
1. Create the S3 bucket
2. Request an ACM certificate (auto-validated via Route53 DNS)
3. Create the CloudFront distribution
4. Create Route53 A/AAAA alias records for `mage.ivantokar.com`
5. Deploy the VitePress site to S3

**Note:** Certificate validation may take 5-10 minutes.

### 4. Configure GitHub Actions

After the first deploy, copy the `MageDocsGitHubActionsRoleArn` output:

```bash
aws cloudformation describe-stacks \
  --stack-name MageDocsStack \
  --query 'Stacks[0].Outputs[?OutputKey==`MageDocsGitHubActionsRoleArn`].OutputValue' \
  --output text
```

Then, on `ivantokar/mage`:
1. **Settings → Secrets and variables → Actions → Secrets** — add `AWS_ROLE_ARN` with the role ARN above.
2. **Settings → Secrets and variables → Actions → Variables** — add:
   - `MAGE_DOCS_DOMAIN_NAME` = `ivantokar.com`
   - `MAGE_DOCS_HOSTED_ZONE_ID` = `Z09725413QNQ5IE4K1JNK`
   - `MAGE_DOCS_SUBDOMAIN` = `mage`

After that, `.github/workflows/deploy-docs.yml` redeploys automatically on every push to `main` that touches `docs/**` or `cdk/**`.

## Updating Documentation

```bash
npm run docs:build
cd cdk
MAGE_DOCS_DOMAIN_NAME=ivantokar.com \
MAGE_DOCS_HOSTED_ZONE_ID=Z09725413QNQ5IE4K1JNK \
MAGE_DOCS_SUBDOMAIN=mage \
MAGE_DOCS_GITHUB_REPO=ivantokar/mage \
npm run deploy
```

## Useful Commands

```bash
npm run diff      # show differences between deployed and local
npm run destroy    # destroy stack (docs bucket is retained)
npm run synth       # synthesize CloudFormation template
npx cdk list
```

## Security

- S3 bucket is private (no public access, CloudFront OAI only)
- HTTPS enforced (HTTP redirects to HTTPS)
- ACM certificate auto-renewed
- GitHub Actions authenticates via OIDC (no long-lived AWS credentials)
- IAM role trust is limited to `ivantokar/mage`, `main` branch only

## Note on subdomain reuse

`mage.ivantokar.com` was previously reserved by the `mage-node` repo's docs stack (`MageNodeDocsStack`) before that project was renamed from "Mage" to "MageNode". That deploy has been failing since the rename (its GitHub variable names were never updated to match), so this stack reclaims the subdomain for the current Mage CLI. If `mage-node`'s docs are revived later, point them at a different subdomain.
