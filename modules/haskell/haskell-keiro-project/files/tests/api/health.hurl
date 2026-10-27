GET {{base_url}}/health/live
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.status" == "ok"
jsonpath "$.check" == "all"
jsonpath "$.failingSince" == null

GET {{base_url}}/health/ready
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.status" == "ok"
jsonpath "$.check" == "all"
jsonpath "$.failingSince" == null
