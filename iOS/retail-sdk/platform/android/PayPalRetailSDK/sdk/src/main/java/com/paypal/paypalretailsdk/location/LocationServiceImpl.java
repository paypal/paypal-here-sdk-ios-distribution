package com.paypal.paypalretailsdk.location;

import android.content.Context;
import android.location.Location;
import android.os.Bundle;
import android.util.Log;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationServices;

public class LocationServiceImpl implements LocationService,
    GoogleApiClient.ConnectionCallbacks,
    GoogleApiClient.OnConnectionFailedListener,
    LocationListener
{
  private static GoogleApiClient sLocationClient;
  private static Location sCurrentLocation;
  private static Context sContext;

  public LocationServiceImpl(Context context)
  {
    sContext = context;
    sLocationClient = new GoogleApiClient.Builder(context)
        .addApi(LocationServices.API)
        .addConnectionCallbacks(this)
        .addOnConnectionFailedListener(this)
        .build();
  }

  @Override
  public void start()
  {
    if (isLocationProviderEnabled() && !sLocationClient.isConnected() && !sLocationClient.isConnecting())
    {
      sLocationClient.connect();
    }
  }


  @Override
  public void end()
  {
    if (sLocationClient.isConnected())
    {
      sLocationClient.disconnect();
    }
  }

  @Override
  public boolean isLocationProviderEnabled()
  {
    int responseCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(sContext);
    return (ConnectionResult.SUCCESS == responseCode);
  }

  @Override
  public Location getCurrentLocation()
  {
    return (sLocationClient.isConnected()) ?
           LocationServices.FusedLocationApi.getLastLocation(sLocationClient) : null;
  }

  @Override
  public boolean isLocationFound()
  {
    return sLocationClient.isConnected() && sCurrentLocation != null;
  }

  /*
   * Called by Location Services when the request to connect the client finishes successfully.
   */
  @Override
  public void onConnected(Bundle bundle)
  {
    sCurrentLocation = LocationServices.FusedLocationApi.getLastLocation(sLocationClient);
    if (sCurrentLocation != null)
    {
      Log.d("Location", "sCurrentLocation : " + sCurrentLocation.getLatitude() + " : " + sCurrentLocation.getLongitude());
    }
  }

  /*
   * Called by Location Services if the connection to the location client drops because
   * of an error.
   */
  @Override
  public void onConnectionSuspended(int i)
  {
    sCurrentLocation = null;
  }

  /*
   * Called by Location Services if the attempt to Location Services fails.
   */
  @Override
  public void onConnectionFailed(ConnectionResult connectionResult)
  {
    sCurrentLocation = null;
  }

  @Override
  public void onLocationChanged(Location location)
  {
    sCurrentLocation = location;
  }
}