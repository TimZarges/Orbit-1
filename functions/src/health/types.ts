/**
 * Typdefinitionen für das ORBIT Health & Recovery Modul (Phase 21).
 */

export interface DailyHealthInput {
  date: string;
  restingHrBpm?: number;
  hrvMs?: number;
  sleepSeconds?: number;
  deepSleepSeconds?: number;
  remSleepSeconds?: number;
  awakeSleepSeconds?: number;
  timeInBedSeconds?: number;
  sleepScore?: number;
  respirationRate?: number;
  bodyBattery?: number;
  avgStress?: number;
  activeCalories?: number;
  activitiesTss?: number;
  bedtimeIso?: string;
  wakeTimeIso?: string;
}

export interface RollingBaseline {
  mean: number;
  standardDeviation: number;
  count: number;
  normBandMin: number;
  normBandMax: number;
}

export interface UserBaselines {
  hrv?: RollingBaseline;
  rhr?: RollingBaseline;
  sleep?: RollingBaseline;
  respiration?: RollingBaseline;
  bodyBattery?: RollingBaseline;
}

export type RecoveryClassification = "GREEN" | "YELLOW" | "RED";

export interface RecoveryResult {
  score: number;
  classification: RecoveryClassification;
  recommendationDe: string;
  recommendationEn: string;
  zHrv?: number;
  zRhr?: number;
  weightsUsed: {
    hrv: number;
    rhr: number;
    sleep: number;
    respOrBb: number;
  };
}

export interface StrainTargetRange {
  min: number;
  max: number;
}

export interface DailyStrainResult {
  score: number;
  trainingTss: number;
  alltagLoad: number;
  totalRawLoad: number;
  targetRange: StrainTargetRange;
}

export interface SleepNeedResult {
  needHours: number;
  baseNeedHours: number;
  strainSurchargeHours: number;
  accumulatedDebtHours: number;
}

export interface SleepScoreResult {
  score: number;
  durationScore: number;
  efficiencyScore: number;
  stagesScore: number;
  consistencyScore: number;
}

export interface OrbitScoreResult {
  score: number;
  consistencyScore: number;
  tsbScore: number;
  recoveryAvg7d: number;
  sleepAvg7d: number;
}

export type JournalTag =
  | "lateCaffeine"
  | "alcohol"
  | "muscleSoreness"
  | "highStress"
  | "poorFeeling"
  | "goodHydration"
  | "lateMeal"
  | "travelAltitude";

export type JournalData = Partial<Record<JournalTag, boolean>>;

export interface CorrelationInsight {
  tag: JournalTag;
  sampleSizeWithTag: number;
  sampleSizeWithoutTag: number;
  metric: "hrv" | "rhr" | "deepSleep" | "recovery";
  delta: number;
  percentChange: number;
  insightDe: string;
  insightEn: string;
}
