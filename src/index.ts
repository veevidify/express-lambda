import type {
	Context,
	APIGatewayProxyResult,
	APIGatewayProxyEventV2,
	APIGatewayProxyCallbackV2,
} from "aws-lambda";
import type { Request } from "express";

import createServerless from "@vendia/serverless-express";

import { createExpressApp } from "./express/app";
import { config } from "./config";

const app = createExpressApp(config);
export const handler = async (
	event: APIGatewayProxyEventV2,
	context: Context,
	callback: APIGatewayProxyCallbackV2
): Promise<APIGatewayProxyResult> => {
	console.log("==> Event: ", JSON.stringify(event, null, 2));
	console.log("==> Context: ", JSON.stringify(context, null, 2));

	if (!event.queryStringParameters) {
		event.queryStringParameters = {};
	}

	const handle = createServerless({ app });
	return handle(event, context, callback);
};
