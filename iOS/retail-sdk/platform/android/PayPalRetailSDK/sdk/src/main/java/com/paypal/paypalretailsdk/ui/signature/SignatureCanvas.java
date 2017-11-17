package com.paypal.paypalretailsdk.ui.signature;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.EmbossMaskFilter;
import android.graphics.MaskFilter;
import android.graphics.Paint;
import android.graphics.Path;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;

public class SignatureCanvas extends View {
    private static final String LOG_TAG = SignatureCanvas.class.getSimpleName();

    private boolean created = false;
    private Paint mPaint;
    private int backgroundColor = 0xe8e6e1;
    private Bitmap mBitmap;
    private Canvas mCanvas;
    private Path mPath;
    private Paint mBitmapPaint;

    public SignatureListener listener;
    private boolean signaturePresent;


    public SignatureCanvas(Context c, AttributeSet a) {
        super(c, a);
        mPath = new Path();
        mBitmapPaint = new Paint(Paint.DITHER_FLAG);

        mPaint = new Paint();
        mPaint.setAntiAlias(true);
        mPaint.setDither(true);
        mPaint.setColor(0xFF000000);
        mPaint.setStyle(Paint.Style.STROKE);
        mPaint.setStrokeJoin(Paint.Join.ROUND);
        mPaint.setStrokeCap(Paint.Cap.ROUND);
        mPaint.setStrokeWidth(10);

        MaskFilter mEmboss = new EmbossMaskFilter(new float[]{1, 1, 1}, 0.4f, 6, 3.5f);
        mPaint.setMaskFilter(mEmboss);

        signaturePresent = false;
        listener = null;

    }


    public Bitmap getBitmap() {
        // need to draw the bitmap onto a white background.
        Bitmap returnBitmap = Bitmap.createBitmap(mBitmap.getWidth(), mBitmap.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas returnCanvas = new Canvas(returnBitmap);
        returnCanvas.drawColor(Color.WHITE);
        returnCanvas.drawBitmap(mBitmap, 0, 0, mBitmapPaint);
        return returnBitmap;
    }


    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (!created) {
            mBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
            mCanvas = new Canvas(mBitmap);
            created = true;
        }
    }


    @Override
    protected void onDraw(Canvas canvas) {
        canvas.drawColor(backgroundColor);
        canvas.drawBitmap(mBitmap, 0, 0, mBitmapPaint);
        canvas.drawPath(mPath, mPaint);
    }


    public void clear() {
        //Logging.d(LOG_TAG, "Clearing the signature");
        mPath = new Path();
        mCanvas.drawColor(backgroundColor);
        mBitmap = Bitmap.createBitmap(mBitmap.getWidth(), mBitmap.getHeight(), Bitmap.Config.ARGB_8888);
        mCanvas = new Canvas(mBitmap);
        invalidate();
        signaturePresent = false;
        listener.onSignaturePresent(false);
    }


    private float mX, mY;
    private static final float TOUCH_TOLERANCE = 4;


    private void touch_start(float x, float y) {
        mPath.moveTo(x, y);
        mX = x;
        mY = y;
    }


    private void touch_move(float x, float y) {
        float dx = Math.abs(x - mX);
        float dy = Math.abs(y - mY);
        if (dx >= TOUCH_TOLERANCE || dy >= TOUCH_TOLERANCE) {
            mPath.quadTo(mX, mY, (x + mX) / 2, (y + mY) / 2);
            mX = x;
            mY = y;
        }
    }


    private void touch_up() {
        mPath.lineTo(mX, mY);
        mCanvas.drawPath(mPath, mPaint);  // commit the path to our offscreen
    }


    @Override
    public boolean onTouchEvent(MotionEvent event) {
        float x = event.getX();
        float y = event.getY();

        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                touch_start(x, y);
                invalidate();
                break;
            case MotionEvent.ACTION_MOVE:
                if (!signaturePresent) {
                    try {
                        listener.onSignaturePresent(true);
                        signaturePresent = true;
                    } catch (NullPointerException e) {
                        //Logging.e("Null Pointer", "SignSignature Listener");
                        //Logging.e(Logging.LOG_PREFIX, e.getMessage());
                    }
                }
                touch_move(x, y);
                invalidate();
                break;
            case MotionEvent.ACTION_UP:
                touch_up();
                invalidate();
                break;
        }
        return true;
    }


    public void setSignatureListener(SignatureListener listener) {
        this.listener = listener;
    }


    public interface SignatureListener {
        void onSignaturePresent(boolean signature);
    }
}
