import type { Request, Response, NextFunction } from "express";

const mainController = async (
	request: Request,
	response: Response,
	next: NextFunction
) => {
	response
		.status(200)
		.type("application/json")
		.send({
			route: `${request.method} ${request.path}`,
			message: "Main Controller: Hello",
		});
};

export default mainController;
