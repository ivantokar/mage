import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface MageDocsStackProps extends cdk.StackProps {
  domainName: string;
  subdomain: string;
  hostedZoneId: string;
  githubRepo: string; // GitHub repository in format "owner/repo"
}

export class MageDocsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: MageDocsStackProps) {
    super(scope, id, props);

    const fullDomain = `${props.subdomain}.${props.domainName}`;

    // Import existing hosted zone
    const hostedZone = route53.HostedZone.fromHostedZoneAttributes(this, 'MageDocsHostedZone', {
      hostedZoneId: props.hostedZoneId,
      zoneName: props.domainName,
    });

    // Create S3 bucket for static website
    const docsBucket = new s3.Bucket(this, 'MageDocsBucket', {
      bucketName: `${fullDomain}-docs`,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      // Keep docs data if the stack is removed or replaced.
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      encryption: s3.BucketEncryption.S3_MANAGED,
    });

    // Create SSL certificate in us-east-1 (required for CloudFront)
    const certificate = new acm.Certificate(this, 'MageDocsCertificate', {
      domainName: fullDomain,
      validation: acm.CertificateValidation.fromDns(hostedZone),
    });

    // Create CloudFront Origin Access Identity
    const originAccessIdentity = new cloudfront.OriginAccessIdentity(this, 'MageDocsOAI', {
      comment: `MageDocs OAI for ${fullDomain}`,
    });

    // Grant read permissions to CloudFront
    docsBucket.grantRead(originAccessIdentity);

    // Create CloudFront distribution
    const distribution = new cloudfront.Distribution(this, 'MageDocsDistribution', {
      defaultBehavior: {
        origin: new origins.S3Origin(docsBucket, {
          originAccessIdentity,
        }),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        compress: true,
      },
      domainNames: [fullDomain],
      certificate: certificate,
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 404,
          responsePagePath: '/404.html',
          ttl: cdk.Duration.minutes(5),
        },
        {
          httpStatus: 403,
          responseHttpStatus: 404,
          responsePagePath: '/404.html',
          ttl: cdk.Duration.minutes(5),
        },
      ],
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100, // US, Canada, Europe
      enableIpv6: true,
    });

    // Create Route53 A record pointing to CloudFront
    new route53.ARecord(this, 'MageDocsAliasRecord', {
      zone: hostedZone,
      recordName: props.subdomain,
      target: route53.RecordTarget.fromAlias(
        new targets.CloudFrontTarget(distribution)
      ),
    });

    // Create Route53 AAAA record for IPv6
    new route53.AaaaRecord(this, 'MageDocsAliasRecordIPv6', {
      zone: hostedZone,
      recordName: props.subdomain,
      target: route53.RecordTarget.fromAlias(
        new targets.CloudFrontTarget(distribution)
      ),
    });

    // Deploy VitePress build to S3
    new s3deploy.BucketDeployment(this, 'MageDocsDeployment', {
      sources: [s3deploy.Source.asset('../docs/.vitepress/dist')],
      destinationBucket: docsBucket,
      distribution: distribution,
      distributionPaths: ['/*'],
    });

    // GitHub Actions OIDC Provider (import existing)
    // Note: This provider should be created once per AWS account
    // Run: aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com \
    //        --client-id-list sts.amazonaws.com \
    //        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    const githubProvider = iam.OpenIdConnectProvider.fromOpenIdConnectProviderArn(
      this,
      'MageDocsGitHubProvider',
      `arn:aws:iam::${this.account}:oidc-provider/token.actions.githubusercontent.com`
    );

    // Limit trust policy to the configured repository and main branch.
    const repoPattern = `repo:${props.githubRepo}:ref:refs/heads/main`;

    // IAM Role for GitHub Actions
    const githubActionsRole = new iam.Role(this, 'MageDocsGitHubActionsRole', {
      roleName: 'MageDocsGitHubActionsRole',
      assumedBy: new iam.WebIdentityPrincipal(
        githubProvider.openIdConnectProviderArn,
        {
          StringEquals: {
            'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com',
          },
          StringLike: {
            'token.actions.githubusercontent.com:sub': repoPattern,
          },
        }
      ),
      description: 'Role for GitHub Actions to deploy Mage CLI documentation',
      maxSessionDuration: cdk.Duration.hours(1),
    });

    // Grant S3 permissions to GitHub Actions role
    docsBucket.grantReadWrite(githubActionsRole);

    // Grant CloudFront invalidation permissions
    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cloudfront:CreateInvalidation',
          'cloudfront:GetInvalidation',
        ],
        resources: [
          `arn:aws:cloudfront::${this.account}:distribution/${distribution.distributionId}`,
        ],
      })
    );

    // Grant CloudFormation read permissions (to get stack outputs)
    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cloudformation:DescribeStacks',
          'cloudformation:ListStackResources',
        ],
        resources: [this.stackId],
      })
    );

    // Grant permissions for CDK deployment
    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cloudformation:CreateChangeSet',
          'cloudformation:DeleteChangeSet',
          'cloudformation:DescribeChangeSet',
          'cloudformation:ExecuteChangeSet',
          'cloudformation:DescribeStackEvents',
          'cloudformation:GetTemplate',
        ],
        resources: [this.stackId],
      })
    );

    // Grant permissions to assume CDK roles
    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'sts:AssumeRole',
        ],
        resources: [
          `arn:aws:iam::${this.account}:role/cdk-*-deploy-role-${this.account}-${this.region}`,
          `arn:aws:iam::${this.account}:role/cdk-*-file-publishing-role-${this.account}-${this.region}`,
        ],
      })
    );

    // Grant permissions to manage CDK bootstrap resources
    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          's3:GetObject',
          's3:PutObject',
        ],
        resources: [
          `arn:aws:s3:::cdk-*-assets-${this.account}-${this.region}/*`,
        ],
      })
    );

    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          's3:ListBucket',
          's3:GetBucketLocation',
        ],
        resources: [
          `arn:aws:s3:::cdk-*-assets-${this.account}-${this.region}`,
        ],
      })
    );

    // Grant SSM parameter read access (for CDK context)
    githubActionsRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ssm:GetParameter',
        ],
        resources: [
          `arn:aws:ssm:${this.region}:${this.account}:parameter/cdk-bootstrap/*`,
        ],
      })
    );

    // Outputs
    new cdk.CfnOutput(this, 'MageDocsBucketName', {
      value: docsBucket.bucketName,
      description: 'S3 Bucket Name',
    });

    new cdk.CfnOutput(this, 'MageDocsDistributionId', {
      value: distribution.distributionId,
      description: 'CloudFront Distribution ID',
    });

    new cdk.CfnOutput(this, 'MageDocsDistributionDomainName', {
      value: distribution.distributionDomainName,
      description: 'CloudFront Distribution Domain Name',
    });

    new cdk.CfnOutput(this, 'MageDocsWebsiteURL', {
      value: `https://${fullDomain}`,
      description: 'Documentation Website URL',
    });

    new cdk.CfnOutput(this, 'MageDocsGitHubActionsRoleArn', {
      value: githubActionsRole.roleArn,
      description: 'GitHub Actions Role ARN (add this to GitHub Secrets as AWS_ROLE_ARN)',
      exportName: 'MageDocsGitHubActionsRoleArn',
    });
  }
}
