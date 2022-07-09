import {
	Context,
	APIGatewayProxyResult,
	APIGatewayProxyEventV2,
	APIGatewayProxyCallbackV2,
} from "aws-lambda";

export const handler = async (
	event: APIGatewayProxyEventV2,
	context: Context,
	callback: APIGatewayProxyCallbackV2
): Promise<APIGatewayProxyResult> => {
	console.log("==> Event: ", JSON.stringify(event, null, 2));
	console.log("==> Context: ", JSON.stringify(context, null, 2));

	const recv = event.body;
	const msg = "hello";

	const resp: APIGatewayProxyResult = {
		statusCode: 200,
		body: JSON.stringify({ recv, msg }),
	};

	return resp;
};
