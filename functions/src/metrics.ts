import { onCall } from "firebase-functions/v2/https";

export const helloWorld = onCall((request) => {
  return { message: "Hello from ORBIT!" };
});
