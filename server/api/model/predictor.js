// Simple logistic-regression-like predictor for demo purposes.
// Replace with a real trained model or call into a proper ML service for production.

const weights = require('./weights.json');

function dot(a, b) {
  let s = 0;
  for (let i = 0; i < Math.min(a.length, b.length); i++) s += a[i] * b[i];
  return s;
}

function sigmoid(x) {
  return 1 / (1 + Math.exp(-x));
}

function predict(features) {
  if (!Array.isArray(features)) throw new Error('features must be an array');
  const w = weights.w || [];
  const b = typeof weights.b === 'number' ? weights.b : 0;
  const score = sigmoid(dot(features, w) + b);
  return score; // 0..1 probability
}

module.exports = { predict };
