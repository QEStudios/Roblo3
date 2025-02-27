local auth = require(script.Parent.Utilities.Authentication)
local requester = require(script.Parent.Utilities.Requester)

local request = requester.request
local toJson = requester.toJson
local toTable = requester.toTable
local toDdbJson = requester.toDdbJson
local fromDdbJson = requester.fromDdbJson

local function get_timezone_offset(ts)
	local utcdate   = os.date("!*t", ts)
	local localdate = os.date("*t", ts)
	localdate.isdst = false -- this is the trick
	return os.difftime(os.time(localdate), os.time(utcdate))
end

local function requestTime()
	local requestTime = os.time() - get_timezone_offset()
	local datestamp = os.date("%Y%m%d", requestTime)
	local amzdate = os.date("%Y%m%dT%H%M%SZ", requestTime)
	return datestamp, amzdate
end

local function serviceResource(accessKeyId, secretAccessKey, region)
	local ddb = {}
	local secrets = {}

	secrets.secretAccessKey = secretAccessKey
	secrets.accessKeyId = accessKeyId

	ddb.algorithm = "AWS4-HMAC-SHA256"
	ddb.region = region
	ddb.service = "dynamodb"
	ddb.endpoint = "https://dynamodb."..ddb.region..".amazonaws.com"

	function ddb:Table(tableName)
		if self ~= ddb then error("Table must be called with `:`, not `.`", 2) end
		if tableName == nil then error("`tableName` is a required parameter", 2) end

		self.ddbTable = {}
		local ddbTable = self.ddbTable
		ddbTable.Name = tableName

		function ddbTable:DeleteItem(kwargs)
			if self ~= ddbTable then error("`DeleteItem` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["Key"] = {}
			toDdbJson(kwargs["Key"], ddbJson["Key"])
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConditionExpression"] = kwargs["ConditionExpression"]
			ddbJson["ExpressionAttributeNames"] = kwargs["ExpressionAttributeNames"]
			if kwargs["ExpressionAttributeValues"] ~= nil then
				ddbJson["ExpressionAttributeValues"] = {}
				toDdbJson(kwargs["ExpressionAttributeValues"], ddbJson["ExpressionAttributeValues"])
			end
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			ddbJson["ReturnItemCollectionMetrics"] = kwargs["ReturnItemCollectionMetrics"]
			ddbJson["ReturnValues"] = kwargs["ReturnValues"]

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.DeleteItem",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
				if bodyData.Attributes ~= nil then 
					responseData["Attributes"] = {}
					fromDdbJson(bodyData.Attributes, responseData["Attributes"])
				end
				if bodyData.ItemCollectionMetrics ~= nil then
					responseData["ItemCollectionMetrics"] = {}
					responseData["ItemCollectionMetrics"]["ItemCollectionKey"] = {}
					responseData["ItemCollectionMetrics"]["SizeEstimateRangeGB"] = bodyData["ItemCollectionMetrics"]["SizeEstimateRangeGB"]
					fromDdbJson(bodyData["ItemCollectionMetrics"]["ItemCollectionKey"], responseData["ItemCollectionMetrics"]["ItemCollectionKey"])
				end
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:GetItem(kwargs)
			if self ~= ddbTable then error("`GetItem` must be called with `:`, not `.`", 2) end
			if type(kwargs["Key"]) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["Key"] = {}
			toDdbJson(kwargs["Key"], ddbJson["Key"])
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConsistentRead"] = kwargs["ConsistentRead"] or false
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			ddbJson["ExpressionAttributeNames"] = kwargs["ExpressionAttributeNames"]
			ddbJson["ProjectionExpression"] = kwargs["ProjectionExpression"]

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.GetItem",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local item = {}
				if bodyData.Item ~= nil then
					fromDdbJson(bodyData.Item, item)
				else
					item = nil
				end
				return item, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:GetTableInfo()
			if self ~= ddbTable then error("`UpdateItem` must be called with `:`, not `.`", 2) end
			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = '{"TableName": "'..self.Name..'"}'
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.DescribeTable",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseData = response.Response
				local body = responseData.Body
				local data = toTable(body)
				return data.Table
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:PutItem(kwargs)
			if self ~= ddbTable then error("`PutItem` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["Item"] = {}
			toDdbJson(kwargs["Item"], ddbJson["Item"], false)
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConditionExpression"] = kwargs["ConditionExpression"]
			ddbJson["ExpressionAttributeNames"] = kwargs["ExpressionAttributeNames"]
			if kwargs["ExpressionAttributeValues"] ~= nil then
				ddbJson["ExpressionAttributeValues"] = {}
				toDdbJson(kwargs["ExpressionAttributeValues"], ddbJson["ExpressionAttributeValues"])
			end
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			ddbJson["ReturnItemCollectionMetrics"] = kwargs["ReturnItemCollectionMetrics"]
			ddbJson["ReturnValues"] = kwargs["ReturnValues"]

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.PutItem",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
				if bodyData.Attributes ~= nil then 
					responseData["Attributes"] = {}
					fromDdbJson(bodyData.Attributes, responseData["Attributes"])
				end
				if bodyData.ItemCollectionMetrics ~= nil then
					responseData["ItemCollectionMetrics"] = {}
					responseData["ItemCollectionMetrics"]["ItemCollectionKey"] = {}
					responseData["ItemCollectionMetrics"]["SizeEstimateRangeGB"] = bodyData["ItemCollectionMetrics"]["SizeEstimateRangeGB"]
					fromDdbJson(bodyData["ItemCollectionMetrics"]["ItemCollectionKey"], responseData["ItemCollectionMetrics"]["ItemCollectionKey"])
				end
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:UpdateItem(kwargs)
			if self ~= ddbTable then error("`UpdateItem` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["Key"] = {}
			toDdbJson(kwargs["Key"], ddbJson["Key"])
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConditionExpression"] = kwargs["ConditionExpression"]
			ddbJson["ExpressionAttributeNames"] = kwargs["ExpressionAttributeNames"]
			if kwargs["ExpressionAttributeValues"] ~= nil then
				ddbJson["ExpressionAttributeValues"] = {}
				toDdbJson(kwargs["ExpressionAttributeValues"], ddbJson["ExpressionAttributeValues"])
			end
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			ddbJson["ReturnItemCollectionMetrics"] = kwargs["ReturnItemCollectionMetrics"]
			ddbJson["ReturnValues"] = kwargs["ReturnValues"]
			ddbJson["UpdateExpression"] = kwargs["UpdateExpression"]

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.UpdateItem",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
				if bodyData.Attributes ~= nil then 
					responseData["Attributes"] = {}
					fromDdbJson(bodyData.Attributes, responseData["Attributes"])
				end
				if bodyData.ItemCollectionMetrics ~= nil then
					responseData["ItemCollectionMetrics"] = {}
					responseData["ItemCollectionMetrics"]["ItemCollectionKey"] = {}
					responseData["ItemCollectionMetrics"]["SizeEstimateRangeGB"] = bodyData["ItemCollectionMetrics"]["SizeEstimateRangeGB"]
					fromDdbJson(bodyData["ItemCollectionMetrics"]["ItemCollectionKey"], responseData["ItemCollectionMetrics"]["ItemCollectionKey"])
				end
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:Query(kwargs)
			if self ~= ddbTable then error("`Query` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConsistentRead"] = kwargs["ConsistentRead"] or false
			if kwargs["ExclusiveStartKey"] ~= nil then
				ddbJson["ExclusiveStartKey"] = kwargs["ExclusiveStartKey"]
			end
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			if kwargs["ExpressionAttributeNames"] ~= nil then
				ddbJson["ExpressionAttributeNames"] = kwargs["ExpressionAttributeNames"]
			end
			if kwargs["ExpressionAttributeValues"] ~= nil then
				ddbJson["ExpressionAttributeValues"] = {}
				toDdbJson(kwargs["ExpressionAttributeValues"], ddbJson["ExpressionAttributeValues"])
			end
			if kwargs["FilterExpression"] ~= nil then
				ddbJson["FilterExpression"] = kwargs["FilterExpression"]
			end
			if kwargs["IndexName"] ~= nil then
				ddbJson["IndexName"] = kwargs["IndexName"]
			end
			if kwargs["KeyConditionExpression"] ~= nil then
				ddbJson["KeyConditionExpression"] = kwargs["KeyConditionExpression"]
			end
			if kwargs["Limit"] ~= nil then
				ddbJson["Limit"] = kwargs["Limit"]
			end
			if kwargs["ProjectionExpression"] ~= nil then
				ddbJson["ProjectionExpression"] = kwargs["ProjectionExpression"]
			end
			if kwargs["ScanIndexForward"] ~= nil then
				ddbJson["ScanIndexForward"] = kwargs["ScanIndexForward"]
			end
			if kwargs["Select"] ~= nil then
				ddbJson["Select"] = kwargs["Select"]
			end

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.Query",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
				responseData["Count"] = bodyData.Count
				if bodyData.Items ~= nil then
					responseData["Items"] = {}
					for key,value in pairs(bodyData.Items) do
						responseData["Items"][key] = {}
						fromDdbJson(value, responseData["Items"][key])
					end
				end
				responseData["LastEvaluatedKey"] = bodyData.LastEvaluatedKey
				responseData["ScannedCount"] = bodyData.ScannedCount
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:Scan(kwargs)
			if self ~= ddbTable then error("`Scan` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConsistentRead"] = kwargs["ConsistentRead"] or false
			if kwargs["ExclusiveStartKey"] ~= nil then
				ddbJson["ExclusiveStartKey"] = kwargs["ExclusiveStartKey"]
			end
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			if kwargs["ExpressionAttributeNames"] ~= nil then
				ddbJson["ExpressionAttributeNames"] = kwargs["ExpressionAttributeNames"]
			end
			if kwargs["ExpressionAttributeValues"] ~= nil then
				ddbJson["ExpressionAttributeValues"] = {}
				toDdbJson(kwargs["ExpressionAttributeValues"], ddbJson["ExpressionAttributeValues"])
			end
			if kwargs["FilterExpression"] ~= nil then
				ddbJson["FilterExpression"] = kwargs["FilterExpression"]
			end
			if kwargs["IndexName"] ~= nil then
				ddbJson["IndexName"] = kwargs["IndexName"]
			end
			if kwargs["Limit"] ~= nil then
				ddbJson["Limit"] = kwargs["Limit"]
			end
			if kwargs["ProjectionExpression"] ~= nil then
				ddbJson["ProjectionExpression"] = kwargs["ProjectionExpression"]
			end
			if kwargs["Segment"] ~= nil then
				ddbJson["Segment"] = kwargs["Segment"]
			end
			if kwargs["Select"] ~= nil then
				ddbJson["Select"] = kwargs["Select"]
			end
			if kwargs["TotalSegments"] ~= nil then
				ddbJson["TotalSegments"] = kwargs["TotalSegments"]
			end

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.Scan",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
				responseData["Count"] = bodyData.LastEvaluatedKey
				responseData["Items"] = {}
				for key,value in pairs(bodyData.Items) do
					responseData["Items"][key] = {}
					fromDdbJson(value, responseData["Items"][key])
				end
				responseData["LastEvaluatedKey"] = bodyData.LastEvaluatedKey
				responseData["ScannedCount"] = bodyData.ScannedCount
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		function ddbTable:ExecuteStatement(kwargs)
			if self ~= ddbTable then error("`ExecuteStatement` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["ConsistentRead"] = kwargs["ConsistentRead"] or false
			ddbJson["Statement"] = kwargs["Statement"]
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"
			if kwargs["Limit"] ~= nil then
				ddbJson["Limit"] = kwargs["Limit"]
			end
			if kwargs["NextToken"] ~= nil then
				ddbJson["NextToken"] = kwargs["NextToken"]
			end
			if kwargs["Parameters"] ~= nil then
				ddbJson["Parameters"] = {}
				toDdbJson(kwargs["Parameters"], ddbJson["Parameters"])
			end
			if kwargs["ReturnValuesOnConditionCheckFailure"] ~= nil then
				ddbJson["ReturnValuesOnConditionCheckFailure"] = kwargs["ReturnValuesOnConditionCheckFailure"]
			end

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.ExecuteStatement",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
				if bodyData.NextToken ~= nil then
					responseData["NextToken"] = bodyData.NextToken
				end
				responseData["Items"] = {}
				for key,value in pairs(bodyData.Items) do
					responseData["Items"][key] = {}
					fromDdbJson(value, responseData["Items"][key])
				end
				responseData["LastEvaluatedKey"] = bodyData.LastEvaluatedKey
				responseData["ScannedCount"] = bodyData.ScannedCount
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

        function ddbTable:BatchExecuteStatement(kwargs)
			if self ~= ddbTable then error("`BatchExecuteStatement` must be called with `:`, not `.`", 2) end
			if type(kwargs) ~= "table" then error("`kwargs` must be a table", 2) end
			local ddbJson = {}
			ddbJson["TableName"] = ddbTable.Name
			ddbJson["Statements"] = kwargs["Statements"]
			ddbJson["ReturnConsumedCapacity"] = kwargs["ReturnConsumedCapacity"] or "TOTAL"

			local datestamp, amzdate = requestTime()

			local method = "POST"
			local query = {}
			local payload = toJson(ddbJson)
			local path = ""
			local headers = {
				["Host"] = "dynamodb."..ddb.region..".amazonaws.com",
				["x-amz-date"] = amzdate,
				["x-amz-target"] = "DynamoDB_20120810.ExecuteStatement",
				["Content-Type"] = "application/x-amz-json-1.0"
			}

			local authItems = {
				["method"] = method,
				["algorithm"] = ddb.algorithm,
				["datestamp"] = datestamp,
				["amzdate"] = amzdate,
				["region"] = ddb.region,
				["service"] = ddb.service,
				["secretAccessKey"] = secrets.secretAccessKey,
				["accessKeyId"] = secrets.accessKeyId,
				["payload"] = payload,
				["path"] = path,
				["headers"] = headers,
				["query"] = query
			}

			local authHeader, canonicalQueryString = auth.formAuthenticationHeader(authItems)

			headers["Authorization"] = authHeader
			headers["Host"] = nil

			local url = ddb.endpoint .. path
			if canonicalQueryString ~= "" then url = url .. "?" .. canonicalQueryString end
			local requestParams = {
				["Url"] = url,
				["Method"] = method,
				["Headers"] = headers,
				["Body"] = payload
			}
			local response = request(requestParams)
			if response.Success then
				local responseDataRaw = response.Response
				local body = responseDataRaw.Body
				local bodyData = toTable(body)
				local responseData = {}
                responseData["Responses"] = bodyData.Responses
				if bodyData.ConsumedCapacity ~= nil then
					responseData["ConsumedCapacity"] = bodyData.ConsumedCapacity
				end
				if responseData == {} then responseData = nil end
				return responseData, bodyData, response
			else
				error(response.ErrorType..": "..response.ErrorMessage, 2)
			end
		end

		return ddbTable
	end

	return ddb
end

return { serviceResource = serviceResource }