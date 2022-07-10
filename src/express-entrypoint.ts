import { createApplication } from "./express/app";
import { config } from "./config";

const app = createApplication(config);
app.listen(config.httpPort);
console.log(`Application listening on port ${config.httpPort} ...`);
