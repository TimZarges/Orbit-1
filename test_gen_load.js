// CTL / ATL calculation
function calcEMA(prev, current, timeConstant) {
  const alpha = 2 / (timeConstant + 1); // standard EMA or alpha = 1 - Math.exp(-1 / timeConstant)
  // Usually in TrainingPeaks CTL, alpha = Math.exp(-1/42), but many open implementations use exp(-1/tc)
  // Let's use standard exp:
  const a = Math.exp(-1 / timeConstant);
  return current * (1 - a) + prev * a;
}

let ctl = 0;
let atl = 0;
let loads = [100, 150, 0, 50, 120];

for (let load of loads) {
  ctl = calcEMA(ctl, load, 42);
  atl = calcEMA(atl, load, 7);
}
console.log({ctl, atl, tsb: ctl - atl});
