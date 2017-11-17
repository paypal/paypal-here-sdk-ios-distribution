import moment from 'moment';
import {
  deviceError,
  deviceErrorDomain,
  FormFactor,
  deviceManufacturer,
} from 'retail-payment-device';
import { InvoiceEnums, Currency } from 'paypal-invoicing';
import BN from 'bignumber.js';
import {
  transaction as transactionError,
  domain as transactionDomain,
} from './sdkErrors';
import PaymentType from '../transaction/PaymentType';

module.exports.StorageType = {
  Secure: 'S',
  Blob: 'B',
  String: 'V',
  SecureBlob: 'E',
};

export function getEnumName(obj, val) {
  for (const prop in obj) {
    if ({}.hasOwnProperty.call(obj, prop)) {
      if (obj[prop] === val) {
        return prop;
      }
    }
  }

  return val;
}

export function transactionCancelledError(error) {
  return (error &&
  ((error.code === deviceError.paymentCancelled.code && error.domain === deviceErrorDomain) ||
  (error.code === transactionError.customerCancel.code && error.domain === transactionDomain.transaction)));
}

export function hereAPICardDataFromCard(card) {
  const cardData = {
    reader: {
      vendor: card.reader.manufacturer.toUpperCase(),
      readerSerialNumber: card.reader.serialNumber,
      deviceModel: card.reader.model,
    },
  };

  if (card.formFactor === FormFactor.MagneticCardSwipe) {
    cardData.reader.keySerialNumber = card.ksn;
    cardData.inputType = card.isMSRFallbackAllowed ? 'fallback_swipe' : 'swipe';
    cardData.track1 = card.track1;
    cardData.track2 = card.track2;
    cardData.track3 = card.track3;
    // TODO Remove the following M010 specific code once US837438 is live
    if (card.isMSRFallbackAllowed && cardData.reader.vendor === deviceManufacturer.miura) {
      cardData.reader.vendor = 'MIURA_FB_SWIPE';
      cardData.inputType = 'swipe';
    }
  } else if (card.formFactor === FormFactor.ManualCardEntry) {
    cardData.inputType = 'keyIn';
    cardData.emvData = card.emvData;
    if (card.expiration && card.expiration.length > 2) {
      cardData.expirationMonth = card.expiration.substring(2);
      cardData.expirationYear = parseInt(card.expiration.substring(0, 2), 10) + 2000;
    }
    cardData.cvv = card.cvv;
  } else if (card.formFactor === FormFactor.Chip) {
    cardData.inputType = 'chip';
    cardData.emvData = card.emvData.apdu.data.toString('hex');
  } else if (card.formFactor === FormFactor.EmvCertifiedContactless) {
    cardData.inputType = card.isContactlessMSD ? 'contactless_msd' : 'contactless_chip';
    cardData.emvData = card.emvData.apdu.data.toString('hex');
  } else {
    throw new Error(`Cannot generate HereAPI card data from ${card}`);
  }

  return cardData;
}

export function getInvoiceEnumFromPaymentType(paymentType) {
  switch (paymentType) {
    case PaymentType.card:
    case PaymentType.keyIn:
      return InvoiceEnums.PaymentMethod.CREDIT_CARD;

    case PaymentType.cash:
      return InvoiceEnums.PaymentMethod.CASH;

    case PaymentType.check:
      return InvoiceEnums.PaymentMethod.CHECK;

    default :
      return InvoiceEnums.PaymentMethod.NONE;
  }
}

export const currencySymbols = {
  USD: '$',
  AUD: '$',
  CAD: '$',
  HKD: '$',
  GBP: '£',
  EUR: '€',
};

export function getAmountWithCurrencySymbol(currencyCode, amount) {
  const symbol = currencySymbols[currencyCode] || '$';
  const formatted = Currency.round(currencyCode, amount).toFormat(2, BN.ROUND_HALF_UP);
  return `${symbol}${formatted}`;
}

export function getRandomId() {
  return Math.floor(Math.random() * 10000000000000);
}

export function isDatesWithinOffset(startDate, endDate, offsetDays) {
  const momentStartDate = moment(startDate);
  const momentEndDate = moment(endDate);

  const daysDifference = momentEndDate.diff(momentStartDate, 'days', true);

  return daysDifference >= 0 && daysDifference <= offsetDays;
}
