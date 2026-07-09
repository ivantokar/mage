#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { MageDocsStack } from '../lib/mage-docs-stack';

const app = new cdk.App();

const normalize = (value: string | undefined): string | undefined => {
  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : undefined;
};

const domainName =
  normalize(app.node.tryGetContext('domainName')) ?? normalize(process.env.MAGE_DOCS_DOMAIN_NAME);
const subdomain =
  normalize(app.node.tryGetContext('subdomain')) ??
  normalize(process.env.MAGE_DOCS_SUBDOMAIN) ??
  'mage';
const hostedZoneId =
  normalize(app.node.tryGetContext('hostedZoneId')) ??
  normalize(process.env.MAGE_DOCS_HOSTED_ZONE_ID);
const githubRepo =
  normalize(app.node.tryGetContext('githubRepo')) ??
  normalize(process.env.MAGE_DOCS_GITHUB_REPO) ??
  normalize(process.env.GITHUB_REPOSITORY);

if (!domainName || !hostedZoneId || !githubRepo) {
  throw new Error(
    'Missing required CDK docs config. Set domainName, hostedZoneId, githubRepo via CDK context ' +
    'or env vars (MAGE_DOCS_DOMAIN_NAME, MAGE_DOCS_HOSTED_ZONE_ID, MAGE_DOCS_GITHUB_REPO).'
  );
}

new MageDocsStack(app, 'MageDocsStack', {
  domainName,
  subdomain,
  hostedZoneId,
  githubRepo,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-east-1'
  },
  description: 'Mage CLI documentation website'
});

app.synth();
