const Razorpay = require('razorpay');
const crypto = require('crypto');
const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

// Initialize Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_mock',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'mock_secret',
});

/**
 * SAFEGUARD #2: SERVER-SIDE SOVEREIGNTY
 * Amounts are calculated based on property data from Firestore, not from request body.
 */
exports.createOrder = asyncHandler(async (req, res) => {
  const { propertyId, bookingId, type } = req.body;
  const userId = req.user.uid;

  // 1. Fetch Property and Booking Data
  const propertyDoc = await db.collection('properties').doc(propertyId).get();
  const bookingDoc = await db.collection('bookings').doc(bookingId).get();

  if (!propertyDoc.exists || !bookingDoc.exists) {
    return res.status(404).json({ success: false, error: 'Property or Booking not found' });
  }

  const propertyData = propertyDoc.data();
  const bookingData = bookingDoc.data();

  // 2. Calculate Amount based on Type
  let amount = 0;
  let currency = 'INR';

  switch (type) {
    case 'reservationFee':
      amount = 1000; // Fixed MVP reservation fee
      break;
    case 'deposit':
      amount = propertyData.pricing?.deposit || 0;
      break;
    case 'firstMonthRent':
      amount = propertyData.pricing?.singleRent || 0;
      break;
    default:
      return res.status(400).json({ success: false, error: 'Invalid payment type' });
  }

  if (amount <= 0) {
    return res.status(400).json({ success: false, error: 'Invalid amount calculated' });
  }

  // 3. Create Razorpay Order
  const options = {
    amount: amount * 100, // in paisa
    currency: currency,
    receipt: `receipt_${bookingId}_${Date.now()}`,
    notes: {
      bookingId: bookingId,
      userId: userId,
      propertyId: propertyId,
      paymentType: type
    }
  };

  const order = await razorpay.orders.create(options);

  // 4. Create Transaction Record (Status: CREATED)
  await db.collection('transactions').add({
    bookingId: bookingId,
    userId: userId,
    propertyId: propertyId,
    amount: amount,
    transactionType: type,
    status: 'created',
    paymentGateway: 'RAZORPAY',
    gatewayOrderId: order.id,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  res.json({
    success: true,
    orderId: order.id,
    amount: amount,
    currency: currency
  });
});

/**
 * SAFEGUARD #1: IDEMPOTENCY PROTECTION
 * SAFEGUARD #3: POST-VERIFICATION ESCROW
 * SAFEGUARD #4: PAYMENT EVENT AUDIT
 */
exports.verifyPayment = asyncHandler(async (req, res) => {
  const {
    razorpay_order_id,
    razorpay_payment_id,
    razorpay_signature,
    bookingId,
    paymentType
  } = req.body;

  // 1. Check Idempotency
  const processedRef = db.collection('processed_payments').doc(razorpay_payment_id);
  const processedDoc = await processedRef.get();

  if (processedDoc.exists) {
    return res.json({ success: true, message: 'Payment already processed' });
  }

  // 2. Verify Signature
  const body = razorpay_order_id + "|" + razorpay_payment_id;
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'mock_secret')
    .update(body.toString())
    .digest('hex');

  const isSignatureValid = expectedSignature === razorpay_signature;

  if (!isSignatureValid) {
    // Log Audit Event for failure
    await db.collection('payment_events').add({
      bookingId,
      event: 'SIGNATURE_VERIFICATION_FAILED',
      data: { orderId: razorpay_order_id, paymentId: razorpay_payment_id },
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    return res.status(400).json({ success: false, error: 'Invalid payment signature' });
  }

  // 3. Process Success Transactionally
  await db.runTransaction(async (transaction) => {
    // A. Update Transaction Record
    const txnSnapshot = await db.collection('transactions')
      .where('gatewayOrderId', '==', razorpay_order_id)
      .limit(1)
      .get();

    if (!txnSnapshot.empty) {
      transaction.update(txnSnapshot.docs[0].ref, {
        status: 'success',
        gatewayPaymentId: razorpay_payment_id,
        gatewaySignature: razorpay_signature,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // B. Mark as Processed (Idempotency)
    transaction.set(processedRef, {
      processed: true,
      orderId: razorpay_order_id,
      paymentId: razorpay_payment_id,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // C. Create Escrow (Only if not reservationFee)
    if (paymentType !== 'reservationFee') {
      const bookingRef = db.collection('bookings').doc(bookingId);
      const bookingDoc = await transaction.get(bookingRef);

      if (bookingDoc.exists) {
        const pricing = bookingDoc.data().pricing_breakdown || {};
        const commissionRate = 25; // Standard commission
        const rent = pricing.rent || 0;
        const deposit = pricing.deposit || 0;
        const serviceFee = pricing.serviceFee || 0;

        const commissionAmount = (rent * commissionRate) / 100 + serviceFee;
        const hosterAmount = (rent + deposit + serviceFee) - commissionAmount;

        const escrowRef = db.collection('escrow').doc(bookingId);
        transaction.set(escrowRef, {
          bookingId,
          depositAmount: deposit,
          rentAmount: rent,
          platformFeeAmount: serviceFee,
          grossAmount: rent + deposit + serviceFee,
          commissionRate,
          commissionAmount,
          hosterAmount,
          escrowStatus: 'held',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }

    // D. Log Financial Audit Event
    const eventRef = db.collection('financial_events').doc();
    transaction.set(eventRef, {
      bookingId,
      event: 'PAYMENT_VERIFIED',
      amount: req.body.amount || 0,
      performedBy: req.user.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  res.json({ success: true, message: 'Payment verified and processed' });
});
