/**
 * @file index.ts
 * @description Zentraler Export-Index für alle sportwissenschaftlichen Metrik-Module.
 * Bündelt Leistungsmetriken (Rad/Lauf/Schwimmen), aerobe Entkopplung, Bestleistungen,
 * Intervallerkennung, PMC (CTL/ATL/TSB) und automatische Firestore-Trigger.
 */

export * from "./power";
export * from "./running";
export * from "./swimming";
export * from "./decoupling";
export * from "./intervals";
export * from "./pmc";
export * from "./brick";
export * from "./load";
export * from "./activityTrigger";
export * from "./recompute";
export * from "./zones";
export * from "./bests";
export * from "./diagnostics";
