package com.paypal.retailsdktestapp;

import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;

import com.paypal.paypalretailsdk.AuthorizedTransaction;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.RetailSDKException;

import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;

import java.math.BigDecimal;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

@EActivity
public class AuthActivity extends ActionBarActivity {

  @ViewById
  EditText startDateText;

  @ViewById
  EditText startTimeText;

  @ViewById
  EditText endDateText;

  @ViewById
  EditText endTimeText;

  @ViewById
  EditText pageSizeText;

  @ViewById
  ListView listAuth;

  @ViewById
  TextView displayTextView;

  @ViewById
  CheckBox optionalEndTime;

  @ViewById
  CheckBox authStatusAll;

  @ViewById
  CheckBox authStatusPending;

  @ViewById
  CheckBox authStatusCancelled;

  Button btnLoadMore;
  boolean isLoadMoreInView;
  ListViewAdapter adapter;
  List<AuthorizedTransaction> auths;
  String nextPageToken;

  ProgressDialog progressDialog;

  @UiThread
  public void showAlert(String text) {
    AlertDialog.Builder builder = new AlertDialog.Builder(this);
    builder.setMessage(text)
        .setCancelable(false)
        .setPositiveButton("OK", new DialogInterface.OnClickListener() {
          public void onClick(DialogInterface dialog, int id) {
            //do things
          }
        });
    AlertDialog alert = builder.create();
    alert.show();
  }

  @UiThread
  public void updateView(TextView status, String text) {
    status.setText(text);
  }

  @UiThread
  public void showProgressDialog(String text) {
    progressDialog = new ProgressDialog(this);
    progressDialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
    progressDialog.setIndeterminate(false);
    progressDialog.setMessage(text + "...");
    progressDialog.show();
  }

  @UiThread
  public void dismissProgressDialog() {
    if (progressDialog != null)
      progressDialog.dismiss();
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_auth);

    initializeData();
    displayTextView.setTypeface(null, Typeface.BOLD);

    // LoadMore button
    btnLoadMore = new Button(this);
    btnLoadMore.setText("Load More");
    btnLoadMore.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View arg0) {
        // Starting a new async task
        new AuthLoader().execute();
      }
    });

    // Checkbox to enable/disable end time
    endDateText.setEnabled(false);
    endTimeText.setEnabled(false);
    optionalEndTime.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
      @Override
      public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
        if (isChecked) {
          endDateText.setEnabled(true);
          endTimeText.setEnabled(true);
        } else {
          endDateText.setEnabled(false);
          endTimeText.setEnabled(false);
        }
      }
    });
    optionalEndTime.setChecked(false);

    // Checkbox to enable/disable status filter
    authStatusAll.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
      @Override
      public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
        if (isChecked) {
          authStatusPending.setChecked(true);
          authStatusCancelled.setChecked(true);
          authStatusPending.setEnabled(false);
          authStatusCancelled.setEnabled(false);
        } else {
          authStatusPending.setEnabled(true);
          authStatusCancelled.setEnabled(true);
        }
      }
    });
    authStatusAll.setChecked(true);
  }

    private void initializeData() {
    DateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy");
    DateFormat timeFormat = new SimpleDateFormat("HH:mm:ss");
    Calendar cal = Calendar.getInstance();
    String sCurrentDate = dateFormat.format(cal.getTime());
    String sCurrentTime = timeFormat.format(cal.getTime());

    cal.add(Calendar.DATE, -2);
    String sDateBefore2Days = dateFormat.format(cal.getTime());

    startDateText.setText(sDateBefore2Days);
    startTimeText.setText(sCurrentTime);
    endDateText.setText(sCurrentDate);
    endTimeText.setText(sCurrentTime);
    pageSizeText.setText(30 + "");

    auths = new ArrayList<>();
  }

  @Click
  void loadAuth() {
    // Reset the list of auths and the load more button
    auths.clear();
    listAuth.removeFooterView(btnLoadMore);
    isLoadMoreInView = false;

    DateFormat sdf = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
    String sStartDate = startDateText.getText() + " " + startTimeText.getText();
    String sEndDate = endDateText.getText() + " " + endTimeText.getText();
    Date startDate = null;
    Date endDate = null;
    try {
      startDate = sdf.parse(sStartDate);
    } catch (ParseException e) {
      e.printStackTrace();
      Calendar cal = Calendar.getInstance();
      cal.add(Calendar.DATE, -2);
      startDate = cal.getTime();
    }
    // Read the end date time only if its enabled
    if (optionalEndTime.isChecked()) {
      try {
        endDate = sdf.parse(sEndDate);
      } catch (ParseException e) {
        e.printStackTrace();
        endDate = new Date();
      }
    }

    List<AuthStatus> status = null;
    if(authStatusPending.isChecked() || authStatusCancelled.isChecked()) {
      status = new ArrayList<>();
      if(authStatusPending.isChecked())
        status.add(AuthStatus.pending);
      if(authStatusCancelled.isChecked())
        status.add(AuthStatus.canceled);
    }


    int pageSize;
    try {
      pageSize = Integer.parseInt(pageSizeText.getText() + "");

      RetailSDK.retrieveAuthorizedTransactions(startDate, endDate, pageSize, status, new RetailSDK.AuthorizedTransactionsHandler() {
        @Override
        public void handle(RetailSDKException error, List<AuthorizedTransaction> listOfAuths, String nextPageToken) {
          processListOfAuthResponse(error, listOfAuths, nextPageToken);
        }
      });
    } catch (Exception e) {
      displayTextView.setTextColor(Color.RED);
      displayTextView.setText(e.getMessage());
    }
  }


  @UiThread
  void processListOfAuthResponse(RetailSDKException error, List<AuthorizedTransaction> listOfAuths, String nextPageToken) {
    if (error != null) {
      displayTextView.setTextColor(Color.RED);
      displayTextView.setText(error.getDeveloperMessage());
    } else {
      this.nextPageToken = nextPageToken;
      if (this.nextPageToken != null) {
        // Adding Load More button to the bottom of list view, if it is not already added
        if (!isLoadMoreInView) {
          listAuth.addFooterView(btnLoadMore);
          isLoadMoreInView = true;
        }
      } else {
        listAuth.removeFooterView(btnLoadMore);
      }

      // Lets get the list of auths
      if (listOfAuths != null) {
        displayTextView.setTextColor(Color.GRAY);
        displayTextView.setText("Loaded " + listOfAuths.size() + " auth(s)");
        auths.addAll(listOfAuths);
      }

      adapter = new ListViewAdapter(AuthActivity.this, auths);
      listAuth.setAdapter(adapter);
    }
  }

  private class AuthLoader extends AsyncTask<Void, Void, Void> {

    @Override
    protected Void doInBackground(Void... voids) {
      RetailSDK.retrieveAuthorizedTransactions(nextPageToken, new RetailSDK.AuthorizedTransactionsHandler() {
        @Override
        public void handle(RetailSDKException error, List<AuthorizedTransaction> listOfAuths, String nextPageToken) {
          processListOfAuthResponse(error, listOfAuths, nextPageToken);
        }
      });
      return null;
    }
  }
}


class ListViewAdapter extends BaseAdapter {

  private AuthActivity activity;
  private List<AuthorizedTransaction> data;
  private static LayoutInflater inflater = null;

  public ListViewAdapter(AuthActivity activity, List<AuthorizedTransaction> data) {
    this.activity = activity;
    this.data = data;
    this.inflater = (LayoutInflater) activity.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
  }

  public int getCount() {
    return data.size();
  }

  public Object getItem(int position) {
    return position;
  }

  public long getItemId(int position) {
    return position;
  }

  public View getView(int position, View convertView, ViewGroup parent) {
    View vi = convertView;
    if (convertView == null)
      vi = inflater.inflate(R.layout.auth_item, null);

    final TextView authId = (TextView) vi.findViewById(R.id.authid);
    final TextView invoiceId = (TextView) vi.findViewById(R.id.invoiceid);
    final TextView timeCreatedTextView = (TextView) vi.findViewById(R.id.timeCreated);
    final TextView status = (TextView) vi.findViewById(R.id.status);
    TextView amt = (TextView) vi.findViewById(R.id.amt);
    final Button btnVoid = (Button) vi.findViewById(R.id.btnVoid);

    // Capture elements
    final Button btnCapture = (Button) vi.findViewById(R.id.btnCapture);
    final TextView totalAmountTextView = (TextView) vi.findViewById(R.id.totalAmountText);
    final TextView gratuityTextView = (TextView) vi.findViewById(R.id.gratuityText);

    final AuthorizedTransaction authorizedTransaction = data.get(position);

    // Setting all values in listview
    authId.setText(authorizedTransaction.getAuthorizationId());
    invoiceId.setText(authorizedTransaction.getInvoiceId());
    status.setText(authorizedTransaction.getStatus());
    amt.setText(authorizedTransaction.getAuthorizedAmount().toString() + " " + authorizedTransaction.getCurrency());

    Date timeCreated = authorizedTransaction.getTimeCreated();
    timeCreatedTextView.setText(timeCreated.toString());

    // Method 1 to void a transaction
    btnVoid.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(final View btnView) {
        activity.showProgressDialog("Voiding " + authId.getText().toString());
        RetailSDK.voidAuthorization(authId.getText().toString(), new RetailSDK.VoidAuthorizationHandler() {
          @Override
          public void handle(RetailSDKException error) {
            activity.dismissProgressDialog();
            if (error != null) {
              if(error.getDeveloperMessage() == null || error.getDeveloperMessage().isEmpty()) {
                activity.showAlert(error.getMessage());
              } else {
                activity.showAlert(error.getDeveloperMessage());
              }
            } else {
              authorizedTransaction.setStatus("CANCELED");
              activity.updateView(status, "CANCELED");
              activity.showAlert(authId.getText() + " was voided");
            }
          }
        });
      }
    });

    // Method 2 to void a transaction
//    btnVoid.setOnClickListener(new View.OnClickListener() {
//      @Override
//      public void onClick(final View btnView) {
//        authorizedTransaction.voidTransaction(new AuthorizedTransaction.VoidCompleteCallback() {
//          @Override
//          public void voidComplete(RetailSDKException error) {
//            activity.dismissProgressDialog();
//            if (error != null) {
//              activity.showAlert(error.getDeveloperMessage());
//            } else {
//              authorizedTransaction.setStatus("CANCELED");
//              activity.updateView(status, "CANCELED");
//              activity.showAlert(authId.getText() + " was voided");
//            }
//          }
//        });
//      }
//    });


//    // Method 1 to capture a transaction
//    btnCapture.setOnClickListener(new View.OnClickListener() {
//      @Override
//      public void onClick(final View btnView) {
//        // Get the amounts from text fields
//        BigDecimal totalAmount = null;
//        BigDecimal gratuity = null;
//        if(!gratuityTextView.getText().toString().isEmpty()) {
//          gratuity = new BigDecimal(gratuityTextView.getText().toString());
//        }
//        if(!totalAmountTextView.getText().toString().isEmpty()) {
//          totalAmount = new BigDecimal(totalAmountTextView.getText().toString());
//        }
//        activity.showProgressDialog("Capturing " + authId.getText().toString()+" with "+totalAmount+" total and gratuity "+gratuity);
//        RetailSDK.captureAuthorization(authId.getText().toString(), invoiceId.getText().toString(), totalAmount, gratuity, authorizedTransaction.getCurrency(), new RetailSDK.CaptureAuthorizationHandler(){
//          @Override
//          public void handle(RetailSDKException error, String captureId) {
//            activity.dismissProgressDialog();
//            if(error != null) {
//              if(error.getDeveloperMessage() == null || error.getDeveloperMessage().isEmpty()) {
//                activity.showAlert(error.getMessage());
//              } else {
//                activity.showAlert(error.getDeveloperMessage());
//              }
//            } else {
//              activity.updateView(status, "COMPLETED");
//              activity.showAlert("Success! Capture id is "+captureId);
//            }
//          }
//        });
//      }
//    });

    // Method 2 to capture a transaction
    btnCapture.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(final View btnView) {
        // Get the amounts from text fields
        BigDecimal totalAmount = null;
        BigDecimal gratuity = null;
        if(!gratuityTextView.getText().toString().isEmpty()) {
          gratuity = new BigDecimal(gratuityTextView.getText().toString());
        }
        if(!totalAmountTextView.getText().toString().isEmpty()) {
          totalAmount = new BigDecimal(totalAmountTextView.getText().toString());
        }
        activity.showProgressDialog("Capturing " + authId.getText().toString()+" with "+totalAmount+" total and gratuity "+gratuity);
        authorizedTransaction.captureTransaction(totalAmount, gratuity, new AuthorizedTransaction.CaptureCompleteCallback(){
          @Override
          public void captureComplete(RetailSDKException error, String captureId) {
            activity.dismissProgressDialog();
            if(error != null) {
              if(error.getDeveloperMessage() == null || error.getDeveloperMessage().isEmpty()) {
                activity.showAlert(error.getMessage());
              } else {
                activity.showAlert(error.getDeveloperMessage());
              }
            } else {
              activity.updateView(status, "COMPLETED");
              activity.showAlert("Success! Capture id is "+captureId);
            }
          }
        });
      }
    });
    return vi;
  }

}