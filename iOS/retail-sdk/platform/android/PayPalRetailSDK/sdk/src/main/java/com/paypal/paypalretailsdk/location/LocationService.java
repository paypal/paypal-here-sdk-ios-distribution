package com.paypal.paypalretailsdk.location;

import android.location.Location;

/**
 * Created by schandrashekar on 3/9/17.
 */

public interface LocationService
{
  public void start();

  public void end();

  public boolean isLocationProviderEnabled();

  public Location getCurrentLocation();

  public boolean isLocationFound();
}
