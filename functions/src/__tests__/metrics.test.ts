import * as fs from 'fs';
import * as path from 'path';
import { calculatePowerMetrics } from '../metrics/power';
import { calculateLoadMetrics } from '../metrics/load';

describe('Metrics Core Tests', () => {
  const powerVectorsPath = path.join(__dirname, '../../../testvectors/power_metrics.json');
  const loadVectorsPath = path.join(__dirname, '../../../testvectors/load_metrics.json');
  
  if (fs.existsSync(powerVectorsPath)) {
    const powerTests = JSON.parse(fs.readFileSync(powerVectorsPath, 'utf8'));
    
    describe('Power Metrics (NP, IF, TSS)', () => {
      for (const t of powerTests) {
        it(`should pass ${t.id} - ${t.description}`, () => {
          let powerArray: number[] = [];
          if (typeof t.input.powerArray === 'string') {
            const parts = t.input.powerArray.split(',');
            for (const p of parts) {
              const [type, val, dur] = p.split(':');
              if (type === 'constant' || type === 'pattern') {
                const value = parseFloat(val);
                const duration = parseInt(dur, 10);
                for (let i = 0; i < duration; i++) {
                  powerArray.push(value);
                }
              }
            }
          }
          
          const result = calculatePowerMetrics(powerArray, t.input.ftp);
          
          expect(Math.abs(result.np - t.expected.np)).toBeLessThanOrEqual(t.tolerance);
          expect(Math.abs(result.iff - t.expected.if)).toBeLessThanOrEqual(t.tolerance);
          expect(Math.abs(result.tss - t.expected.tss)).toBeLessThanOrEqual(t.tolerance);
        });
      }
    });
  }

  if (fs.existsSync(loadVectorsPath)) {
    const loadTests = JSON.parse(fs.readFileSync(loadVectorsPath, 'utf8'));
    
    describe('Load Metrics (CTL, ATL, TSB)', () => {
      for (const t of loadTests) {
        it(`should pass ${t.id} - ${t.description}`, () => {
          const result = calculateLoadMetrics(
            t.input.dailyLoads, 
            t.input.startCtl, 
            t.input.startAtl, 
            t.input.ctlConstant, 
            t.input.atlConstant
          );
          
          expect(Math.abs(result.ctl - t.expected.ctl)).toBeLessThanOrEqual(t.tolerance);
          expect(Math.abs(result.atl - t.expected.atl)).toBeLessThanOrEqual(t.tolerance);
          expect(Math.abs(result.tsb - t.expected.tsb)).toBeLessThanOrEqual(t.tolerance);
        });
      }
    });
  }
});
