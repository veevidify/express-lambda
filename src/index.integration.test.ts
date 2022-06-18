import AWS from "aws-sdk";
import {
	PutObjectRequest,
	DeleteObjectsRequest,
	ListObjectsV2Request,
	ListObjectsV2Output,
} from "aws-sdk/clients/s3";

const s3Client = new AWS.S3({
	endpoint: "http://localhost:4566",
	s3ForcePathStyle: true,
});
AWS.config.update({ region: "ap-southeast-2" });

const localConfigs = {
	name: "simple-bucket",
};

const PREFIX_OBJ = "integ-test-";
const cleanupLocalstack = async () => {
	const listParams: ListObjectsV2Request = {
		Bucket: localConfigs.name,
	};
	const getObjectsResp = await s3Client.listObjectsV2(listParams).promise();
	const objects = getObjectsResp.$response.data as ListObjectsV2Output;
	const deleteRequest = (objects.Contents ?? [])
		.filter((s3Obj) => s3Obj.Key)
		.filter((s3Obj) => s3Obj.Key!.startsWith(PREFIX_OBJ))
		.map((s3Obj) => {
			const deleteParams: DeleteObjectsRequest = {
				Bucket: localConfigs.name,
				Delete: {
					Objects: [
						{
							Key: s3Obj.Key!,
						},
					],
				},
			};
			return s3Client.deleteObjects(deleteParams).promise();
		});

	await Promise.all(deleteRequest);
};

describe("testing lambda with localstack", () => {
	afterAll(cleanupLocalstack);

	describe("lambda handler", () => {
		it("should listen & react to s3 put event", async () => {
			// kinda just observe in the terminal using
			// scripts/tail-lambda-log.sh
			const putObjParams: PutObjectRequest = {
				Bucket: localConfigs.name,
				Key: `${PREFIX_OBJ}test-object`,
				Body: "just testing",
			};
			await s3Client.putObject(putObjParams).promise();
		});
	});
});
