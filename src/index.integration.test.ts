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
};

const PREFIX_OBJ = "integ-test-";
describe("testing lambda with localstack apigateway", () => {
	describe("lambda handler", () => {
		it("should handle http request", async () => {
		
		});
	});
});
