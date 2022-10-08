import { createExpressApp } from "./express/app";
import { config } from "./config";

const app = createExpressApp(config);
app.listen(config.httpPort);
console.log(`Application listening on port ${config.httpPort} ...`);
