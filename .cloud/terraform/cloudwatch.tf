resource "aws_cloudwatch_log_group" "suricata_logs" {
  name = "/suricata/logs"
}

resource "aws_cloudwatch_log_stream" "suricata_stream" {
  log_group_name = aws_cloudwatch_log_group.suricata_logs.name
  name           = "suricata-log-stream"
}

