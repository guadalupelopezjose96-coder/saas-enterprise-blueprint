# =============================================================================
# INFRAESTRUCTURA COMO CÓDIGO (IaC) INMUTABLE MULTI-REGIÓN Y ALMACENAMIENTO WORM
# Cumplimiento: ISO 27001 (A.8.9, A.8.13, A.8.15, A.8.24) | SLA 99.95% (RPO <5m)
# =============================================================================
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = "eu-central-1"
  default_tags {
    tags = {
      DataClassification = "Restricted"
      ComplianceScope    = "SOC2-ISO27001-GDPR"
      ManagedBy          = "Terraform-GitOps"
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = "eu-west-1"
  default_tags {
    tags = {
      DataClassification = "Restricted"
      ComplianceScope    = "SOC2-ISO27001-GDPR-BCDR"
      ManagedBy          = "Terraform-GitOps"
    }
  }
}

# 1. Clave Criptográfica Maestra Multi-Región en HSM FIPS 140-3 con Rotación Automática (CRY-02)
resource "aws_kms_key" "saas_master_key_primary" {
  provider                 = aws.primary
  description              = "Clave Maestra Multi-Region HSM FIPS 140-3 para cifrado AES-256-GCM"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  rotation_period_in_days  = 365
  multi_region             = true
  deletion_window_in_days  = 30
}

resource "aws_kms_replica_key" "saas_master_key_secondary" {
  provider                = aws.secondary
  description             = "Replica Multi-Region KMS en eu-west-1 para Failover BCDR (RTO <30m)"
  primary_key_arn         = aws_kms_key.saas_master_key_primary.arn
  deletion_window_in_days = 30
}

# 2. Repositorio de Auditoría Inmutable WORM (Write Once, Read Many - Control MON-01 / ISO 8.15)
resource "aws_s3_bucket" "worm_audit_logs" {
  provider          = aws.primary
  bucket            = "saas-prod-audit-logs-worm-compliance"
  object_lock_enabled = true
}

resource "aws_s3_bucket_public_access_block" "worm_block_public" {
  provider                = aws.primary
  bucket                  = aws_s3_bucket.worm_audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "worm_encryption" {
  provider = aws.primary
  bucket   = aws_s3_bucket.worm_audit_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.saas_master_key_primary.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_object_lock_configuration" "worm_compliance_lock" {
  provider = aws.primary
  bucket   = aws_s3_bucket.worm_audit_logs.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

# 3. Clúster Global de Base de Datos PostgreSQL (Garantiza RPO < 5 min y RTO < 30 min - BCD-01)
resource "aws_rds_global_cluster" "saas_global_postgres" {
  provider                  = aws.primary
  global_cluster_identifier = "saas-prod-eu-global-db"
  engine                    = "aurora-postgresql"
  engine_version            = "16.4"
  database_name             = "saas_prod"
  storage_encrypted         = true
  deletion_protection       = true
}

resource "aws_rds_cluster" "primary_cluster" {
  provider                  = aws.primary
  cluster_identifier        = "saas-prod-eu-primary"
  global_cluster_identifier = aws_rds_global_cluster.saas_global_postgres.id
  engine                    = aws_rds_global_cluster.saas_global_postgres.engine
  engine_version            = aws_rds_global_cluster.saas_global_postgres.engine_version
  database_name             = "saas_prod"
  master_username           = "postgres_admin"
  manage_master_user_password = true
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.saas_master_key_primary.arn
  backup_retention_period   = 35
  preferred_backup_window   = "02:00-03:00"
  deletion_protection       = true
  skip_final_snapshot       = false
}

resource "aws_rds_cluster" "secondary_bcdr_cluster" {
  provider                  = aws.secondary
  cluster_identifier        = "saas-prod-eu-secondary"
  global_cluster_identifier = aws_rds_global_cluster.saas_global_postgres.id
  engine                    = aws_rds_global_cluster.saas_global_postgres.engine
  engine_version            = aws_rds_global_cluster.saas_global_postgres.engine_version
  storage_encrypted         = true
  kms_key_id                = aws_kms_replica_key.saas_master_key_secondary.arn
  backup_retention_period   = 35
  deletion_protection       = true
  skip_final_snapshot       = false
  depends_on                = [aws_rds_cluster.primary_cluster]
}
