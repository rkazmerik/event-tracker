resource "aws_glue_catalog_database" "events_db" {
  name = "events_db"
  tags = local.common_tags
}

resource "aws_glue_catalog_table" "events_table" {
  name          = "events"
  database_name = aws_glue_catalog_database.events_db.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.event_data_bucket.bucket}/events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed    = true

    ser_de_info {
      name                  = "json"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = { "serialization.format" = "1" }
    }

    columns {
      name = "browser"
      type = "string"
    }
    columns {
      name = "device"
      type = "string"
    }
    columns {
      name = "event_id"
      type = "string"
    }
    columns {
      name = "event_type"
      type = "string"
    }
    columns {
      name = "event_timestamp"
      type = "timestamp"
    }
    columns {
      name = "ip_address"
      type = "string"
    }
    columns {
      name = "page"
      type = "string"
    }
    columns {
      name = "server_ingestion_time"
      type = "timestamp"
    }
    columns {
      name = "user_id"
      type = "string"
    }
  }

  partition_keys {
    name = "event_date"
    type = "string"
  }

  parameters = {
    "classification" = "json"
    "compressionType" = "gzip"
    "typeOfData" = "file"
    "projection.enabled" = "true"
    "projection.event_date.type" = "date"
    "projection.event_date.format" = "yyyy-MM-dd"
    "projection.event_date.range" = "2024-06-01,NOW"
    "projection.event_date.interval" = "1"
    "projection.event_date.interval.unit" = "DAYS"
    "storage.location.template" = "s3://${aws_s3_bucket.event_data_bucket.bucket}/events/event_date=$${event_date}/"
  }
}