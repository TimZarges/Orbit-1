import { setGlobalOptions } from "firebase-functions/v2";

// Set default region to europe-west3 (Frankfurt) for GDPR compliance
setGlobalOptions({ region: "europe-west3" });

export * from "./metrics";
export * from "./auth";
export * from "./coach";
export * from './import/index';
