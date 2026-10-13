import { estimateFtp, estimateRunThresholds, estimateCss } from '../metrics/diagnostics';

describe('Diagnostics & Threshold Estimators', () => {
  describe('estimateFtp', () => {
    it('creates FTP proposal for steady 20-min effort', () => {
      const res = estimateFtp(300, 306, 270, '2026-10-13');
      expect(res.hasProposal).toBe(true);
      expect(res.proposedValue).toBe(285);
      expect(res.delta).toBe(15);
      expect(res.confidence).toBe('HIGH');
    });

    it('rejects proposal when pacing is erratic (VI > 1.15)', () => {
      const res = estimateFtp(300, 360, 270, '2026-10-13');
      expect(res.hasProposal).toBe(false);
      expect(res.reasonForNoProposal).toContain('VI > 1.15');
    });

    it('rejects proposal when delta is below relevance threshold (< 3W and < 1.5%)', () => {
      const res = estimateFtp(285, 290, 270, '2026-10-13'); // 285 * 0.95 = 271 -> delta = 1W
      expect(res.hasProposal).toBe(false);
      expect(res.reasonForNoProposal).toContain('Relevanzschwelle');
    });
  });

  describe('estimateRunThresholds', () => {
    it('creates LTHR and pace proposals from 30-min run test', () => {
      const { lthr, pace } = estimateRunThresholds(174, 270, 2.5, 168, 285, '2026-10-13');
      expect(lthr.hasProposal).toBe(true);
      expect(lthr.proposedValue).toBe(174);
      expect(lthr.confidence).toBe('HIGH');

      expect(pace.hasProposal).toBe(true);
      expect(pace.proposedValue).toBe(270);
    });

    it('rejects LTHR when heart rate is erratic (std dev > 8 bpm)', () => {
      const { lthr } = estimateRunThresholds(174, 270, 9.5, 168, 285, '2026-10-13');
      expect(lthr.hasProposal).toBe(false);
    });
  });

  describe('estimateCss', () => {
    it('calculates CSS from 400m and 200m time trials', () => {
      const res = estimateCss(360, 160, 105, '2026-10-13');
      expect(res.hasProposal).toBe(true);
      expect(res.proposedValue).toBe(100);
      expect(res.delta).toBe(-5);
      expect(res.confidence).toBe('HIGH');
    });

    it('rejects when 400m time is less than 200m time', () => {
      const res = estimateCss(180, 200, 105, '2026-10-13');
      expect(res.hasProposal).toBe(false);
    });
  });
});
