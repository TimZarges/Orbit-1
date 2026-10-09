function calcNP(powers) {
  if (powers.length < 30) {
    let sum = 0;
    for (let p of powers) sum += p;
    return sum / powers.length;
  }
  let sum4 = 0;
  for (let i = 29; i < powers.length; i++) {
    let rollSum = 0;
    for (let j = 0; j < 30; j++) {
      rollSum += powers[i - j];
    }
    let avg30 = rollSum / 30;
    sum4 += Math.pow(avg30, 4);
  }
  let count = powers.length - 29;
  return Math.pow(sum4 / count, 0.25);
}

let arr = [];
for (let i=0; i<300; i++) arr.push(100);
for (let i=0; i<300; i++) arr.push(300);

let np = calcNP(arr);
let ftp = 200;
let iff = np / ftp;
let tss = (arr.length * np * iff) / (ftp * 3600) * 100;
console.log({np, iff, tss});
