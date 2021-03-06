package edu.uml.cs.isense.collector.splash;

import java.io.File;
import java.util.Locale;

import android.annotation.SuppressLint;
import android.app.ActionBar;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;
import edu.uml.cs.isense.collector.DataCollector;
import edu.uml.cs.isense.collector.ManualEntry;
import edu.uml.cs.isense.collector.R;
import edu.uml.cs.isense.collector.dialogs.LoginActivity;
import edu.uml.cs.isense.comm.API;
import edu.uml.cs.isense.supplements.FileBrowser;
import edu.uml.cs.isense.supplements.ObscuredSharedPreferences;
import edu.uml.cs.isense.supplements.OrientationManager;
import edu.uml.cs.isense.waffle.Waffle;

public class SelectMode extends Activity {

	private static Context mContext;
	private Waffle w;
	private API api;
	
	private String tempFilepath = "";

	public static final String ENABLE_MANUAL_AND_CSV = "enable_manual_and_csv";

	private static final int UPLOAD_CSV_REQUESTED = 100;
	private static final int LOGIN_REQUESTED = 101;

	@SuppressLint("NewApi")
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.select_mode);

		mContext = this;
		w = new Waffle(mContext);
		api = API.getInstance(mContext);

		// Action bar customization for API >= 14
		if (android.os.Build.VERSION.SDK_INT >= 14) {
			ActionBar bar = getActionBar();
			bar.setBackgroundDrawable(new ColorDrawable(Color
					.parseColor("#111133")));
			bar.setIcon(getResources()
					.getDrawable(R.drawable.rsense_logo_right));
			bar.setDisplayShowTitleEnabled(false);
			int actionBarTitleId = Resources.getSystem().getIdentifier(
					"action_bar_title", "id", "android");
			if (actionBarTitleId > 0) {
				TextView title = (TextView) findViewById(actionBarTitleId);
				if (title != null) {
					title.setTextColor(Color.WHITE);
					title.setTextSize(24.0f);
				}
			}
		}

		// Set listeners for the buttons
		final Button dataCollector = (Button) findViewById(R.id.select_mode_data_collector);
		dataCollector.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				Intent iDC = new Intent(mContext, DataCollector.class);
				startActivity(iDC);
			}
		});

		final Button manualEntry = (Button) findViewById(R.id.select_mode_manual_entry);
		manualEntry.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				Intent iME = new Intent(mContext, ManualEntry.class);
				startActivity(iME);
			}
		});

		final Button csvUploader = (Button) findViewById(R.id.select_mode_csv_uploader);
		csvUploader.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				Intent iFileBrowse = new Intent(mContext, FileBrowser.class);
				startActivityForResult(iFileBrowse, UPLOAD_CSV_REQUESTED);
			}
		});

		// Determine if we should disable manual entry and .csv uploader
		Bundle extras = getIntent().getExtras();
		if (extras != null) {
			boolean en = extras.getBoolean(ENABLE_MANUAL_AND_CSV);
			if (!en) {
				manualEntry.setEnabled(false);
				csvUploader.setEnabled(false);
			}
		}

	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		if (requestCode == UPLOAD_CSV_REQUESTED) {
			if (resultCode == RESULT_OK) {
				String filepath = data.getStringExtra("filepath");
				if (filepath.length() == 0) {
					w.make("Could not find .csv file", Waffle.LENGTH_SHORT,
							Waffle.IMAGE_X);
					return;
				}

				if (!api.hasConnectivity()) {
					w.make("Cannot upload a .csv file with no internet connectivity",
							Waffle.LENGTH_SHORT, Waffle.IMAGE_WARN);
					return;
				}

				String[] comp = filepath.split("\\.");

				if (comp.length == 0
						|| !(comp[comp.length - 1].toLowerCase(Locale.US)
								.equals("csv"))) {
					w.make("Only .csv files are allowed for upload",
							Waffle.LENGTH_SHORT, Waffle.IMAGE_WARN);
					return;
				}

				new LoginTask().execute(filepath);
			}
		} else if (requestCode == LOGIN_REQUESTED) {
			if (resultCode == RESULT_OK) {
				if (resultCode == RESULT_OK) {
					String returnCode = data.getStringExtra("returnCode");

					if (returnCode.equals("Success")) {

						w.make("Login successful", Waffle.LENGTH_LONG,
								Waffle.IMAGE_CHECK);

						new UploadCSVTask().execute(tempFilepath);

					} else if (returnCode.equals("Failed")) {
						
						Intent i = new Intent(mContext, LoginActivity.class);
						startActivityForResult(i, LOGIN_REQUESTED);
						
					}
				}
			}
		}
	}

	private class LoginTask extends AsyncTask<String, Integer, Void> {

		private ProgressDialog dia;
		private String filepath;

		@Override
		protected void onPreExecute() {

			OrientationManager.disableRotation(SelectMode.this);

			dia = new ProgressDialog(SelectMode.this);
			dia.setProgressStyle(ProgressDialog.STYLE_SPINNER);
			dia.setMessage("Logging in...");
			dia.setCancelable(false);
			dia.show();
		}

		@Override
		protected Void doInBackground(String... args) {

			filepath = args[0];

			final SharedPreferences mPrefs = new ObscuredSharedPreferences(
					SelectMode.mContext,
					SelectMode.mContext.getSharedPreferences("USER_INFO",
							Context.MODE_PRIVATE));

			api.createSession(mPrefs.getString("username", ""),
					mPrefs.getString("password", ""));

			publishProgress(100);
			return null;

		}

		@Override
		protected void onPostExecute(Void voids) {
			dia.setMessage("Done");
			dia.cancel();
			OrientationManager.enableRotation(SelectMode.this);

			if (api.getCurrentUser() == null) {
				tempFilepath = filepath;
				w.make("Please log in", Waffle.LENGTH_SHORT, Waffle.IMAGE_WARN);
				
				Intent i = new Intent(mContext, LoginActivity.class);
				startActivityForResult(i, LOGIN_REQUESTED);
			} else {
				new UploadCSVTask().execute(filepath);
			}

		}

	}

	private class UploadCSVTask extends AsyncTask<String, Integer, Void> {

		private ProgressDialog dia;
		private int dsid = -1;

		@Override
		protected void onPreExecute() {

			OrientationManager.disableRotation(SelectMode.this);

			dia = new ProgressDialog(SelectMode.this);
			dia.setProgressStyle(ProgressDialog.STYLE_SPINNER);
			dia.setMessage("Please wait while the .csv file is uploaded...");
			dia.setCancelable(false);
			dia.show();
		}

		@Override
		protected Void doInBackground(String... args) {

			SharedPreferences globalProjPrefs = getSharedPreferences(
					"GLOBAL_PROJ", 0);
			int projectId = Integer.parseInt(globalProjPrefs.getString(
					"project_id_csv", "-1"));

			File csvToUpload = new File(args[0]);

			String[] components = args[0].split("/");
			String datasetName = components[components.length - 1];

			dsid = api.uploadCSV(projectId, csvToUpload, datasetName);

			publishProgress(100);
			return null;

		}

		@Override
		protected void onPostExecute(Void voids) {
			dia.setMessage("Done");
			dia.cancel();
			OrientationManager.enableRotation(SelectMode.this);

			if (dsid <= 0) {
				w.make(".csv File Failed to Upload", Waffle.LENGTH_SHORT,
						Waffle.IMAGE_X);
			} else {
				w.make(".csv File Uploaded Successfully", Waffle.LENGTH_SHORT,
						Waffle.IMAGE_CHECK);
			}

		}

	}

	@Override
	public void onBackPressed() {
		super.onBackPressed();
	}

}