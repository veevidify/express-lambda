import {
	Context,
	APIGatewayProxyResult,
	APIGatewayEvent,
	APIGatewayProxyCallbackV2,
} from "aws-lambda";
import { S3PutEvent } from "./types/S3PutEvent";

export const handler = async (
	event: S3PutEvent,
	context: Context,
	callback: APIGatewayProxyCallbackV2
): Promise<APIGatewayProxyResult> => {
	console.log("==> Event: ", JSON.stringify(event, null, 2));
	console.log("==> Context: ", JSON.stringify(context, null, 2));

	const recv = event.Records.map((record) => ({
		object: record.s3.object.key,
		props: Object.keys(record.s3.object),
	}));
	const msg = "hello";

	const resp: APIGatewayProxyResult = {
		statusCode: 200,
		body: JSON.stringify({ recv, msg }),
	};

	return resp;
};
