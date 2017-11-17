package com.paypal.paypalretailsdk.readers.swipers;

import android.content.Context;

import com.bbpos.swiper.SwiperController;
import com.bbpos.swiper.SwiperController.DecodeResult;
import com.bbpos.swiper.SwiperController.SwiperControllerState;
import com.bbpos.swiper.SwiperController.SwiperStateChangedListener;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.readers.common.AudioJackCardReaderInterface;

import com.paypal.paypalretailsdk.readers.common.CardReaderManager;
import com.paypal.paypalretailsdk.readers.common.CardReaderObserver;
import com.paypal.paypalretailsdk.readers.common.CardReaderInterface;

import java.util.HashMap;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import android.util.Log;

public class RoamSwiper implements AudioJackCardReaderInterface {

    private static final String LOG_TAG = RoamSwiper.class.getSimpleName();

    private enum SwiperCommand {STOP_SWIPE, START_SWIPE};

    private static RoamSwiper mInstance;
    private Context mContext;
    private StateChangedListener mRoamStateListener;
    private SwiperController mRoamSwiperController;
    private CardReaderObserver mObserver;
    private List<SwiperStateChangedListener> mSwiperStateChangeListeners;
    private String mKsn = null;
    private int mSwipeFailureReason;
    private ArrayBlockingQueue<SwiperCommand> mCommandsQueue;
    private boolean mIsCommandRunning;
    private final int mSwiperCommandQueueSize = 2;
    private Runnable checker;
    private ScheduledFuture next;
    private ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);;
    private boolean mCheckerInProgress = false;
    private final Object lock = new Object();

    private RoamSwiper(Context context) {
        mContext = context;
        mSwiperStateChangeListeners = new CopyOnWriteArrayList<SwiperStateChangedListener>();
        mCommandsQueue = new ArrayBlockingQueue<SwiperCommand>(mSwiperCommandQueueSize);
        initialize();
    }

    public static RoamSwiper getInstance(Context context) {
        if (null == mInstance) {
            mInstance = new RoamSwiper(context);
        }
        return mInstance;
    }

    private void initialize() {
        if (null != mRoamStateListener) {
            mRoamStateListener = null;
        }

        if (null != mRoamSwiperController) {
            mRoamSwiperController.deleteSwiper();
            mRoamSwiperController = null;
        }
        mRoamStateListener = new StateChangedListener();
        mRoamSwiperController = SwiperController.createInstance(mContext, mRoamStateListener);

        mRoamSwiperController.setDetectDeviceChange(true);
        mRoamSwiperController.setSwipeTimeout(-1);
        mIsCommandRunning = false;
        notifyDevicePresentStatus();
    }

    @Override
    public AudioJackCardReaderInterface getAudioJackReaderInterface() {
        return this;
    }

    @Override
    public void listenForCardEvents() {
        queueSwiperCommand(SwiperCommand.START_SWIPE);
    }

    @Override
    public void stopTransaction() {
        queueSwiperCommand(SwiperCommand.STOP_SWIPE);
    }

    @Override
    public void markAudioJackDeviceAsPlugged(boolean pluggedIn) {
        Log.d(LOG_TAG, "markAudioJackDeviceAsPlugged " + pluggedIn);

        if (pluggedIn) {
            if (null == mRoamSwiperController) {
                initialize();
            }
        } else {
            if (null != mRoamSwiperController) {
                Log.d(LOG_TAG, "About to deleteSwiper");
                mRoamSwiperController.deleteSwiper();
                mRoamSwiperController = null;
            }
            mInstance = null;

            // device is unplugged!
            if (null != mObserver) {
                Log.d(LOG_TAG, "markAudioJackDeviceAsPluggged OnDeviceLostConnection " + pluggedIn);

                mObserver.onDeviceLostConnection(CardReaderInterface.DeviceTypes.RoamPayReader,
                                                 CardReaderInterface.DeviceFamily.MagneticCardReader);
            }
        }
    }

    @Override
    public boolean isAudioJackDevicePlugged() {
        return mRoamSwiperController != null;
    }

    @Override
    public boolean isConnected() {
        boolean devicePresent = false;
        if (null != mRoamSwiperController) {
            SwiperControllerState state = mRoamSwiperController.getSwiperControllerState();
            switch (state) {
                case STATE_WAITING_FOR_DEVICE:
                    devicePresent = false;
                    break;

                case STATE_IDLE:
                    mRoamSwiperController.isSwiperHere();
                    devicePresent = true;
                    break;

                default:
                    devicePresent = true;
                    break;
            }
        }
        return devicePresent;
    }

    @Override
    public String getName() {
        return this.getClass().getSimpleName();
    }

    @Override
    public CardReaderManager.ReaderTypes getReaderType() {
        return CardReaderManager.ReaderTypes.MagneticCardReader;
    }

    @Override
    public DeviceTypes getDeviceType() {
        return DeviceTypes.RoamPayReader;
    }

    @Override
    public DeviceFamily getDeviceFamily() {
        return DeviceFamily.MagneticCardReader;
    }

    private void notifyDevicePresentStatus() {
        if (null != mRoamSwiperController) {
            if (mRoamSwiperController.isDevicePresent()) {
                mRoamSwiperController.isSwiperHere();
            }
        }
    }

    public void setObserver(CardReaderObserver observer) {
        mObserver = observer;
    }

    public void removeObserver() {
        mObserver = null;
    }


    private void executeStopSwipe() {
        mRoamSwiperController.stopSwiper();
    }

    private void executeStartSwipe() {
        mRoamSwiperController.startSwiper();
    }

    private void logSwipeFailureToCal(int reason) {
        Log.d(LOG_TAG, "logSwipeFailureToCal: msg: " + reason);
        if (null != mKsn) {
            //Log.logSwipeFailed(CardReaderInterface.DeviceTypes.RoamPayReader, reason, mKsn);
        } else {
            Log.d(LOG_TAG, "logswipeFailureToCal swiper ksn is null. Hence calling getSwiperKsn()");
            mSwipeFailureReason = reason;
            //Commenting this because if we call this is intersecting with listenForCardEvents() call in case of swipe failure
            //mRoamSwiperController.getSwiperKsn();
            //For now we are sending with null ksn.
            //Log.logSwipeFailed(CardReaderInterface.DeviceTypes.RoamPayReader, reason, mKsn);
        }
    }

    private void logSwipeSuccessToCal() {
        Log.d(LOG_TAG, "In RoamSwiper, calling successfulPaymentEntry ");
        //TransactionTimeTracker.successfulPaymentEntry();
        //Log.logSwipeSuccess(CardReaderInterface.DeviceTypes.RoamPayReader, mKsn);
    }

    private class StateChangedListener implements SwiperStateChangedListener {

        @Override
        public void onDecodeCompleted(HashMap<String, String> decodeData) {

            Log.v(LOG_TAG + "RoamReader", "Looks like the decoding went through well too!");
            String formatID = decodeData.get("formatID");
            String ksn = decodeData.get("ksn");
            String encTrack = decodeData.get("encTrack");
            String maskedPAN = decodeData.get("maskedPAN");
            String partialTrack = decodeData.get("partialTrack");
            // All the cards that I swiped, the key is "cardholderName" instead of "cardHolderName".
            // Also, we dont use this variable. We extract the name from  encTrack, formatID and  partialTrack.
            String cardHolderName = decodeData.get("cardholderName");
            String expDate = decodeData.get("expiryDate");

            //Store the value of ksn for future purpose..
            mKsn = ksn;

            String track1 = SwiperController.packEncTrackData(formatID, encTrack, partialTrack);

            if (track1 != null) {
                if (null != mObserver) {
                    mObserver.onSwipeDetected(decodeData, track1);
                }
                logSwipeSuccessToCal();
            } else {
                if (null != mObserver) {
                    mObserver.onSwipeFailed();
                }
                listenForCardEvents();
                //logSwipeFailureToCal(CalMessage.CalMessageSwipeFailureEnum.ePPHSwipeFailureCode_SwipeButNoTrackData.getVal());
            }
            callbackFromSwiperCommand("onDecodeCompleted");
        }

        @Override
        public void onDecodeError(DecodeResult decodeResult) {
            // We will, downstream, log the failure to Log.  Don't log here or
            // we'll get duplicate messages sent to CAL
            Log.d(LOG_TAG, "onDecodeError");

            switch (decodeResult) {

                case DECODE_SWIPE_FAIL:
                    if (null != mObserver) {
                        mObserver.onSwipeFailed();
                    }
                    //logSwipeFailureToCal(CalMessage.CalMessageSwipeFailureEnum.ePPHSwipeFailureCode_CouldNotDecodeSwipe.getVal());
                    break;
                case DECODE_COMM_ERROR:
                    if (null != mObserver) {
                        mObserver.onDeviceError("Roam Swiper reports a DECODE_COMM_ERROR");
                    }
                    //logSwipeFailureToCal(CalMessage.CalMessageSwipeFailureEnum.ePPHSwipeFailureCode_DecodeCommError.getVal());
                    break;

                case DECODE_CRC_ERROR:
                    if (null != mObserver) {
                        mObserver.onDeviceError("Roam Swiper reports a DECODE_CRC_ERROR");
                    }
                    //logSwipeFailureToCal(CalMessage.CalMessageSwipeFailureEnum.ePPHSwipeFailureCode_DecodeCRCError.getVal());
                    break;

                default:
                    if (null != mObserver) {
                        mObserver.onDeviceError("Roam Swiper swipe failed with undefined Decode Result: "
                                                    + decodeResult);
                    }
                    //logSwipeFailureToCal(CalMessage.CalMessageSwipeFailureEnum.ePPHSwipeFailureCode_DecodeUnknownError.getVal());
                    break;

            }

            listenForCardEvents();
            callbackFromSwiperCommand("onDecodeError");
        }

        @Override
        public void onGetKsnCompleted(String ksn) {
            Log.d(LOG_TAG, "onGetKsnCompleted: ksn: " + ksn + " Log the swipe failure event to cal..");
            mKsn = ksn;
            // We are calling getSwiperKsn in swipe failure cases and when we want to log the swipe failure to Cal.
            //Log.logSwipeFailed(CardReaderInterface.DeviceTypes.RoamPayReader, mSwipeFailureReason, mKsn);

            for (SwiperStateChangedListener listener : mSwiperStateChangeListeners) {
                listener.onGetKsnCompleted(ksn);
            }
            callbackFromSwiperCommand("onGetKsnCompleted");
        }

        @Override
        public void onError(String message) {
            Log.d(LOG_TAG, "reportErrorBackToApplication called back. Message = " + message);

            if (message.equalsIgnoreCase("Volume warning not accepted")) {
                if (mObserver != null) {
                    mObserver.onDeviceDetected(false, DeviceTypes.RoamPayReader, DeviceFamily.MagneticCardReader);
                } else {
                    Log.i(LOG_TAG, "********************** mObserver is null!! ***************. If you see this, please DIAGNOSE FURTHER!!");
                }
                return;
            }

            for (SwiperStateChangedListener listener : mSwiperStateChangeListeners) {
                listener.onError(message);
            }
            callbackFromSwiperCommand("onError");
            /*
            Raj - I observed that whenever there is this specific eror - Failed to create audio recorder,
            Swipes just stop working. Patching it this way, seems to recover from such a situation.
            We should talk to Roam and get more information. May be they know the right way to handle.
             */
            if (message != null && message.contains("Failed to create audio recorder")) {
                queueSwiperCommand(SwiperCommand.STOP_SWIPE);
                queueSwiperCommand(SwiperCommand.START_SWIPE);
            }
        }

        @Override
        public void onInterrupted() {
            Log.d(LOG_TAG, "onInterrupted() called back");
            callbackFromSwiperCommand("onInterrupted");
        }

        @Override
        public void onNoDeviceDetected() {
            Log.d(LOG_TAG, "onNoDeviceDetected() called back");
            callbackFromSwiperCommand("onNoDeviceDetected");
        }

        @Override
        public void onTimeout() {
            Log.d(LOG_TAG, "A very helpful timeout message has been received");
        }

        @Override
        public void onCardSwipeDetected() {
            Log.d(LOG_TAG, "We now have a card swipe!");
        }

        @Override
        public void onWaitingForCardSwipe() {
            Log.d(LOG_TAG, "onWaitingForCardSwipe() is received");
            callbackFromSwiperCommand("onWaitingForCardSwipe");
        }

        @Override
        public void onWaitingForDevice() {
            Log.d(LOG_TAG, "onWaitingForDevice is received. State = " + mRoamSwiperController.getSwiperControllerState());
        }

        @Override
        public void onDevicePlugged() {
            final SwiperControllerState swiperControllerState = mRoamSwiperController.getSwiperControllerState();
            if (SwiperControllerState.STATE_IDLE == swiperControllerState) {
                Log.d(LOG_TAG, "Device is plugged and we are in idle state so invoking getSwiperKsn");
                mRoamSwiperController.isSwiperHere();
            } else {

                Log.w(LOG_TAG, "Device plugged but we are not idle! state = " + swiperControllerState);
            }
        }

        @Override
        public void onDeviceUnplugged() {
            Log.d(LOG_TAG, "onDeviceUnplugged is invoked!");
            if (null != mObserver) {
                mObserver.onDeviceLostConnection(CardReaderInterface.DeviceTypes.RoamPayReader,
                                                 CardReaderInterface.DeviceFamily.MagneticCardReader);
            }
        }

        @Override
        public void onSwiperHere(boolean isRoam) {
            if (mRoamSwiperController == null) {
                return;
            }

            Log.d(LOG_TAG, "onSwiperHere is invoked with isRoam = " + isRoam + ", state" + mRoamSwiperController.getSwiperControllerState());
            if (null != mObserver) {
                mObserver.onDeviceDetected(isRoam, CardReaderInterface.DeviceTypes.RoamPayReader, CardReaderInterface.DeviceFamily.MagneticCardReader);
            }

            if (isRoam && mRoamSwiperController.getSwiperControllerState().equals(SwiperControllerState.STATE_IDLE)) {
                queueSwiperCommand(SwiperCommand.START_SWIPE);
            }
        }
    }

    void runAllCommands() {
        Log.d(LOG_TAG, "A Is swiper command running? " + mIsCommandRunning);

        if (mIsCommandRunning || mCommandsQueue.isEmpty() || mRoamSwiperController == null) {
            Log.d(LOG_TAG, "--> Swiper command queue size: " + mCommandsQueue.size() + " contents: " + mCommandsQueue.toString());
            return;
        }

        try {
            Log.d(LOG_TAG, "A Swiper command queue size: " + mCommandsQueue.size() + " contents: " + mCommandsQueue.toString());
            SwiperControllerState state = mRoamSwiperController.getSwiperControllerState();
            SwiperCommand command = mCommandsQueue.take();
            if (command == SwiperCommand.STOP_SWIPE && SwiperControllerState.STATE_IDLE != state) {
                Log.d(LOG_TAG, " Executing swiper command stopSwiper ");
                executeStopSwipe();
                mIsCommandRunning = true;
            } else if (command == SwiperCommand.START_SWIPE && SwiperControllerState.STATE_IDLE == state) {
                Log.d(LOG_TAG, " Executing swiper command startSwiper ");
                executeStartSwipe();
                mIsCommandRunning = true;
            } else {
                Log.d(LOG_TAG, " COULD NOT Execute " + command + ", state: " + state);
            }
        } catch (InterruptedException e) {
            Log.d(LOG_TAG, " InterruptedException while executing swiper commands. Message:  " + e.getMessage());
            mIsCommandRunning = false;
        }
        Log.d(LOG_TAG, "B Swiper command queue size: " + mCommandsQueue.size() + " contents: " + mCommandsQueue.toString());

    }

    synchronized void callbackFromSwiperCommand(String callback) {
        Log.d(LOG_TAG, " callbackFromSwiperCommand " + callback);
        mIsCommandRunning = false;
        runAllCommands();
    }

    private boolean isCommandAlreadyTheTail(SwiperCommand swiperCommand) {
        SwiperCommand lastCommand = null;
        for (SwiperCommand command : mCommandsQueue) {
            lastCommand = command;
        }
        return (swiperCommand.equals(lastCommand));
    }

    synchronized void queueSwiperCommand(SwiperCommand command)
    {
        if (mCheckerInProgress && mCommandsQueue.size() < mSwiperCommandQueueSize) {
            Log.d(LOG_TAG, "checker is IN PROGRESS and queue size is coming down: " + mCommandsQueue.size() + " so swiper is in GOOD state");
            synchronized (lock)
            {
                mCheckerInProgress = false;
            }
            if (next != null)
            {
                next.cancel(false);
            }
            if (executor != null || !executor.isShutdown())
            {
                executor.shutdown();
            }
        }

        if (mCommandsQueue.size() > 0 && isCommandAlreadyTheTail(command)) {
            Log.d(LOG_TAG, "NOT queueing swiper command " + command);
            Log.d(LOG_TAG, "-- Swiper command queue size: " + mCommandsQueue.size() + " contents: " + mCommandsQueue.toString());
        }
        else if (mCommandsQueue.size() >= mSwiperCommandQueueSize) {
            Log.d(LOG_TAG, "NOT queueing swiper command " + command + " due to FULL queue");
            Log.d(LOG_TAG, "-- Swiper command queue FULL size: " + mCommandsQueue.size() + " contents: " + mCommandsQueue.toString());
            if (!mCheckerInProgress) {
                Log.d(LOG_TAG, "checker is not InProgress");
                synchronized (lock)
                {
                    mCheckerInProgress = true;
                }
                checker = new Runnable()
                {
                    @Override
                    public void run()
                    {
                        Log.d(LOG_TAG, "Swiper command queue size: " + mCommandsQueue.size() + " contents: " + mCommandsQueue.toString());
                        if (mCommandsQueue.size() >= mSwiperCommandQueueSize) {
                            Log.d(LOG_TAG, "checker is IN PROGRESS and queue size is NOT coming down: " + mCommandsQueue.size() + " so swiper is in BAD state. Restarting the swiper!");
                            RetailSDK.endRoamSwiper();
                            RetailSDK.beginRoamSwiper();
                            synchronized (lock)
                            {
                                mCheckerInProgress = false;
                            }
                        }
                    }
                };
                next = executor.schedule(checker, 2, TimeUnit.SECONDS);
            }
            else {
                Log.d(LOG_TAG, "NOT queueing swiper command " + command + " due to checker in PROGRESS");
            }
        }
        else {
            mCommandsQueue.add(command);
            Log.d(LOG_TAG, " queueing swiper command " + command);
        }
        runAllCommands();
    }
}