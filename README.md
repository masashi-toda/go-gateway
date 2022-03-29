# go-gateway

# create accesslog table for Athena
CREATE EXTERNAL TABLE IF NOT EXISTS accesslogs
(
level string,
time string,
status int,
method string,
path string, query string,
protocol string,
client_ip string,
useragent string,
referer string,
latency string,
server string,
container_name string,
body map < string, string >,
message string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://api-server-dev-deliverylog/2022/03/'

# other
https://zenn.dev/bun913/articles/c25765744352a4
