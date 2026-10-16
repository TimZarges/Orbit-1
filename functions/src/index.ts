import { setGlobalOptions } from "firebase-functions/v2";

// Set default region to europe-west3 (Frankfurt) for GDPR compliance
setGlobalOptions({ region: "europe-west3" });

// 1. Auth Functions (onCall)
export { setInitialRole, deleteAccount, exportAccount } from "./auth";

// 2. Coach & Collaboration Functions
export {
  createInvite,
  redeemInvite,
  updatePermissions,
  revokeLink,
} from "./coach";
export {
  onCoachLinkChanged,
  onActivityCreatedForCoachDashboard,
} from "./coach/dashboard";
export { seedCoachAthletes } from "./seeds/seed_coach_athletes";

// 3. Metrics & Diagnostics Functions (Triggers & Callables)
export { onActivityWritten, recomputeMetrics } from "./metrics/index";

// 4. Activity Import & Storage Triggers
export { processFitUpload, processActivityUpload } from "./import/index";
export { deleteActivity } from "./import/deleteActivity";
export {
  garminAuthStart,
  garminAuthCallback,
  garminDisconnect,
  garminWebhook,
  processGarminWebhook,
  garminBackfill,
  requestGarminBackfill,
} from "./import/garmin";

// 5. Calendar Planning Trigger
export { onPlannedWorkoutWritten } from "./calendar";

// 6. Chat Messaging Trigger
export { onMessageCreated } from "./chat";

// 7. Health & Recovery Trigger
export { onDailyMetricsWritten } from "./health";
