const functions = require("firebase-functions");
const {setGlobalOptions} = require("firebase-functions");

setGlobalOptions({maxInstances: 10});

exports.verifyOrderNumber = functions.https.onRequest((req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const orderNumber = parseInt(req.body.orderNumber);
  if (isNaN(orderNumber)) {
    res.json({isValid: false, orderId: null});
    return;
  }

  const isPrime = (n) => {
    if (n < 2) return false;
    for (let i = 2; i <= Math.sqrt(n); i++) {
      if (n % i === 0) return false;
    }
    return true;
  };

  res.json({
    isValid: isPrime(orderNumber),
    orderId: String(orderNumber),
  });
});
