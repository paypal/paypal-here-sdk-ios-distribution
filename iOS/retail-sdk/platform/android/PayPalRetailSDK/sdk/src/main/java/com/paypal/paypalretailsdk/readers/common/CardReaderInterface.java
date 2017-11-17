package com.paypal.paypalretailsdk.readers.common;

public interface CardReaderInterface extends CardReaderManager.CardReader
{
    public AudioJackCardReaderInterface getAudioJackReaderInterface();

    public void listenForCardEvents();

    public void stopTransaction();

    public boolean isConnected();

    public DeviceTypes getDeviceType();

    public DeviceFamily getDeviceFamily();

    public enum DeviceTypes {
        RoamPayReader,
        MagtekReader,
        MiuraEMVReader,
        UnknownReader
    }

    public enum DeviceFamily {
        MagneticCardReader,
        ChipAndPinReader,
        NonContactReader,
        UnknownReaderFamily
    }
}
