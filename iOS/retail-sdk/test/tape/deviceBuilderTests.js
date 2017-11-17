import test from 'tape';
import {
  PaymentDevice,
  deviceManufacturer,
} from 'retail-payment-device';
import MiuraDevice from 'miura-emv';
import RoamSwiperDevice from '../../js/paymentDevice/RoamSwiperDevice';
import DeviceBuilder from '../../js/paymentDevice/DeviceBuilder';

test('DeviceBuilder Can build Miura device', (t) => {
  // Given
  const builder = new DeviceBuilder();

  // When
  const isUsb = false;
  const nativeShim = {};
  const cardReader = builder.build(deviceManufacturer.miura, 'id-1', isUsb, nativeShim);

  // Then
  t.ok(cardReader, 'Card reader was properly created');
  t.ok(cardReader instanceof MiuraDevice, 'Card reader of type MiuraDevice was provisioned');
  t.end();
});

test('DeviceBuilder Can build Roam swiper device', (t) => {
  // Given
  const builder = new DeviceBuilder();

  // When
  const isUsb = false;
  const nativeShim = {};
  const cardReader = builder.build(deviceManufacturer.roam, 'id-1', isUsb, nativeShim);

  // Then
  t.ok(cardReader, 'Card reader was properly created');
  t.ok(cardReader instanceof RoamSwiperDevice, 'Card reader of type MiuraDevice was provisioned');
  t.end();
});

test('DeviceBuilder can re-use existing devices', (t) => {
  // Given
  const builder = new DeviceBuilder();

  // Create a new card reader
  const isUsb = false;
  const id1 = 'id-1';
  const nativeShim1 = {};
  const cardReader1 = builder.build(deviceManufacturer.miura, id1, isUsb, nativeShim1);
  t.ok(cardReader1, 'Card reader was properly created');
  t.ok(cardReader1 instanceof MiuraDevice, 'Card reader of type MiuraDevice was provisioned');
  PaymentDevice.discovered(cardReader1);
  t.equal(PaymentDevice.devices.length, 1, 'One device was discovered');

  // Call to build with same manufacturer and Id
  const nativeShim2 = {};
  const cardReader2 = builder.build(deviceManufacturer.miura, id1, isUsb, nativeShim2);
  t.equal(cardReader2, cardReader1, 'Reuse device when provided with same ID and Manufacturer');
  t.equal(cardReader2.native, nativeShim2, 'Native shim is updated to new one');

  PaymentDevice.devices = [];
  t.end();
});
