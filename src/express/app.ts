import express from "express";
import bodyParser from "body-parser";
import path from "path";
import cors from "cors";

import type {
	Application,
	Request,
	Response,
	NextFunction,
	Router,
	ErrorRequestHandler,
} from "express";
import type { AppConfig } from "../config";

import { ApiError } from "../utils";
import mainController from "./main-controller";

const jsonMiddleware = (
	request: Request,
	response: Response,
	next: NextFunction
) =>
	express.json()(request, response, (error) => {
		if (error) {
			const apiError = new ApiError("INVALID_JSON", error);
			next(apiError);
		} else {
			next();
		}
	});

const notFoundMiddleware = (
	request: Request,
	response: Response,
	next: NextFunction
) => {
	const apiError = new ApiError("NOT_FOUND");
	next(apiError);
};

const handleApiErrorMiddleware = (
	err: unknown,
	request: Request,
	response: Response,
	next: NextFunction
) => {
	if (response.headersSent) {
		return next(err);
	}

	if (err instanceof ApiError) {
		console.log({
			apiError: err.toString(),
			causedBy: JSON.stringify(err?.previousError),
		});
		response.status(err.code).send({
			statusCode: err.code,
			message: err.toString(),
		});
	} else {
		console.log(
			"Received unexpected error",
			JSON.stringify({
				message: (err as Partial<Error>)?.message,
				stack: (err as Partial<Error>)?.stack,
				raw: err,
			})
		);

		response.status(500).send({
			statusCode: 500,
			message: "Unknown Error.",
		});
	}
};

export const createExpressApp = (config: AppConfig): Application => {
	const router: Router = express.Router();
	router.get("/", mainController);
	router.get("/main", mainController);

	// === //

	const app: Application = express();
	app.use(bodyParser.urlencoded({ extended: true }));
	app.use(jsonMiddleware);
	app.use("/", router);
	app.use(notFoundMiddleware);
	app.use(handleApiErrorMiddleware);

	return app;
};
