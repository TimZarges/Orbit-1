import { isQuietTime } from '../chat';

describe('Chat & Notification Quiet Time Tests', () => {
  it('identifies quiet time when within day window (e.g. 13:00 to 15:00)', () => {
    const duringQuiet = new Date('2026-10-13T14:30:00');
    expect(isQuietTime('13:00', '15:00', duringQuiet)).toBe(true);

    const outsideQuiet = new Date('2026-10-13T16:00:00');
    expect(isQuietTime('13:00', '15:00', outsideQuiet)).toBe(false);
  });

  it('identifies quiet time spanning across midnight (e.g. 22:00 to 07:00)', () => {
    // 23:30 is quiet
    const lateNight = new Date('2026-10-13T23:30:00');
    expect(isQuietTime('22:00', '07:00', lateNight)).toBe(true);

    // 05:15 is quiet
    const earlyMorning = new Date('2026-10-13T05:15:00');
    expect(isQuietTime('22:00', '07:00', earlyMorning)).toBe(true);

    // 14:00 is not quiet
    const daytime = new Date('2026-10-13T14:00:00');
    expect(isQuietTime('22:00', '07:00', daytime)).toBe(false);
  });

  it('returns false when quiet hours are not set', () => {
    const now = new Date();
    expect(isQuietTime(undefined, undefined, now)).toBe(false);
    expect(isQuietTime('22:00', undefined, now)).toBe(false);
  });
});
