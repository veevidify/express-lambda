import { Context, APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';
import { S3PutEvent } from './types/S3PutEvent';

export const s3PutHandler = async (event: S3PutEvent): Promise<void> => {
	console.log("==> Event: ", JSON.stringify(evt, null, 2));
	console.log("==> Context: ", JSON.stringify(ctx, null, 2));

  event.Records.map((record) => console.log(record.s3.object.key));

	const resp: APIGatewayProxyResult = {
		statusCode: 200,
		body: JSON.stringify({
			msg: 'hello',
		});
	};
	return resp;
};
