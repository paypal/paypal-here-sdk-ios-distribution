package com.paypal.paypalretailsdk;

import android.annotation.TargetApi;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.SoundPool;
import android.media.ToneGenerator;
import android.os.Build;

import java.util.HashMap;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;

public class SoundNotification {
    private static final String LOG_TAG = SoundNotification.class.getSimpleName();
    private SoundPool mSoundPool;
    private HashMap mSoundsMap = new HashMap();
    private Context mContext;

    public SoundNotification(Context activity) {
        mContext = activity;
        initializeSoundPool();
    }

    private SoundPool createSoundPool() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return createNewSoundPool();
        } else {
            return createOldSoundPool();
        }
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private SoundPool createNewSoundPool() {
        AudioAttributes attributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build();

        SoundPool sounds = new SoundPool.Builder()
                .setAudioAttributes(attributes)
                .build();

        return sounds;
    }

    @SuppressWarnings("deprecation")
    private SoundPool createOldSoundPool() {
        return new SoundPool(5, AudioManager.STREAM_NOTIFICATION, 0);
    }

    public void initializeSoundPool() {
        mSoundPool = createSoundPool();

        mSoundPool.setOnLoadCompleteListener(new SoundPool.OnLoadCompleteListener() {
            @Override
            public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {
                RetailSDK.logViaJs("debug", LOG_TAG, "onLoadComplete");
            }
        });

        mSoundsMap.put(R.raw.success_card_read, mSoundPool.load(mContext, R.raw.success_card_read, 1));
    }

    public void playSound(int sampleId) {
        try {
            int iSoundId = (Integer) mSoundsMap.get(sampleId);
            mSoundPool.play(iSoundId, 1.0f, 1.0f, 1, 0, 1f);
        } catch(Exception ex) {
            RetailSDK.logViaJs("error", LOG_TAG, "Error in playSound" + ex.toString());
        }
    }

    public void playAudibleBeep(int playCount) {
        final Timer t = new Timer();
        final int[] count = {playCount};
        TimerTask tt = new TimerTask() {
            @Override
            public void run() {
                try {
                    final ToneGenerator tg = new ToneGenerator(AudioManager.STREAM_ALARM, 100);
                    tg.startTone(ToneGenerator.TONE_PROP_BEEP, 200);
                    if(--count[0] == 0) {
                        t.cancel();
                    }
                } catch(Exception ex) {
                    RetailSDK.logViaJs("error", LOG_TAG, "Error in playAudibleBeep" + ex.toString());
                }
            }
        };

        t.schedule(tt, 0, 400);
    }

    public void release() {
        if (mSoundPool != null) {
            mSoundPool.release();
        }
    }

    public void stop() {
        if (mSoundPool != null) {
            Set<Integer> ids = mSoundsMap.keySet();
            for(Integer id: ids) {
                mSoundPool.stop(id);
            }
        }
    }
}
