const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function : Valider le code de départ côté serveur
 * Vérifie :
 * - Authentification de l'appelant (conducteur)
 * - Validité de la session de trajet
 * - Code exact
 * - Expiration
 * - Limite de tentatives (max 3)
 */
exports.confirmDepartureCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Vous devez être authentifié pour effectuer cette opération."
    );
  }

  const driverId = context.auth.uid;
  const { bookingId, enteredCode } = data;

  if (!bookingId || !enteredCode) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "bookingId et enteredCode sont requis."
    );
  }

  return db.runTransaction(async (transaction) => {
    const sessionRef = db.collection("trip_sessions").doc(bookingId);
    const sessionDoc = await transaction.get(sessionRef);

    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Session de départ introuvable."
      );
    }

    const session = sessionDoc.data();

    if (session.driverId !== driverId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Seul le conducteur de ce trajet peut valider ce code."
      );
    }

    if (session.isUsed) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Ce code a déjà été validé et utilisé."
      );
    }

    const now = admin.firestore.Timestamp.now();
    if (session.expiresAt && session.expiresAt.toMillis() < now.toMillis()) {
      throw new functions.https.HttpsError(
        "deadline-exceeded",
        "Ce code de départ a expiré."
      );
    }

    if (session.attemptCount >= (session.maxAttempts || 3)) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Nombre maximal de tentatives atteint."
      );
    }

    const newAttempts = (session.attemptCount || 0) + 1;

    if (session.code !== enteredCode.toString().trim()) {
      transaction.update(sessionRef, {
        attemptCount: newAttempts,
      });

      const remaining = (session.maxAttempts || 3) - newAttempts;
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Code erroné. Il vous reste ${remaining} tentative(s).`
      );
    }

    // Code valide : confirmation du départ
    transaction.update(sessionRef, {
      isUsed: true,
      attemptCount: newAttempts,
      verifiedAt: now,
    });

    const bookingRef = db.collection("bookings").doc(bookingId);
    transaction.update(bookingRef, {
      status: "completed",
    });

    return {
      success: true,
      message: "Départ confirmé avec succès.",
    };
  });
});

/**
 * Cloud Function : Annulation sécurisée d'une réservation côté serveur
 */
exports.cancelBookingSecure = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Non authentifié.");
  }

  const userId = context.auth.uid;
  const { bookingId } = data;

  return db.runTransaction(async (transaction) => {
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Réservation introuvable.");
    }

    const booking = bookingDoc.data();

    if (booking.passengerId !== userId && booking.driverId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "Accès non autorisé.");
    }

    if (booking.status === "cancelled") {
      throw new functions.https.HttpsError("failed-precondition", "Déjà annulée.");
    }

    if (booking.status === "completed") {
      throw new functions.https.HttpsError("failed-precondition", "Trajet déjà effectué.");
    }

    const rideRef = db.collection("rides").doc(booking.rideId);
    const rideDoc = await transaction.get(rideRef);

    if (booking.status === "accepted" && rideDoc.exists) {
      const ride = rideDoc.data();
      const restored = Math.min(
        (ride.availableSeats || 0) + booking.seatsCount,
        ride.totalSeats || 8
      );
      transaction.update(rideRef, { availableSeats: restored });
    }

    transaction.update(bookingRef, { status: "cancelled" });

    return { success: true };
  });
});
