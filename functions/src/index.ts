import { setGlobalOptions } from "firebase-functions/v2";

// Set default region to europe-west3 (Frankfurt) for GDPR compliance
setGlobalOptions({ region: "europe-west3" });

export * from "./metrics/index";
export * from "./auth";
export * from "./coach";
export * from './import/index';
export * from "./calendar";
export * from "./chat";
export * from "./notifications";
